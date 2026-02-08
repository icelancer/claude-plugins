---
description: LangChain/LangGraph 프로젝트 초기 설정을 자동화합니다. 의존성 설치, 환경변수 템플릿, 보일러플레이트 코드를 생성합니다.
allowed-tools: Bash(uv *), Bash(pip *)
---

# LangChain Project Initializer

새로운 LangChain/LangGraph 프로젝트의 초기 설정을 자동화하는 커맨드입니다.

## Workflow

### Step 1: 패키지 매니저 감지

현재 디렉토리에서 패키지 매니저를 자동 감지합니다:

1. `uv.lock` 파일이 존재하거나 `pyproject.toml`에 `[tool.uv]` 섹션이 있으면 → **uv** 사용
2. `requirements.txt`가 존재하거나 위 조건에 해당하지 않으면 → **pip** 사용
3. 감지 불가 시 → AskUserQuestion으로 사용자에게 질문

**감지 로직:**
```
Glob으로 uv.lock, pyproject.toml, requirements.txt 존재 여부 확인
pyproject.toml이 있으면 Read로 [tool.uv] 섹션 확인
```

### Step 2: 프로젝트 타입 선택

AskUserQuestion으로 프로젝트 타입을 질문합니다:

```
질문: "어떤 타입의 프로젝트를 만들까요?"
옵션:
1. Simple Agent (create_agent) — LangChain의 create_agent를 사용한 간단한 에이전트
2. LangGraph Agent (Graph API) — StateGraph 기반 워크플로우
3. LangGraph Agent (Functional API) — @entrypoint/@task 기반 워크플로우
4. RAG Application — 검색 증강 생성 에이전트
```

### Step 3: LLM Provider 선택

AskUserQuestion으로 LLM Provider를 질문합니다 (복수 선택 가능):

```
질문: "사용할 LLM Provider를 선택하세요. (복수 선택 가능)"
multiSelect: true
옵션:
1. Anthropic (Recommended) — Claude 모델 사용 (langchain-anthropic)
2. OpenAI — GPT 모델 사용 (langchain-openai)
3. Google — Gemini 모델 사용 (langchain-google-genai)
```

### Step 4: 실행

감지/선택 결과를 바탕으로 아래 작업을 순서대로 수행합니다.

#### 4-1. 의존성 설치

**uv인 경우:**
```bash
uv add langchain langsmith python-dotenv <타입별 패키지> <provider별 패키지>
```

**pip인 경우:**
```bash
pip install langchain langsmith python-dotenv <타입별 패키지> <provider별 패키지>
```

**타입별 추가 패키지:**

| 프로젝트 타입 | 추가 패키지 |
|-------------|-----------|
| Simple Agent | (없음) |
| LangGraph Agent (Graph API) | `langgraph` |
| LangGraph Agent (Functional API) | `langgraph` |
| RAG Application | `langchain-community` |

**Provider별 추가 패키지:**

| Provider | 패키지 |
|----------|--------|
| Anthropic | `langchain-anthropic` |
| OpenAI | `langchain-openai` |
| Google | `langchain-google-genai` |

#### 4-2. `.env` 파일 생성

`.env` 파일이 이미 존재하면, 기존 내용을 유지하면서 누락된 키만 추가합니다.
존재하지 않으면 새로 생성합니다.

```env
# LangSmith
LANGSMITH_API_KEY=ls_...
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=<프로젝트 디렉토리명>

# LLM Providers (선택한 provider만 포함)
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GOOGLE_API_KEY=...
```

`.gitignore`에 `.env`가 없으면 추가합니다.

#### 4-3. 엔트리포인트 파일 생성

프로젝트 타입에 맞는 보일러플레이트 파일을 생성합니다.
**이미 `main.py` 또는 `agent.py`가 존재하면 덮어쓰지 않고 사용자에게 알립니다.**

첫 번째로 선택된 provider를 기본 모델로 사용합니다.

---

**Simple Agent → `agent.py`:**

```python
from dotenv import load_dotenv
load_dotenv()

from langchain.chat_models import init_chat_model
from langchain.agents import create_agent
from langchain_core.tools import tool


@tool
def hello(name: str) -> str:
    """Greet someone by name."""
    return f"Hello, {name}!"


model = init_chat_model("<모델명>", model_provider="<provider>")

agent = create_agent(
    model,
    tools=[hello],
    prompt="You are a helpful assistant.",
)

if __name__ == "__main__":
    result = agent.invoke({"input": "Greet the world!"})
    print(result)
```

모델명/provider 매핑:
- Anthropic → `"claude-sonnet-4-5-20250929"`, `"anthropic"`
- OpenAI → `"gpt-4o"`, `"openai"`
- Google → `"gemini-2.0-flash"`, `"google_genai"`

---

**LangGraph Agent (Graph API) → `agent.py`:**

```python
from dotenv import load_dotenv
load_dotenv()

from typing import Annotated
from typing_extensions import TypedDict
from langchain.chat_models import init_chat_model
from langchain_core.messages import AnyMessage
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages


class State(TypedDict):
    messages: Annotated[list[AnyMessage], add_messages]


model = init_chat_model("<모델명>", model_provider="<provider>")


def chatbot(state: State) -> dict:
    response = model.invoke(state["messages"])
    return {"messages": [response]}


graph = StateGraph(State)
graph.add_node("chatbot", chatbot)
graph.add_edge(START, "chatbot")
graph.add_edge("chatbot", END)

app = graph.compile()

if __name__ == "__main__":
    result = app.invoke({"messages": [("user", "Hello!")]})
    print(result["messages"][-1].content)
```

---

**LangGraph Agent (Functional API) → `agent.py`:**

```python
from dotenv import load_dotenv
load_dotenv()

from langchain.chat_models import init_chat_model
from langgraph.func import entrypoint, task


model = init_chat_model("<모델명>", model_provider="<provider>")


@task
def generate_response(user_input: str) -> str:
    response = model.invoke([("user", user_input)])
    return response.content


@entrypoint()
def agent(user_input: str) -> str:
    result = generate_response(user_input).result()
    return result


if __name__ == "__main__":
    result = agent.invoke("Hello!")
    print(result)
```

---

**RAG Application → `agent.py`:**

```python
from dotenv import load_dotenv
load_dotenv()

from langchain.chat_models import init_chat_model
from langchain.agents import create_agent
from langchain_core.tools import tool


@tool
def retrieve(query: str) -> str:
    """Retrieve relevant documents from the knowledge base.

    TODO: Implement your retrieval logic here (vector store, database, etc.)
    """
    return f"[Document about: {query}]"


model = init_chat_model("<모델명>", model_provider="<provider>")

rag_agent = create_agent(
    model,
    tools=[retrieve],
    prompt="You are a helpful assistant. Use the retrieve tool to find relevant information before answering questions.",
)

if __name__ == "__main__":
    result = rag_agent.invoke({"input": "What is LangChain?"})
    print(result)
```

### Step 5: 결과 요약

모든 작업이 완료되면 아래 형식으로 요약합니다:

```
✅ 프로젝트 초기화 완료!

- 패키지 매니저: uv (또는 pip)
- 프로젝트 타입: <선택한 타입>
- LLM Provider: <선택한 provider(s)>
- 설치된 패키지: langchain, langsmith, ...
- 생성된 파일:
  - agent.py — 엔트리포인트
  - .env — 환경변수 템플릿

다음 단계:
1. .env 파일에 실제 API 키를 입력하세요
2. python agent.py 로 실행해보세요
```
