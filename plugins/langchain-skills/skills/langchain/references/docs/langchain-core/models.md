# LangChain Models

> Source: https://docs.langchain.com/oss/python/langchain/models.md

## Initialization

### Using init_chat_model

```python
from langchain.chat_models import init_chat_model

model = init_chat_model("gpt-4.1")
response = model.invoke("Why do parrots talk?")
```

### Provider-Specific

**OpenAI:**
```python
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1")
```

**Anthropic:**
```python
from langchain_anthropic import ChatAnthropic
model = ChatAnthropic(model="claude-sonnet-4-5-20250929")
```

**Azure OpenAI:**
```python
from langchain_openai import AzureChatOpenAI
model = AzureChatOpenAI(
    model="gpt-4.1",
    azure_deployment=os.environ["AZURE_OPENAI_DEPLOYMENT_NAME"]
)
```

**Google Gemini:**
```python
from langchain_google_genai import ChatGoogleGenerativeAI
model = ChatGoogleGenerativeAI(model="gemini-2.5-flash-lite")
```

**AWS Bedrock:**
```python
from langchain_aws import ChatBedrock
model = ChatBedrock(model="anthropic.claude-3-5-sonnet-20240620-v1:0")
```

**HuggingFace:**
```python
from langchain_huggingface import ChatHuggingFace, HuggingFaceEndpoint
llm = HuggingFaceEndpoint(repo_id="microsoft/Phi-3-mini-4k-instruct", temperature=0.7, max_length=1024)
model = ChatHuggingFace(llm=llm)
```

## Model Parameters

```python
model = init_chat_model(
    "claude-sonnet-4-5-20250929",
    temperature=0.7,
    timeout=30,
    max_tokens=1000,
)
```

Standard params: `model`, `api_key`, `temperature`, `max_tokens`, `timeout`, `max_retries`

## Invocation Methods

### Invoke (Single Response)

```python
response = model.invoke("Why do parrots have colorful feathers?")

# Dictionary format
conversation = [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Translate: I love programming."},
]
response = model.invoke(conversation)

# Message objects
from langchain.messages import HumanMessage, AIMessage, SystemMessage
conversation = [
    SystemMessage("You are a helpful assistant."),
    HumanMessage("Translate: I love programming."),
]
response = model.invoke(conversation)
```

### Stream

```python
for chunk in model.stream("Why do parrots have colorful feathers?"):
    print(chunk.text, end="|", flush=True)

# Stream with content blocks
for chunk in model.stream("What color is the sky?"):
    for block in chunk.content_blocks:
        if block["type"] == "reasoning" and (reasoning := block.get("reasoning")):
            print(f"Reasoning: {reasoning}")
        elif block["type"] == "text":
            print(block["text"])
```

### Batch

```python
responses = model.batch([
    "Why do parrots have colorful feathers?",
    "How do airplanes fly?",
])

model.batch(list_of_inputs, config={'max_concurrency': 5})
```

### Streaming Events (Async)

```python
async for event in model.astream_events("Hello"):
    if event["event"] == "on_chat_model_stream":
        print(f"Token: {event['data']['chunk'].text}")
```

## Tool Calling

### Basic Tool Binding

```python
from langchain.tools import tool

@tool
def get_weather(location: str) -> str:
    """Get the weather at a location."""
    return f"It's sunny in {location}."

model_with_tools = model.bind_tools([get_weather])
response = model_with_tools.invoke("What's the weather like in Boston?")

for tool_call in response.tool_calls:
    print(f"Tool: {tool_call['name']}, Args: {tool_call['args']}")
```

### Tool Execution Loop

```python
model_with_tools = model.bind_tools([get_weather])
messages = [{"role": "user", "content": "What's the weather in Boston?"}]
ai_msg = model_with_tools.invoke(messages)
messages.append(ai_msg)

for tool_call in ai_msg.tool_calls:
    tool_result = get_weather.invoke(tool_call)
    messages.append(tool_result)

final_response = model_with_tools.invoke(messages)
```

### Forcing Tool Calls

```python
model_with_tools = model.bind_tools([tool_1], tool_choice="any")
model_with_tools = model.bind_tools([tool_1], tool_choice="tool_1")
```

## Structured Output

### Pydantic

```python
from pydantic import BaseModel, Field

class Movie(BaseModel):
    title: str = Field(..., description="The title of the movie")
    year: int = Field(..., description="The year the movie was released")
    director: str
    rating: float

model_with_structure = model.with_structured_output(Movie)
response = model_with_structure.invoke("Provide details about the movie Inception")
```

### TypedDict

```python
from typing_extensions import TypedDict, Annotated

class MovieDict(TypedDict):
    title: Annotated[str, ..., "The title of the movie"]
    year: Annotated[int, ..., "The year"]

model_with_structure = model.with_structured_output(MovieDict)
```

### JSON Schema

```python
json_schema = {
    "title": "Movie",
    "type": "object",
    "properties": {
        "title": {"type": "string"},
        "year": {"type": "integer"},
    },
    "required": ["title", "year"]
}
model_with_structure = model.with_structured_output(json_schema, method="json_schema")
```

## Configurable Models

```python
configurable_model = init_chat_model(temperature=0)

configurable_model.invoke(
    "what's your name",
    config={"configurable": {"model": "gpt-5-nano"}},
)
configurable_model.invoke(
    "what's your name",
    config={"configurable": {"model": "claude-sonnet-4-5-20250929"}},
)
```

## Rate Limiting

```python
from langchain_core.rate_limiters import InMemoryRateLimiter

rate_limiter = InMemoryRateLimiter(requests_per_second=0.1, check_every_n_seconds=0.1, max_bucket_size=10)
model = init_chat_model("gpt-5", model_provider="openai", rate_limiter=rate_limiter)
```

## Token Usage Tracking

```python
from langchain_core.callbacks import get_usage_metadata_callback

with get_usage_metadata_callback() as cb:
    model.invoke("Hello")
    print(cb.usage_metadata)
```

## Base URL (OpenAI-Compatible APIs)

```python
model = init_chat_model(
    model="MODEL_NAME",
    model_provider="openai",
    base_url="BASE_URL",
    api_key="YOUR_API_KEY",
)
```
