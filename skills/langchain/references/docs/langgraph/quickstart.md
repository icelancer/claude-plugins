# LangGraph Quickstart

> Source: https://docs.langchain.com/oss/python/langgraph/quickstart.md

## Calculator Agent Example

### Tools Definition

```python
from langchain.tools import tool

@tool
def multiply(a: int, b: int) -> int:
    """Multiply two numbers."""
    return a * b

@tool
def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b

@tool
def divide(a: int, b: int) -> float:
    """Divide two numbers."""
    return a / b
```

## Approach 1: Graph API

```python
import operator
from typing import Annotated
from typing_extensions import TypedDict
from langchain.messages import AnyMessage
from langgraph.graph import StateGraph, START, END

class MessagesState(TypedDict):
    messages: Annotated[list[AnyMessage], operator.add]
    llm_calls: int

def llm_call(state: dict):
    """Invoke model with tools."""
    response = model_with_tools.invoke(state["messages"])
    return {"messages": [response], "llm_calls": state.get("llm_calls", 0) + 1}

def tool_node(state: dict):
    """Execute tool calls."""
    results = []
    for tool_call in state["messages"][-1].tool_calls:
        tool_fn = {"multiply": multiply, "add": add, "divide": divide}[tool_call["name"]]
        result = tool_fn.invoke(tool_call)
        results.append(result)
    return {"messages": results}

def should_continue(state: MessagesState):
    if state["messages"][-1].tool_calls:
        return "tools"
    return END

# Build graph
graph = StateGraph(MessagesState)
graph.add_node("llm_call", llm_call)
graph.add_node("tools", tool_node)
graph.add_edge(START, "llm_call")
graph.add_conditional_edges("llm_call", should_continue, {"tools": "tools", END: END})
graph.add_edge("tools", "llm_call")
app = graph.compile()
```

## Approach 2: Functional API

```python
from langgraph.func import entrypoint, task

@task
def call_llm(messages):
    return model_with_tools.invoke(messages)

@task
def call_tool(tool_call):
    tool_fn = {"multiply": multiply, "add": add, "divide": divide}[tool_call["name"]]
    return tool_fn.invoke(tool_call)

@entrypoint()
def agent(messages):
    llm_response = call_llm(messages).result()
    while llm_response.tool_calls:
        tool_results = [call_tool(tc).result() for tc in llm_response.tool_calls]
        messages = messages + [llm_response] + tool_results
        llm_response = call_llm(messages).result()
    return llm_response
```

## Setup

```python
from langchain_anthropic import ChatAnthropic

model = ChatAnthropic(model="claude-sonnet-4-5-20250929", temperature=0)
tools = [multiply, add, divide]
model_with_tools = model.bind_tools(tools)
```

## Invocation

```python
from langchain.messages import HumanMessage

result = app.invoke({"messages": [HumanMessage("What is 2 * 3 + 4?")]})
```
