# Structured Output

> Source: https://docs.langchain.com/oss/python/langchain/structured-output.md

## Overview

`create_agent` enables agents to return data in predictable formats using JSON objects, Pydantic models, or dataclasses. The structured response is available in the `'structured_response'` key of the agent's final state.

## Response Format Parameter

The `response_format` parameter accepts:
- **`ToolStrategy[T]`**: Uses tool calling for structured output
- **`ProviderStrategy[T]`**: Uses provider-native structured output
- **`type[T]`**: Schema type with automatic strategy selection
- **`None`**: No explicit structured output

## Provider Strategy

For models supporting native structured output (OpenAI, Anthropic, xAI):

```python
from langchain.agents.structured_output import ProviderStrategy

class ProviderStrategy(Generic[SchemaT]):
    schema: type[SchemaT]
    strict: bool | None = None  # requires langchain>=1.2
```

## Tool Strategy

For models without native structured output support:

```python
from langchain.agents.structured_output import ToolStrategy

class ToolStrategy(Generic[SchemaT]):
    schema: type[SchemaT]
    tool_message_content: str | None
    handle_errors: Union[bool, str, type[Exception], ...]
```

**Parameters:**
- `schema`: Supports Pydantic, dataclasses, TypedDict, JSON Schema, and Union types
- `tool_message_content`: Customizes conversation history messages
- `handle_errors`: Controls retry on validation failures

## Usage Examples

```python
from pydantic import BaseModel
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy, ProviderStrategy

class ContactInfo(BaseModel):
    name: str
    email: str
    phone: str

# ToolStrategy
agent = create_agent(model, tools=[search_tool], response_format=ToolStrategy(ContactInfo))

# ProviderStrategy
agent = create_agent(model, response_format=ProviderStrategy(ContactInfo))

# Auto-select strategy
agent = create_agent(model, response_format=ContactInfo)

result = agent.invoke({"messages": [{"role": "user", "content": "Extract contact info..."}]})
structured = result["structured_response"]
```

## Error Handling

Handles `StructuredOutputValidationError` and `MultipleStructuredOutputsError` automatically with retry.
