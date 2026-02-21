# File Manifest

모든 생성 파일의 목록, 설명, 조건, 플레이스홀더 사용 여부를 정리한 매니페스트.

## 플레이스홀더 변수

| 변수 | 용도 | 기본값 |
|------|------|--------|
| `{{PROJECT_NAME}}` | 디렉토리/패키지명 (kebab-case) | 사용자 입력 |
| `{{PROJECT_NAME_TITLE}}` | 표시용 이름 (Title Case) | PROJECT_NAME에서 변환 |
| `{{PYTHON_VERSION}}` | Python 버전 | 시스템 감지 또는 `3.13` |
| `{{NODE_VERSION}}` | Node.js 버전 | 시스템 감지 또는 `22.13.1` |

## 파일 목록

### root/ → `{{PROJECT_NAME}}/`

| 템플릿 | 대상 경로 | 조건 | 플레이스홀더 |
|--------|----------|------|-------------|
| `root/package.json.tmpl` | `package.json` | 항상 | `{{PROJECT_NAME}}`, `{{NODE_VERSION}}` |
| `root/pyproject.toml.tmpl` | `pyproject.toml` | 항상 | - |
| `root/pnpm-workspace.yaml.tmpl` | `pnpm-workspace.yaml` | 항상 | - |
| `root/pyrightconfig.json.tmpl` | `pyrightconfig.json` | 항상 | - |
| `root/nvmrc.tmpl` | `.nvmrc` | 항상 | `{{NODE_VERSION}}` |
| `root/python-version.tmpl` | `.python-version` | 항상 | `{{PYTHON_VERSION}}` |
| `root/gitignore.tmpl` | `.gitignore` | 항상 | - |
| `root/vscode-settings.json.tmpl` | `.vscode/settings.json` | 항상 | - |
| `root/docker-compose.yml.tmpl` | `docker-compose.yml` | Docker | - |
| `root/env.example.tmpl` | `.env.example` | 항상 | `{{PROJECT_NAME_TITLE}}` |
| `root/CLAUDE.md.tmpl` | `CLAUDE.md` | 항상 | - |
| `root/README.md.tmpl` | `README.md` | 항상 | `{{PROJECT_NAME}}`, `{{PROJECT_NAME_TITLE}}` |

### api/ → `{{PROJECT_NAME}}/apps/api/`

| 템플릿 | 대상 경로 | 조건 | 플레이스홀더 |
|--------|----------|------|-------------|
| `api/pyproject.toml.tmpl` | `pyproject.toml` | 항상 | `{{PROJECT_NAME_TITLE}}`, `{{PYTHON_VERSION}}` |
| `api/README.md.tmpl` | `README.md` | 항상 | `{{PROJECT_NAME_TITLE}}` |
| `api/Dockerfile.tmpl` | `Dockerfile` | Docker | `{{PYTHON_VERSION}}` |
| `api/src/main.py.tmpl` | `src/main.py` | 항상 | - |
| `api/src/core/config.py.tmpl` | `src/core/config.py` | 항상 | `{{PROJECT_NAME_TITLE}}` |
| `api/src/models/__init__.py.tmpl` | `src/models/__init__.py` | 항상 | - |
| `api/src/models/item.py.tmpl` | `src/models/item.py` | 항상 | - |
| `api/src/api/dependencies.py.tmpl` | `src/api/dependencies.py` | 항상 | - |
| `api/src/api/routers/home.py.tmpl` | `src/api/routers/home.py` | 항상 | - |
| `api/src/api/routers/items.py.tmpl` | `src/api/routers/items.py` | 항상 | - |
| `api/src/services/__init__.py.tmpl` | `src/services/__init__.py` | 항상 | - |
| `api/src/services/item_service.py.tmpl` | `src/services/item_service.py` | 항상 | - |
| `api/tests/test_api.py.tmpl` | `tests/test_api.py` | 항상 | - |

### web/ → `{{PROJECT_NAME}}/apps/web/`

