# LangChain Agents

> Source: https://docs.langchain.com/oss/python/langchain/agents.md

## Core Definition

Agents combine language models with tools to create systems that can reason about tasks, decide which tools to use, and iteratively work towards solutions.

## Key Components

### 1. Model Configuration

**Static Model (String Identifier):**
```python
from langchain.agents import create_agent
agent = create_agent("openai:gpt-5", tools=tools)
```

**Static Model (Instance):**
```python
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5", temperature=0.1, max_tokens=1000, timeout=30)
agent = create_agent(model, tools=tools)
```

**Dynamic Model Selection:**
```python
from langchain.agents.middleware import wrap_model_call, ModelRequest, ModelResponse

@wrap_model_call
def dynamic_model_selection(request: ModelRequest, handler) -> ModelResponse:
    message_count = len(request.state["messages"])
    model = advanced_model if message_count > 10 else basic_model
    return handler(request.override(model=model))

agent = create_agent(model=basic_model, tools=tools, middleware=[dynamic_model_selection])
```

### 2. Tools Definition

```python
from langchain.tools import tool
from langchain.agents import create_agent

@tool
def search(query: str) -> str:
    """Search for information."""
    return f"Results for: {query}"

agent = create_agent(model, tools=[search])
```

### 3. Tool Error Handling

```python
from langchain.agents.middleware import wrap_tool_call
from langchain.messages import ToolMessage

@wrap_tool_call
def handle_tool_errors(request, handler):
    try:
        return handler(request)
    except Exception as e:
        return ToolMessage(
            content=f"Tool error: Check input and retry. ({str(e)})",
            tool_call_id=request.tool_call["id"]
        )

agent = create_agent(model="gpt-4.1", tools=[search], middleware=[handle_tool_errors])
```

### 4. System Prompt Configuration

**String-based:**
```python
agent = create_agent(model, tools, system_prompt="You are a helpful assistant.")
```

**Message-based (with caching):**
```python
from langchain.messages import SystemMessage, HumanMessage

agent = create_agent(
    model="anthropic:claude-sonnet-4-5",
    system_prompt=SystemMessage(content=[
        {"type": "text", "text": "Content"},
        {"type": "text", "text": "Cached content", "cache_control": {"type": "ephemeral"}}
    ])
)
```

**Dynamic Prompt:**
```python
from langchain.agents.middleware import dynamic_prompt, ModelRequest

@dynamic_prompt
def user_role_prompt(request: ModelRequest) -> str:
    user_role = request.runtime.context.get("user_role", "user")
    return f"Base prompt. {('Technical details' if user_role == 'expert' else 'Simple explanation')}"

agent = create_agent(model="gpt-4.1", tools=[web_search], middleware=[user_role_prompt])
```

## Dynamic Tools

**Filtering Pre-registered Tools:**
```python
from langchain.agents.middleware import wrap_model_call

@wrap_model_call
def filter_tools(request: ModelRequest, handler):
    user_role = request.runtime.context.user_role
    tools = request.tools if user_role == "admin" else [t for t in request.tools if t.name.startswith("read_")]
    return handler(request.override(tools=tools))

agent = create_agent(model="gpt-4o", tools=[read_data, write_data], middleware=[filter_tools])
```

**Runtime Tool Registration:**
```python
from langchain.agents.middleware import AgentMiddleware

class DynamicToolMiddleware(AgentMiddleware):
    def wrap_model_call(self, request: ModelRequest, handler):
        updated = request.override(tools=[*request.tools, calculate_tip])
        return handler(updated)

    def wrap_tool_call(self, request: ToolCallRequest, handler):
        if request.tool_call["name"] == "calculate_tip":
            return handler(request.override(tool=calculate_tip))
        return handler(request)

agent = create_agent(model="gpt-4o", tools=[get_weather], middleware=[DynamicToolMiddleware()])
```

## Invocation

```python
result = agent.invoke(
    {"messages": [{"role": "user", "content": "What's the weather in San Francisco?"}]}
)
```

## Streaming

```python
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "Search for AI news"}]},
    stream_mode="values"
):
    latest_message = chunk["messages"][-1]
```

## Structured Output

**ToolStrategy:**
```python
from pydantic import BaseModel
from langchain.agents.structured_output import ToolStrategy

class ContactInfo(BaseModel):
    name: str
    email: str
    phone: str

agent = create_agent(model="gpt-4.1-mini", tools=[search_tool], response_format=ToolStrategy(ContactInfo))
result = agent.invoke({"messages": [{"role": "user", "content": "Extract contact info..."}]})
```

**ProviderStrategy:**
```python
from langchain.agents.structured_output import ProviderStrategy
agent = create_agent(model="gpt-4.1", response_format=ProviderStrategy(ContactInfo))
```

## Custom State

**Via Middleware:**
```python
from langchain.agents import AgentState
from langchain.agents.middleware import AgentMiddleware
from typing import TypedDict

class CustomState(AgentState):
    user_preferences: dict

class CustomMiddleware(AgentMiddleware):
    state_schema = CustomState

agent = create_agent(model, tools=tools, middleware=[CustomMiddleware()])
result = agent.invoke({
    "messages": [{"role": "user", "content": "message"}],
    "user_preferences": {"style": "technical"}
})
```

**Via state_schema:**
```python
agent = create_agent(model, tools=[tool1, tool2], state_schema=CustomState)
```
