---
name: langchain
description: >
  LangChain, LangGraph, LangSmith 관련 코드 작업 시 최신 문서를 참조하여 정확한 코드를 작성하는 스킬.
  Trigger keywords: langchain, langgraph, langsmith, agent, agents, tool, tools,
  RAG, retrieval, streaming, MCP, multi-agent, graph API, functional API,
  create_agent, StateGraph, ChatModel, embeddings, vector store, tracing,
  evaluation, memory, middleware, deep agents, init_chat_model
---

# LangChain Documentation-Aware Coding Skill

## Purpose

LLM의 학습 데이터에 포함된 LangChain API는 이미 deprecated되었을 수 있습니다.
이 스킬은 로컬에 다운받은 최신 문서와 `docs.langchain.com`의 실시간 문서를 참조하여 정확한 코드를 작성합니다.

**절대로 기억에 의존하여 LangChain 코드를 작성하지 마세요. 반드시 아래 워크플로우를 따르세요.**

## Workflow

### Step 1: 사용자 요청 분류

사용자의 요청을 아래 카테고리로 분류합니다:

| Product | Feature Area | Local Docs |
|---------|-------------|------------|
| **LangChain** | agents, tools, models, RAG, streaming, memory, multi-agent, middleware, MCP, structured output | `references/docs/langchain-core/` |
| **LangGraph** | graph API, functional API, persistence, interrupts, workflows, subgraphs | `references/docs/langgraph/` |
| **LangSmith** | tracing, evaluation, observability | `references/docs/langsmith/` |
| **Integrations** | Anthropic, OpenAI, vector stores, embeddings | `references/docs/integrations/` |
| **Deep Agents** | planning agents, subagents, skills, customization | (WebFetch only) |

### Step 2: 로컬 문서 검색 (우선)

먼저 `references/docs/` 디렉토리에서 관련 로컬 문서를 Read/Grep으로 검색합니다.

**로컬 문서 맵:**

| Topic | Local File |
|-------|-----------|
| Agent 생성 (create_agent) | `docs/langchain-core/agents.md` |
| Tool 정의 (@tool, ToolRuntime) | `docs/langchain-core/tools.md` |
| Model 초기화 (init_chat_model) | `docs/langchain-core/models.md` |
| RAG 패턴 | `docs/langchain-core/rag.md` |
| Structured Output | `docs/langchain-core/structured-output.md` |
| Streaming | `docs/langchain-core/streaming.md` |
| Memory (단기/장기) | `docs/langchain-core/memory.md` |
| Multi-Agent | `docs/langchain-core/multi-agent.md` |
| MCP Integration | `docs/langchain-core/mcp.md` |
| LangGraph Graph API | `docs/langgraph/graph-api.md` |
| LangGraph Functional API | `docs/langgraph/functional-api.md` |
| LangGraph Persistence | `docs/langgraph/persistence.md` |
| LangGraph Interrupts | `docs/langgraph/interrupts.md` |
| LangGraph Quickstart | `docs/langgraph/quickstart.md` |
| ChatAnthropic | `docs/integrations/anthropic.md` |
| ChatOpenAI | `docs/integrations/openai.md` |
| Vector Stores | `docs/integrations/vectorstores.md` |
| LangSmith Tracing | `docs/langsmith/observability.md` |
| LangSmith Evaluation | `docs/langsmith/evaluation.md` |

### Step 3: WebFetch로 추가 문서 (로컬에 없는 경우)

로컬 문서에서 답을 찾을 수 없으면, `references/url-index.md`에서 관련 URL을 찾아 WebFetch합니다.

```
WebFetch(url: "https://docs.langchain.com/oss/python/langchain/guardrails.md",
         prompt: "Extract the complete code examples, API signatures, and import statements")
```

**WebFetch는 다음 경우에만 사용:**
- 로컬 문서에 해당 주제가 없을 때
- 로컬 문서의 정보가 불충분할 때
- Deep Agents, 특정 provider 통합 등 로컬에 없는 주제

### Step 4: 문서 기반 코드 작성

로컬 문서 또는 WebFetch로 가져온 문서의 코드 예제와 API를 기반으로 코드를 작성합니다.

**규칙:**
- 문서의 import 경로를 그대로 사용
- 문서에 없는 API는 사용하지 않음
- deprecated 경고가 있으면 대체 API 사용
- 문서의 패턴을 따름 (예: async/sync, class/function 스타일)

### Step 5: Fallback (문서 없는 경우)

로컬 문서도 WebFetch도 사용할 수 없으면 아래 Quick Reference의 기본 패턴을 사용하되, 사용자에게 문서 접근 실패를 알립니다.

---

## Quick Reference (Fallback Patterns)

> 아래는 fetch 실패 시 사용할 기본 패턴입니다. 가능하면 항상 최신 문서를 fetch하세요.

### Agent 생성 (LangChain)

```python
from langchain.chat_models import init_chat_model
from langchain.agents import create_agent

model = init_chat_model("claude-sonnet-4-5-20250929", model_provider="anthropic")

agent = create_agent(
    model,
    tools=[...],
    prompt="You are a helpful assistant.",
)

# 실행
result = agent.invoke({"input": "Hello"})

# 스트리밍
async for event in agent.astream({"input": "Hello"}):
    print(event)
```

### Tool 정의

