# RAG (Retrieval-Augmented Generation)

> Source: https://docs.langchain.com/oss/python/langchain/rag.md

## Overview

RAG enables question-answering applications by combining retrieval with generation. Two approaches: agentic RAG (flexible) and two-step chain (simple).

## Installation

```bash
pip install langchain langchain-text-splitters langchain-community bs4
```

## Indexing Pipeline

### 1. Document Loading

```python
from langchain_community.document_loaders import WebBaseLoader
import bs4

bs4_strainer = bs4.SoupStrainer(class_=("post-title", "post-header", "post-content"))
loader = WebBaseLoader(
    web_paths=("https://lilianweng.github.io/posts/2023-06-23-agent/",),
    bs_kwargs={"parse_only": bs4_strainer},
)
docs = loader.load()
```

### 2. Text Splitting

```python
from langchain_text_splitters import RecursiveCharacterTextSplitter

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    add_start_index=True,
)
all_splits = text_splitter.split_documents(docs)
```

### 3. Vector Storage

```python
document_ids = vector_store.add_documents(documents=all_splits)
```

## RAG Agent Implementation

```python
from langchain.tools import tool
from langchain.agents import create_agent

@tool(response_format="content_and_artifact")
def retrieve_context(query: str):
    """Retrieve information to help answer a query."""
    retrieved_docs = vector_store.similarity_search(query, k=2)
    serialized = "\n\n".join(
        (f"Source: {doc.metadata}\nContent: {doc.page_content}")
        for doc in retrieved_docs
    )
    return serialized, retrieved_docs

tools = [retrieve_context]
prompt = (
    "You have access to a tool that retrieves context from a blog post. "
    "Use the tool to help answer user queries."
)
agent = create_agent(model, tools, system_prompt=prompt)
```

**Usage:**
```python
query = "What is the standard method for Task Decomposition?"
for event in agent.stream(
    {"messages": [{"role": "user", "content": query}]},
    stream_mode="values",
):
    event["messages"][-1].pretty_print()
```

## RAG Chain (Two-Step with Middleware)

```python
from langchain.agents.middleware import dynamic_prompt, ModelRequest

@dynamic_prompt
def prompt_with_context(request: ModelRequest) -> str:
    """Inject context into state messages."""
    last_query = request.state["messages"][-1].text
    retrieved_docs = vector_store.similarity_search(last_query)
    docs_content = "\n\n".join(doc.page_content for doc in retrieved_docs)
    system_message = (
        "You are a helpful assistant. Use the following context:\n\n"
        f"{docs_content}"
    )
    return system_message

agent = create_agent(model, tools=[], middleware=[prompt_with_context])
```

## Agent vs Chain Trade-offs

| Agent | Chain |
|-------|-------|
| Search only when needed | Always performs search |
| Contextual queries | Single inference call |
| Multiple searches supported | Reduced latency |
| Two inference calls required | Less flexible |

## Supported Components

- **Embedding models**: OpenAI, Azure, Google, AWS Bedrock, HuggingFace, Ollama, Cohere, etc.
- **Vector stores**: In-memory, Chroma, FAISS, Milvus, MongoDB, PGVector, Pinecone, Qdrant, etc.
