# LangChain Streaming

> Source: https://docs.langchain.com/oss/python/langchain/streaming/overview.md

## Stream Modes

| Mode | Purpose |
|------|---------|
| `updates` | Emits state changes after each agent step |
| `messages` | Streams token tuples with metadata from LLM calls |
| `custom` | Transmits user-defined signals via stream writer |

Multiple modes can be combined: `stream_mode=["updates", "custom"]`

## Key APIs

- `agent.stream(input, stream_mode="mode_name")`
- `agent.astream(input, stream_mode="mode_name")`

## Basic Streaming

```python
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "query"}]},
    stream_mode="updates"
):
    for step, data in chunk.items():
        print(f"step: {step}, content: {data}")
```

## Multiple Mode Streaming

```python
for stream_mode, chunk in agent.stream(
    input_data,
    stream_mode=["updates", "custom"]
):
    print(f"Mode: {stream_mode}, Data: {chunk}")
```

## Custom Stream Writer

```python
from langgraph.config import get_stream_writer

writer = get_stream_writer()
writer("Custom message or data")
```

## Disable Streaming

```python
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1", streaming=False)
```

## Advanced Features

- **Sub-agents:** Use `name` parameter on agents and set `subgraphs=True` when streaming
- **Human-in-the-loop:** Integrate `HumanInTheLoopMiddleware` with checkpointer support
- **Chunk aggregation:** Combine `AIMessageChunk` objects using `+` operator
- **Resume interrupted:** `Command(resume=decisions)` for resuming interrupted streams
