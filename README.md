# Claude Plugins

개인 Claude Code 플러그인 마켓플레이스. 프로젝트에 필요한 플러그인을 선택적으로 설치할 수 있습니다.

## 설치

```bash
claude plugin add git@github.com:icelancer/claude-plugins.git
```

## 플러그인 목록

### langchain-skills

LangChain, LangGraph, LangSmith 관련 코드 작업 시 최신 문서를 참조하여 정확한 코드를 작성하는 스킬.

- 로컬 레퍼런스 문서와 `docs.langchain.com` 실시간 문서를 함께 활용
- LLM 학습 데이터의 deprecated API 대신 최신 API 사용을 보장
- Trigger keywords: `langchain`, `langgraph`, `langsmith`, `agent`, `RAG`, `streaming`, `MCP` 등

## 새 플러그인 추가하기

1. `plugins/<plugin-name>/` 디렉토리 생성
2. `plugins/<plugin-name>/.claude-plugin/plugin.json` 작성
3. 스킬이 있는 경우 `plugins/<plugin-name>/skills/<skill-name>/` 하위에 배치
4. 루트 `.claude-plugin/marketplace.json`의 `plugins` 배열에 추가

```
plugins/
└── my-new-plugin/
    ├── .claude-plugin/
    │   └── plugin.json
    └── skills/
        └── my-skill/
            ├── SKILL.md
            ├── permissions.json
            └── references/
                └── ...
```
