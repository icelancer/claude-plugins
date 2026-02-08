# LangGraph Graph API

> Source: https://docs.langchain.com/oss/python/langgraph/graph-api.md

## Core Components

1. **State**: Shared data structure (TypedDict or Pydantic BaseModel)
2. **Nodes**: Python functions that receive state and return updates
3. **Edges**: Functions determining which node executes next

## State Definition

### Schema Options

```python
from typing import Annotated
from typing_extensions import TypedDict
from operator import add

class State(TypedDict):
    foo: int
    bar: Annotated[list[str], add]  # Custom reducer: appends instead of overwrites
```

### Messages in State

```python
from langchain.messages import AnyMessage
from langgraph.graph.message import add_messages
from typing import Annotated

class GraphState(TypedDict):
    messages: Annotated[list[AnyMessage], add_messages]
```

Or use prebuilt:

```python
from langgraph.graph import MessagesState

class State(MessagesState):
    documents: list[str]
```

## Nodes

```python
def my_node(state: State, config: RunnableConfig, runtime: Runtime):
    return {"key": "updated_value"}

builder.add_node("node_name", my_node)
```

Special nodes: `START` (entry point), `END` (terminal)

### Node Caching

```python
from langgraph.cache.memory import InMemoryCache
from langgraph.types import CachePolicy

builder.add_node("expensive_node", fn, cache_policy=CachePolicy(ttl=3))
graph = builder.compile(cache=InMemoryCache())
```

## Edges

### Normal Edges

```python
graph.add_edge("node_a", "node_b")
```

### Conditional Edges

```python
def routing_function(state: State) -> str:
    return "node_b" if state["foo"] else "node_c"

graph.add_conditional_edges("node_a", routing_function)
graph.add_conditional_edges("node_a", routing_function, {True: "node_b", False: "node_c"})
```

### Entry Points

```python
from langgraph.graph import START
graph.add_edge(START, "node_a")
```

## Send API (Map-Reduce)

```python
from langgraph.types import Send

def continue_to_jokes(state: OverallState):
    return [Send("generate_joke", {"subject": s}) for s in state['subjects']]

graph.add_conditional_edges("node_a", continue_to_jokes)
```

## Command (Control Flow + State Updates)

```python
from langgraph.types import Command
from typing import Literal

def my_node(state: State) -> Command[Literal["my_other_node"]]:
    return Command(update={"foo": "bar"}, goto="my_other_node")
```

Navigate to parent graph:

```python
def my_node(state: State) -> Command[Literal["other_subgraph"]]:
    return Command(update={"foo": "bar"}, goto="other_subgraph", graph=Command.PARENT)
```

## Graph Compilation

```python
graph = graph_builder.compile(
    checkpointer=...,
    interrupt_before=[...],
    interrupt_after=[...]
)
```

**You MUST compile your graph before you can use it.**

## Input/Output Schemas

```python
class InputState(TypedDict):
    user_input: str

class OutputState(TypedDict):
    graph_output: str

class OverallState(TypedDict):
    foo: str
    user_input: str
    graph_output: str

builder = StateGraph(OverallState, input_schema=InputState, output_schema=OutputState)
```

## Context Schema

```python
from dataclasses import dataclass

@dataclass
class ContextSchema:
    llm_provider: str = "openai"

graph = StateGraph(State, context_schema=ContextSchema)
graph.invoke(inputs, context={"llm_provider": "anthropic"})
```

## Recursion Limit

```python
graph.invoke(inputs, config={"recursion_limit": 5})
```

## Remaining Steps

```python
from langgraph.managed import RemainingSteps

class State(TypedDict):
    messages: Annotated[list, lambda x, y: x + y]
    remaining_steps: RemainingSteps

def reasoning_node(state: State) -> dict:
    if state["remaining_steps"] <= 2:
        return {"messages": ["Wrapping up..."]}
    return {"messages": ["Thinking..."]}
```
