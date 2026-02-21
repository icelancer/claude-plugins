---
name: fullstack-init
description: >
  Python(FastAPI) + Next.js 풀스택 모노레포 프로젝트를 스캐폴딩합니다.
  UV 워크스페이스(Python)와 pnpm 워크스페이스(Node.js)를 사용한 폴리글랏 모노레포를
  생성하며, Docker, CI/CD, 공유 패키지, CRUD 데모 코드를 포함합니다.
  Trigger: create monorepo, scaffold monorepo, python nextjs project,
  fullstack monorepo, fastapi nextjs, create fullstack project,
  fullstack init, 모노레포 생성, 모노레포 스캐폴딩, 풀스택 프로젝트
---

# Fullstack Init

Python(FastAPI) + Next.js 풀스택 모노레포를 스캐폴딩하는 스킬.

## 생성되는 프로젝트 구조

```
{{PROJECT_NAME}}/
├── apps/
│   ├── api/                    # FastAPI backend (Python, uv)
│   │   ├── src/
│   │   │   ├── main.py
│   │   │   ├── core/config.py
│   │   │   ├── models/item.py
│   │   │   ├── api/
│   │   │   │   ├── dependencies.py
│   │   │   │   └── routers/{home,items}.py
│   │   │   └── services/item_service.py
│   │   ├── tests/test_api.py
│   │   ├── pyproject.toml
│   │   └── Dockerfile          # (conditional: Docker)
│   └── web/                    # Next.js frontend (React 19, Tailwind 4)
│       ├── src/
│       │   ├── app/{layout,page}.tsx
│       │   ├── components/{item-form,item-list}.tsx
│       │   ├── hooks/use-items.ts
│       │   ├── api.ts
│       │   └── types/item.ts
│       ├── tests/
│       ├── package.json
│       └── Dockerfile          # (conditional: Docker)
├── packages/
│   ├── python/common/          # Shared Python utils (uv workspace)
│   └── typescript/utils/       # Shared TS utils (@repo/utils)
├── package.json                # Root scripts (concurrently dev)
├── pyproject.toml              # UV workspace config
├── pnpm-workspace.yaml
├── .env.example
├── docker-compose.yml          # (conditional: Docker)
├── .github/workflows/ci.yml   # (conditional: CI)
├── CLAUDE.md
└── README.md
```

## 템플릿 변수

| 변수 | 용도 | 예시 |
|------|------|------|
| `{{PROJECT_NAME}}` | 디렉토리/패키지명 (kebab-case) | `my-app` |
| `{{PROJECT_NAME_TITLE}}` | 표시용 이름 (Title Case) | `My App` |
| `{{PYTHON_VERSION}}` | Python 버전 | `3.13` |
| `{{NODE_VERSION}}` | Node.js 버전 | `22.13.1` |

## Workflow

### Step 1: 사용자 입력 수집

AskUserQuestion **한 번**으로 프로젝트명과 옵션을 동시에 수집한다.

```
questions:
  - question: "프로젝트 이름을 입력하세요. (kebab-case)"
    header: "Name"
    multiSelect: false
    options:
      - label: "my-fullstack-app"
        description: "예시 이름 — 'Other'를 선택해서 원하는 이름을 직접 입력하세요"
      - label: "my-app"
        description: "예시 이름"
  - question: "프로젝트에 포함할 추가 구성을 선택하세요."
    header: "Options"
    multiSelect: true
    options:
      - label: "Docker (Recommended)"
        description: "Dockerfile + docker-compose.yml 포함"
      - label: "CI/CD"
        description: "GitHub Actions CI 워크플로우 포함"
```

사용자가 선택하거나 "Other"로 직접 입력한 이름을 kebab-case로 정규화하여 `{{PROJECT_NAME}}`으로 사용.
kebab-case를 Title Case로 변환하여 `{{PROJECT_NAME_TITLE}}`로 사용.
(예: `my-app` → `My App`)

### Step 2: 환경 감지

Bash로 아래를 확인한다:

1. **대상 디렉토리**: 현재 작업 디렉토리(cwd) 아래에 `{{PROJECT_NAME}}` 디렉토리가 이미 존재하면 사용자에게 경고하고 중단.
2. **Python 버전 감지**: `python3 --version` 실행 → 메이저.마이너 추출 (예: `3.13`). 실패 시 기본값 `3.13`.
3. **Node.js 버전 감지**: `node --version` 실행 → 버전 추출 (예: `22.13.1`). 실패 시 기본값 `22.13.1`.
4. **필수 도구 확인**: `uv --version`과 `pnpm --version` 실행. 둘 중 하나라도 없으면 설치 안내 메시지 출력 후 계속 진행할지 사용자에게 확인.

