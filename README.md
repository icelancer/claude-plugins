# Claude Skills

개인 Claude Code Skills 플러그인 모음. 프로젝트에 필요한 스킬을 선택적으로 설치할 수 있습니다.

## 설치

```bash
claude plugin add git@github.com:icelancer/claude-skill.git
```

## 스킬 목록

### langchain

LangChain, LangGraph, LangSmith 관련 코드 작업 시 최신 문서를 참조하여 정확한 코드를 작성하는 스킬.

- 로컬 레퍼런스 문서와 `docs.langchain.com` 실시간 문서를 함께 활용
- LLM 학습 데이터의 deprecated API 대신 최신 API 사용을 보장
- Trigger keywords: `langchain`, `langgraph`, `langsmith`, `agent`, `RAG`, `streaming`, `MCP` 등

## 새 스킬 추가하기

1. `skills/<skill-name>/` 디렉토리 생성
2. `SKILL.md` 작성 (frontmatter에 `name`, `description` 포함)
3. 필요 시 `references/` 디렉토리에 레퍼런스 문서 추가
4. `permissions.json` 작성 (스킬에 필요한 권한 명시)

```
skills/
└── my-new-skill/
    ├── SKILL.md
    ├── permissions.json
    └── references/
        └── ...
```