| 템플릿 | 대상 경로 | 조건 | 플레이스홀더 |
|--------|----------|------|-------------|
| `web/package.json.tmpl` | `package.json` | 항상 | - |
| `web/Dockerfile.tmpl` | `Dockerfile` | Docker | - |
| `web/next.config.ts.tmpl` | `next.config.ts` | 항상 | - |
| `web/vitest.config.ts.tmpl` | `vitest.config.ts` | 항상 | - |
| `web/tsconfig.json.tmpl` | `tsconfig.json` | 항상 | - |
| `web/eslint.config.mjs.tmpl` | `eslint.config.mjs` | 항상 | - |
| `web/postcss.config.mjs.tmpl` | `postcss.config.mjs` | 항상 | - |
| `web/src/app/layout.tsx.tmpl` | `src/app/layout.tsx` | 항상 | `{{PROJECT_NAME_TITLE}}` |
| `web/src/app/page.tsx.tmpl` | `src/app/page.tsx` | 항상 | `{{PROJECT_NAME_TITLE}}` |
| `web/src/app/globals.css.tmpl` | `src/app/globals.css` | 항상 | - |
| `web/src/components/item-form.tsx.tmpl` | `src/components/item-form.tsx` | 항상 | - |
| `web/src/components/item-list.tsx.tmpl` | `src/components/item-list.tsx` | 항상 | - |
| `web/src/hooks/use-items.ts.tmpl` | `src/hooks/use-items.ts` | 항상 | - |
| `web/src/api.ts.tmpl` | `src/api.ts` | 항상 | - |
| `web/src/types/item.ts.tmpl` | `src/types/item.ts` | 항상 | - |
| `web/tests/api.test.ts.tmpl` | `tests/api.test.ts` | 항상 | - |
| `web/tests/use-items.test.ts.tmpl` | `tests/use-items.test.ts` | 항상 | - |
| `web/tests/item-list.test.tsx.tmpl` | `tests/item-list.test.tsx` | 항상 | - |
| `web/tests/setup.ts.tmpl` | `tests/setup.ts` | 항상 | - |

### packages/ → `{{PROJECT_NAME}}/packages/`

| 템플릿 | 대상 경로 | 조건 | 플레이스홀더 |
|--------|----------|------|-------------|
| `packages/python-common/pyproject.toml.tmpl` | `python/common/pyproject.toml` | 항상 | `{{PYTHON_VERSION}}` |
| `packages/python-common/README.md.tmpl` | `python/common/README.md` | 항상 | `{{PROJECT_NAME_TITLE}}` |
| `packages/python-common/src/common/__init__.py.tmpl` | `python/common/src/common/__init__.py` | 항상 | - |
| `packages/python-common/src/common/py.typed.tmpl` | `python/common/src/common/py.typed` | 항상 | - |
| `packages/typescript-utils/package.json.tmpl` | `typescript/utils/package.json` | 항상 | - |
| `packages/typescript-utils/src/index.ts.tmpl` | `typescript/utils/src/index.ts` | 항상 | - |

### ci/ → `{{PROJECT_NAME}}/.github/workflows/`

| 템플릿 | 대상 경로 | 조건 | 플레이스홀더 |
|--------|----------|------|-------------|
| `ci/ci.yml.tmpl` | `ci.yml` | CI | - |

## 조건부 파일 요약

- **Docker** (사용자가 Docker 포함 선택 시): `docker-compose.yml`, `apps/api/Dockerfile`, `apps/web/Dockerfile`
- **CI** (사용자가 CI 포함 선택 시): `.github/workflows/ci.yml`

## 생성 순서

1. **root**: 프로젝트 루트 설정 파일들
2. **packages**: 공유 패키지 (Python common, TypeScript utils)
3. **api**: FastAPI 백엔드 앱
4. **web**: Next.js 프론트엔드 앱
5. **docker**: Docker 관련 파일 (조건부)
6. **ci**: CI/CD 워크플로우 (조건부)
7. **dx**: `.vscode/settings.json`, `CLAUDE.md` 등 DX 파일
