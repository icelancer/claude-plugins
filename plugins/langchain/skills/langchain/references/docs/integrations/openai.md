# ChatOpenAI Integration

> Source: https://docs.langchain.com/oss/python/integrations/chat/openai.md

## Installation

```bash
pip install -U langchain-openai
```

```python
import os
os.environ["OPENAI_API_KEY"] = "sk-..."
```

## Basic Usage

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="gpt-4o",
    temperature=0.7,
    max_tokens=None,
    timeout=None,
)

messages = [
    ("system", "You are a helpful assistant."),
    ("human", "Translate 'I love programming' to French."),
]
response = llm.invoke(messages)
print(response.text)
```

## Tool Calling

```python
from pydantic import BaseModel, Field

class GetWeather(BaseModel):
    """Get the current weather in a given location"""
    location: str = Field(..., description="City and state")

llm_with_tools = llm.bind_tools([GetWeather])
ai_msg = llm_with_tools.invoke("what is the weather like in San Francisco")
print(ai_msg.tool_calls)

# Strict mode
llm_with_tools = llm.bind_tools([GetWeather], strict=True)
```

## Azure OpenAI

```python
# v1 API with API key
llm = ChatOpenAI(
    model="gpt-4o",
    base_url="https://{resource}.openai.azure.com/openai/v1/",
    api_key="your-azure-key"
)

# With Microsoft Entra ID
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
token_provider = get_bearer_token_provider(
    DefaultAzureCredential(), "https://cognitiveservices.azure.com/.default"
)
llm = ChatOpenAI(
    model="gpt-4o",
    base_url="https://{resource}.openai.azure.com/openai/v1/",
    api_key=token_provider
)
```

## Built-in Tools (Responses API)

```python
# Web Search
tool = {"type": "web_search_preview"}
llm_with_tools = llm.bind_tools([tool])

# File Search
tool = {"type": "file_search", "vector_store_ids": ["vs_..."]}

# Code Interpreter
tool = {"type": "code_interpreter", "container": {"type": "auto"}}

# Computer Use
tool = {"type": "computer_use_preview", "display_width": 1024, "display_height": 768}
```

## Reasoning Models

```python
llm = ChatOpenAI(
    model="gpt-5-nano",
    reasoning={"effort": "medium", "summary": "auto"}
)
```

## Multimodal

```python
# Image
content_block = {"type": "image", "url": "https://example.com/image.jpg"}

# PDF
content_block = {"type": "file", "base64": b64, "mime_type": "application/pdf", "filename": "doc.pdf"}

# Audio
content_block = {"type": "audio", "mime_type": "audio/wav", "base64": b64}
```

## Streaming with Usage

```python
llm = ChatOpenAI(model="gpt-4o-mini", stream_usage=True)
```

## Prompt Caching

```python
response = llm.invoke(messages, prompt_cache_key="translation-assistant-v1")
cache_read = response.usage_metadata.input_token_details.cache_read
```

## Features

- Tool calling & structured output
- Image/Audio/PDF input
- Token-level streaming
- Native async
- Token usage tracking
- Reasoning models
- Prompt caching
