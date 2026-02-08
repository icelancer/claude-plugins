# LangGraph Persistence

> Source: https://docs.langchain.com/oss/python/langgraph/persistence.md

## Checkpointers

Save graph state snapshots at each super-step for memory, human-in-the-loop, time travel, and fault tolerance.

### Thread Management

```python
config = {"configurable": {"thread_id": "1"}}
```

### Retrieving State

```python
config = {"configurable": {"thread_id": "1"}}
graph.get_state(config)                    # Latest state
list(graph.get_state_history(config))     # Full history (most recent first)
```

### Replaying from Checkpoint

```python
config = {"configurable": {"thread_id": "1", "checkpoint_id": "0c62ca34..."}}
graph.invoke(None, config=config)
```

### Updating State

```python
graph.update_state(config, {"foo": 2, "bar": ["b"]})
# If bar has add reducer, new values append rather than replace
```

## Checkpointer Libraries

| Package | Saver | Use Case |
|---------|-------|----------|
| `langgraph-checkpoint` | `InMemorySaver` | Development (included by default) |
| `langgraph-checkpoint-sqlite` | `SqliteSaver` / `AsyncSqliteSaver` | Local persistence |
| `langgraph-checkpoint-postgres` | `PostgresSaver` / `AsyncPostgresSaver` | Production |
| `langgraph-checkpoint-cosmosdb` | Azure Cosmos DB | Azure environments |

## Store (Cross-Thread Memory)

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()
namespace = (user_id, "memories")

# Save
store.put(namespace, memory_id, {"food_preference": "pizza"})

# Retrieve
memories = store.search(namespace)
```

### Semantic Search

```python
store = InMemoryStore(
    index={
        "embed": init_embeddings("openai:text-embedding-3-small"),
        "dims": 1536,
        "fields": ["food_preference", "$"]
    }
)
memories = store.search(namespace, query="user food preferences", limit=3)
```

### Compile with Both

```python
graph = graph.compile(checkpointer=InMemorySaver(), store=in_memory_store)
```

### Access Store in Nodes

```python
def call_model(state: MessagesState, config: RunnableConfig, *, store: BaseStore):
    user_id = config["configurable"]["user_id"]
    namespace = (user_id, "memories")
    memories = store.search(namespace, query=state["messages"][-1].content)
```

## Serialization & Encryption

```python
# Pickle fallback
from langgraph.checkpoint.serde.jsonplus import JsonPlusSerializer
graph.compile(checkpointer=InMemorySaver(serde=JsonPlusSerializer(pickle_fallback=True)))

# Encryption
from langgraph.checkpoint.serde.encrypted import EncryptedSerializer
serde = EncryptedSerializer.from_pycryptodome_aes()  # reads LANGGRAPH_AES_KEY
checkpointer = SqliteSaver(sqlite3.connect("db.sqlite"), serde=serde)
```
