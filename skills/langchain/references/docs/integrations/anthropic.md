# ChatAnthropic Integration

> Source: https://docs.langchain.com/oss/python/integrations/chat/anthropic.md

## Installation

```bash
pip install -U langchain-anthropic
```

```python
import os
os.environ["ANTHROPIC_API_KEY"] = "sk-ant-..."
```

## Basic Usage

```python
from langchain_anthropic import ChatAnthropic

model = ChatAnthropic(
    model="claude-haiku-4-5-20251001",
    temperature=0.7,
    max_tokens=1024,
)

response = model.invoke(messages)
print(response.text)
```

## Invocation Methods

```python
# Sync
response = model.invoke(messages)

# Streaming
for chunk in model.stream(messages):
    print(chunk.text, end="")

# Async
await model.ainvoke(messages)
async for chunk in await model.astream(messages):
    pass
await model.abatch([messages])
```

## Tool Use

```python
from pydantic import BaseModel, Field

class GetWeather(BaseModel):
    location: str = Field(description="City and state")

model_with_tools = model.bind_tools([GetWeather])
response = model_with_tools.invoke("What's the weather in LA?")
print(response.tool_calls)

# Strict mode (Claude Sonnet 4.5+)
model_with_tools = model.bind_tools([get_weather], strict=True)
```

## Multimodal Inputs

```python
from langchain.messages import HumanMessage

# Image from URL
message = HumanMessage(content=[
    {"type": "text", "text": "Describe this image"},
    {"type": "image", "url": "https://example.com/image.jpg"},
])

# Base64 image
message = HumanMessage(content=[
    {"type": "text", "text": "Describe the image"},
    {"type": "image", "base64": image_data, "mime_type": "image/jpeg"},
])
```

## Extended Thinking

```python
model = ChatAnthropic(
    model="claude-sonnet-4-5-20250929",
    thinking={"type": "enabled", "budget_tokens": 2000},
)
response = model.invoke("What is the cube root of 50.653?")
```

## Prompt Caching

```python
messages = [
    {
        "role": "system",
        "content": [
            {"type": "text", "text": "You are helpful"},
            {"type": "text", "text": large_document, "cache_control": {"type": "ephemeral"}},
        ],
    },
]
response = model.invoke(messages)
```

## Structured Output

```python
from pydantic import BaseModel

class Movie(BaseModel):
    title: str
    year: int

model_structured = model.with_structured_output(Movie, method="json_schema")
response = model_structured.invoke("Tell me about Inception")
```

## Built-in Tools

```python
# Code execution
from anthropic.types.beta import BetaCodeExecutionTool20250825Param
code_tool = BetaCodeExecutionTool20250825Param(type="code_execution_20250825", name="code_execution")

# Web search
from anthropic.types.beta import BetaWebSearchTool20250305Param
search_tool = BetaWebSearchTool20250305Param(type="web_search_20250305", name="web_search", max_uses=3)

model_with_tools = model.bind_tools([code_tool, search_tool])
```

## Features

- Tool calling & structured output
- Image/PDF input
- Token-level streaming
- Native async
- Token usage tracking
- Extended thinking
- Prompt caching
