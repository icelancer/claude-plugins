# Vector Store Integrations

> Source: https://docs.langchain.com/oss/python/integrations/vectorstores/index.md

## Core Concept

Vector stores embed documents and perform similarity searches. Two phases: indexing (documents → embeddings → store) and retrieval (query → embedding → similar docs).

## Standard Interface

```python
from langchain_core.vectorstores import InMemoryVectorStore

vector_store = InMemoryVectorStore(embedding=SomeEmbeddingModel())
```

## Common Operations

### Adding Documents

```python
vector_store.add_documents(documents=[doc1, doc2], ids=["id1", "id2"])
```

### Deleting Documents

```python
vector_store.delete(ids=["id1"])
```

### Similarity Search

```python
similar_docs = vector_store.similarity_search(
    "your query here",
    k=3,
    filter={"source": "tweets"}
)
```

## Similarity Metrics

- Cosine similarity
- Euclidean distance
- Dot product

## Popular Implementations

- **In-memory**: `InMemoryVectorStore` (langchain-core)
- **Chroma**: `pip install langchain-chroma`
- **FAISS**: `pip install langchain-community faiss-cpu`
- **Pinecone**: `pip install langchain-pinecone`
- **Qdrant**: `pip install langchain-qdrant`
- **Milvus**: `pip install langchain-milvus`
- **PGVector**: `pip install langchain-postgres`
- **MongoDB Atlas**: `pip install langchain-mongodb`
- **Elasticsearch**: `pip install langchain-elasticsearch`
- **Weaviate**: `pip install langchain-weaviate`

## Embedding Model Providers

OpenAI, Azure, Google Gemini, AWS Bedrock, HuggingFace, Ollama, Cohere, Mistral AI, etc.