감지된 버전을 `{{PYTHON_VERSION}}`과 `{{NODE_VERSION}}`에 사용.

### Step 3: 파일 생성

`assets/templates/` 디렉토리의 `.tmpl` 파일을 읽어 플레이스홀더를 치환한 후 대상 경로에 Write한다.

**전체 파일 목록과 매핑은 `references/file-manifest.md`를 참조.**

**생성 순서:**

#### 3-1. Root 파일

`assets/templates/root/` → `{{PROJECT_NAME}}/`

| 템플릿 파일 | 대상 파일 |
|------------|----------|
| `package.json.tmpl` | `package.json` |
| `pyproject.toml.tmpl` | `pyproject.toml` |
| `pnpm-workspace.yaml.tmpl` | `pnpm-workspace.yaml` |
| `pyrightconfig.json.tmpl` | `pyrightconfig.json` |
| `nvmrc.tmpl` | `.nvmrc` |
| `python-version.tmpl` | `.python-version` |
| `gitignore.tmpl` | `.gitignore` |
| `CLAUDE.md.tmpl` | `CLAUDE.md` |
| `README.md.tmpl` | `README.md` |
| `env.example.tmpl` | `.env.example` |

#### 3-2. Packages

`assets/templates/packages/python-common/` → `{{PROJECT_NAME}}/packages/python/common/`
`assets/templates/packages/typescript-utils/` → `{{PROJECT_NAME}}/packages/typescript/utils/`

#### 3-3. API

`assets/templates/api/` → `{{PROJECT_NAME}}/apps/api/`

**`Dockerfile.tmpl` 제외** (Step 3-5에서 조건부 처리).
나머지 모든 `.tmpl` 파일을 읽고, 확장자 `.tmpl`을 제거한 경로에 Write.
디렉토리 구조는 템플릿의 하위 경로를 그대로 유지.

#### 3-4. Web

`assets/templates/web/` → `{{PROJECT_NAME}}/apps/web/`

**`Dockerfile.tmpl` 제외** (Step 3-5에서 조건부 처리).
동일하게 나머지 `.tmpl` 파일을 읽고 Write.

#### 3-5. Docker (조건부)

사용자가 Docker를 선택한 경우에만:
- `root/docker-compose.yml.tmpl` → `{{PROJECT_NAME}}/docker-compose.yml`
- `api/Dockerfile.tmpl` → `{{PROJECT_NAME}}/apps/api/Dockerfile`
- `web/Dockerfile.tmpl` → `{{PROJECT_NAME}}/apps/web/Dockerfile`

#### 3-6. CI (조건부)

사용자가 CI를 선택한 경우에만:
- `ci/ci.yml.tmpl` → `{{PROJECT_NAME}}/.github/workflows/ci.yml`

#### 3-7. DX 파일

- `root/vscode-settings.json.tmpl` → `{{PROJECT_NAME}}/.vscode/settings.json`

**플레이스홀더 치환 방법:**

각 `.tmpl` 파일을 Read로 읽은 후, 내용에서 아래 문자열을 치환:
- `{{PROJECT_NAME}}` → 사용자 입력 kebab-case 이름
- `{{PROJECT_NAME_TITLE}}` → Title Case 변환 이름
- `{{PYTHON_VERSION}}` → 감지된 Python 버전
- `{{NODE_VERSION}}` → 감지된 Node.js 버전

치환된 내용을 Write로 대상 경로에 저장.

### Step 4: 의존성 설치

생성된 프로젝트 디렉토리에서 Bash로 실행:

```bash
cd {{PROJECT_NAME}} && pnpm install && uv sync
```

### Step 5: 검증 및 요약

아래 형식으로 결과를 출력:

```
✅ 프로젝트 '{{PROJECT_NAME}}' 생성 완료!

📁 구조:
  - apps/api: FastAPI backend (Python {{PYTHON_VERSION}})
  - apps/web: Next.js frontend (Node.js {{NODE_VERSION}})
  - packages/python/common: 공유 Python 패키지
  - packages/typescript/utils: 공유 TypeScript 패키지
  [- docker-compose.yml: Docker 구성 (포함된 경우)]
  [- .github/workflows/ci.yml: CI 파이프라인 (포함된 경우)]

🚀 시작하기:
  cd {{PROJECT_NAME}}
  pnpm dev              # web(3000) + api(8000) 동시 실행

🧪 테스트:
  uv run pytest         # Python 테스트
  pnpm --filter web test  # Frontend 테스트

[🐳 Docker: (포함된 경우)
  docker-compose up -d --build]
```
