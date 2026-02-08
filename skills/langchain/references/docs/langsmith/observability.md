# LangSmith Observability Quickstart

> Source: https://docs.langchain.com/langsmith/observability-quickstart.md

## Environment Setup

```bash
export LANGSMITH_TRACING=true
export LANGSMITH_API_KEY="ls_..."
export LANGSMITH_PROJECT="my-project"  # optional
```

## Tracing with @traceable

```python
from langsmith import traceable

@traceable
def rag(question: str) -> str:
    docs = retriever(question)
    system_message = "Answer using: " + "\n".join(docs)
    resp = client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=[
            {"role": "system", "content": system_message},
            {"role": "user", "content": question},
        ],
    )
    return resp.choices[0].message.content
```

## Wrapping OpenAI Client

```python
from openai import OpenAI
from langsmith.wrappers import wrap_openai

client = wrap_openai(OpenAI())
```

## LangChain/LangGraph Auto-Tracing

LangChain and LangGraph are automatically traced when `LANGSMITH_TRACING=true` is set. No additional code needed.

## Framework-Specific Tracing

- LangChain: `trace-with-langchain.md`
- LangGraph: `trace-with-langgraph.md`
- Anthropic: `trace-anthropic.md`
- OpenAI: `trace-openai.md`
- AWS Bedrock: `trace-bedrock.md`
