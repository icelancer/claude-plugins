#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"

usage() {
  echo "Usage: $0 <target-project-path> [skill-name]"
  echo ""
  echo "  Install all skills or a specific skill into a target project."
  echo ""
  echo "Examples:"
  echo "  $0 /path/to/project              # Install all skills"
  echo "  $0 /path/to/project langchain     # Install langchain skill only"
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

TARGET_DIR="$(cd "$1" && pwd)"
SKILL_NAME="${2:-}"

install_skill() {
  local name="$1"
  local src="$SKILLS_SRC/$name"
  local dest="$TARGET_DIR/.claude/skills/$name"

  if [[ ! -d "$src" ]]; then
    echo "Error: Skill '$name' not found in $SKILLS_SRC"
    return 1
  fi

  # Create target .claude/skills/ directory
  mkdir -p "$TARGET_DIR/.claude/skills"

  # Create symlink
  if [[ -L "$dest" ]]; then
    echo "  [skip] $name: symlink already exists -> $(readlink "$dest")"
  elif [[ -d "$dest" ]]; then
    echo "  [skip] $name: directory already exists (not a symlink)"
  else
    ln -s "$src" "$dest"
    echo "  [link] $name -> $src"
  fi

  # Merge permissions
  local perms="$src/permissions.json"
  if [[ -f "$perms" ]]; then
    merge_permissions "$perms"
  fi
}

merge_permissions() {
  local perms_file="$1"
  local settings="$TARGET_DIR/.claude/settings.local.json"

  if ! command -v jq &>/dev/null; then
    echo "  [warn] jq not found. Please manually merge permissions from $perms_file"
    return
  fi

  mkdir -p "$TARGET_DIR/.claude"

  # Initialize settings file if it doesn't exist
  if [[ ! -f "$settings" ]]; then
    echo '{}' > "$settings"
  fi

  # Read new allow rules
  local new_rules
  new_rules=$(jq -r '.allow[]' "$perms_file" 2>/dev/null) || return 0

  # Merge each rule into settings.local.json (skip duplicates)
  local updated="$settings"
  local changed=false
  while IFS= read -r rule; do
    [[ -z "$rule" ]] && continue
    local exists
    exists=$(jq --arg r "$rule" '.permissions.allow // [] | map(select(. == $r)) | length' "$settings")
    if [[ "$exists" == "0" ]]; then
      local tmp
      tmp=$(jq --arg r "$rule" '.permissions.allow = ((.permissions.allow // []) + [$r])' "$settings")
      echo "$tmp" > "$settings"
      echo "  [perm] Added: $rule"
      changed=true
    else
      echo "  [perm] Already exists: $rule"
    fi
  done <<< "$new_rules"
}

echo "Installing skills into: $TARGET_DIR"
echo ""

if [[ -n "$SKILL_NAME" ]]; then
  install_skill "$SKILL_NAME"
else
  for skill_dir in "$SKILLS_SRC"/*/; do
    skill=$(basename "$skill_dir")
    install_skill "$skill"
  done
fi

echo ""
echo "Done!"