```python
from langchain_core.tools import tool

@tool
def search(query: str) -> str:
    """Search the web for information."""
    # implementation
    return results

@tool
def calculator(expression: str) -> float:
    """Evaluate a math expression."""
    return eval(expression)
```

### Model 초기화

```python
from langchain.chat_models import init_chat_model

# Anthropic
model = init_chat_model("claude-sonnet-4-5-20250929", model_provider="anthropic")

# OpenAI
model = init_chat_model("gpt-4o", model_provider="openai")

# Google
model = init_chat_model("gemini-2.0-flash", model_provider="google_genai")

# AWS Bedrock
model = init_chat_model("anthropic.claude-sonnet-4-5-20250929-v1:0", model_provider="bedrock")
```

### Structured Output

```python
from pydantic import BaseModel, Field

class ResponseFormat(BaseModel):
    answer: str = Field(description="The answer")
    confidence: float = Field(description="Confidence 0-1")

structured_model = model.with_structured_output(ResponseFormat)
result = structured_model.invoke("What is 2+2?")
# result.answer, result.confidence
```

### RAG 기본 패턴

```python
from langchain_core.tools import tool
from langchain.chat_models import init_chat_model
from langchain.agents import create_agent

@tool
def retrieve(query: str) -> str:
    """Retrieve relevant documents from the knowledge base."""
    # vector store retrieval logic
    return relevant_docs

model = init_chat_model("claude-sonnet-4-5-20250929", model_provider="anthropic")
rag_agent = create_agent(model, tools=[retrieve])
```

### LangGraph StateGraph

```python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict

class State(TypedDict):
    messages: list
    # additional state fields

graph = StateGraph(State)
graph.add_node("agent", agent_node)
graph.add_node("tools", tool_node)
graph.add_edge(START, "agent")
graph.add_conditional_edges("agent", should_continue, {"continue": "tools", "end": END})
graph.add_edge("tools", "agent")

app = graph.compile()
result = app.invoke({"messages": [("user", "Hello")]})
```

### LangGraph Functional API

```python
from langgraph.func import entrypoint, task

@task
def process_step(input_data):
    # processing logic
    return result

@entrypoint()
def my_workflow(input_data):
    result = process_step(input_data).result()
    return result
```

### LangSmith Tracing

```python
import os
os.environ["LANGSMITH_API_KEY"] = "your-api-key"
os.environ["LANGSMITH_TRACING"] = "true"
os.environ["LANGSMITH_PROJECT"] = "my-project"

# LangChain/LangGraph 코드는 자동으로 traced됩니다.
# 커스텀 트레이싱:
from langsmith import traceable

@traceable
def my_function(input_data):
    # your logic
    return result
```

### LangSmith Evaluation

```python
from langsmith import Client, evaluate

client = Client()

# 데이터셋 생성
dataset = client.create_dataset("my-dataset")
client.create_examples(
    inputs=[{"question": "What is LangChain?"}],
    outputs=[{"answer": "A framework for LLM apps"}],
    dataset_id=dataset.id,
)

# 평가 실행
def my_app(inputs: dict) -> dict:
    # your app logic
    return {"answer": "..."}

results = evaluate(
    my_app,
    data="my-dataset",
    evaluators=[...],
)
```

---

## Python Package / Import Cheat Sheet

| Package | Install | Primary Imports |
|---------|---------|-----------------|
| `langchain` | `pip install langchain` | `from langchain.agents import create_agent`<br>`from langchain.chat_models import init_chat_model` |
| `langchain-core` | (auto with langchain) | `from langchain_core.tools import tool`<br>`from langchain_core.messages import HumanMessage, AIMessage`<br>`from langchain_core.prompts import ChatPromptTemplate` |
| `langchain-anthropic` | `pip install langchain-anthropic` | `from langchain_anthropic import ChatAnthropic` |
| `langchain-openai` | `pip install langchain-openai` | `from langchain_openai import ChatOpenAI, OpenAIEmbeddings` |
| `langchain-google-genai` | `pip install langchain-google-genai` | `from langchain_google_genai import ChatGoogleGenerativeAI` |
| `langchain-aws` | `pip install langchain-aws` | `from langchain_aws import ChatBedrock` |
| `langchain-community` | `pip install langchain-community` | `from langchain_community.vectorstores import FAISS`<br>`from langchain_community.document_loaders import WebBaseLoader` |
| `langgraph` | `pip install langgraph` | `from langgraph.graph import StateGraph, START, END`<br>`from langgraph.func import entrypoint, task`<br>`from langgraph.prebuilt import create_react_agent` |
| `langsmith` | `pip install langsmith` | `from langsmith import Client, traceable, evaluate` |

### Provider-Specific Model Init

```python
# Option A: Universal init (recommended)
from langchain.chat_models import init_chat_model
model = init_chat_model("claude-sonnet-4-5-20250929", model_provider="anthropic")

# Option B: Provider-specific class
from langchain_anthropic import ChatAnthropic
model = ChatAnthropic(model="claude-sonnet-4-5-20250929")

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4o")
```

### Common Environment Variables

```bash
# LangSmith
export LANGSMITH_API_KEY="ls_..."
export LANGSMITH_TRACING="true"
export LANGSMITH_PROJECT="my-project"

# Providers
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export GOOGLE_API_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```
