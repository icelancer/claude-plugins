# LangChain Tools

> Source: https://docs.langchain.com/oss/python/langchain/tools.md

## Core Concept

Tools extend agent capabilities by serving as callable functions with well-defined inputs and outputs that get passed to a chat model. The model autonomously decides when and how to invoke them.

## Creating Tools

### Basic Definition

```python
from langchain.tools import tool

@tool
def search_database(query: str, limit: int = 10) -> str:
    """Search the customer database for records matching the query.

    Args:
        query: Search terms to look for
        limit: Maximum number of results to return
    """
    return f"Found {limit} results for '{query}'"
```

### Custom Name and Description

```python
@tool("web_search", description="Search the web for information.")
def search(query: str) -> str:
    """Search the web for information."""
    return f"Results for: {query}"
```

### Complex Schemas with Pydantic

```python
from pydantic import BaseModel, Field
from typing import Literal

class WeatherInput(BaseModel):
    location: str = Field(description="City name or coordinates")
    units: Literal["celsius", "fahrenheit"] = Field(default="celsius")
    include_forecast: bool = Field(default=False)

@tool(args_schema=WeatherInput)
def get_weather(location: str, units: str = "celsius", include_forecast: bool = False) -> str:
    """Get current weather and optional forecast."""
    temp = 22 if units == "celsius" else 72
    result = f"Current weather in {location}: {temp} degrees {units[0].upper()}"
    if include_forecast:
        result += "\nNext 5 days: Sunny"
    return result
```

## Reserved Parameter Names

Cannot use `config` or `runtime` as tool arguments — these are reserved for internal use.

## Accessing Runtime Context

Add `runtime: ToolRuntime` to tool signatures to access state, context, store, and stream writer.

### State Access

```python
from langchain.tools import tool, ToolRuntime

@tool
def get_last_user_message(runtime: ToolRuntime) -> str:
    """Get the most recent message from the user."""
    messages = runtime.state["messages"]
    for message in reversed(messages):
        if isinstance(message, HumanMessage):
            return message.content
    return "No user messages found"
```

### State Updates

```python
from langgraph.types import Command

@tool
def set_user_name(new_name: str) -> Command:
    """Set the user's name in the conversation state."""
    return Command(update={"user_name": new_name})
```

### Context (Immutable Config)

```python
from dataclasses import dataclass
from langchain.tools import tool, ToolRuntime

@dataclass
class UserContext:
    user_id: str

@tool
def get_account_info(runtime: ToolRuntime[UserContext]) -> str:
    """Get the current user's account information."""
    user_id = runtime.context.user_id
    # ... lookup logic
```

### Long-term Memory (Store)

```python
from langgraph.store.memory import InMemoryStore

@tool
def get_user_info(user_id: str, runtime: ToolRuntime) -> str:
    """Look up user info."""
    store = runtime.store
    user_info = store.get(("users",), user_id)
    return str(user_info.value) if user_info else "Unknown user"

@tool
def save_user_info(user_id: str, user_info: dict, runtime: ToolRuntime) -> str:
    """Save user info."""
    store = runtime.store
    store.put(("users",), user_id, user_info)
    return "Successfully saved user info."
```

### Stream Writer

```python
@tool
def get_weather(city: str, runtime: ToolRuntime) -> str:
    """Get weather for a given city."""
    writer = runtime.stream_writer
    writer(f"Looking up data for city: {city}")
    writer(f"Acquired data for city: {city}")
    return f"It's always sunny in {city}!"
```

## ToolNode (LangGraph)

Prebuilt node for executing tools with automatic parallel execution and error handling:

```python
from langgraph.prebuilt import ToolNode
from langgraph.graph import StateGraph, MessagesState, START, END

tool_node = ToolNode([search, calculator])

builder = StateGraph(MessagesState)
builder.add_node("tools", tool_node)
```

### Error Handling

```python
tool_node = ToolNode(tools, handle_tool_errors=True)
tool_node = ToolNode(tools, handle_tool_errors="Something went wrong, please try again.")

def handle_error(e: ValueError) -> str:
    return f"Invalid input: {e}"
tool_node = ToolNode(tools, handle_tool_errors=handle_error)
tool_node = ToolNode(tools, handle_tool_errors=(ValueError, TypeError))
```

### Conditional Routing

```python
from langgraph.prebuilt import tools_condition
builder.add_conditional_edges("llm", tools_condition)  # Routes to "tools" or END
```
