# LangChain Memory (Short-term & Long-term)

> Sources:
> - https://docs.langchain.com/oss/python/langchain/short-term-memory.md
> - https://docs.langchain.com/oss/python/langchain/long-term-memory.md

## Short-term Memory (Conversation History)

Enable short-term memory with a checkpointer:

```python
from langchain.agents import create_agent
from langgraph.checkpoint.memory import InMemorySaver

agent = create_agent(
    "gpt-5",
    tools=[get_user_info],
    checkpointer=InMemorySaver(),
)

agent.invoke(
    {"messages": [{"role": "user", "content": "Hi! My name is Bob."}]},
    {"configurable": {"thread_id": "1"}},
)
```

### Production (PostgresSaver)

```python
from langgraph.checkpoint.postgres import PostgresSaver

DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresSaver.from_conn_string(DB_URI) as checkpointer:
    checkpointer.setup()
    agent = create_agent("gpt-5", tools=[get_user_info], checkpointer=checkpointer)
```

### Context Management Strategies

1. **Trim Messages**: Remove oldest/newest messages using `@before_model` decorator
2. **Delete Messages**: Permanently remove via `RemoveMessage` with `add_messages` reducer
3. **Summarize Messages**: Use `SummarizationMiddleware` to condense history

### Custom State

```python
from langchain.agents import AgentState

class CustomAgentState(AgentState):
    user_id: str
    preferences: dict

agent = create_agent("gpt-5", tools=[...], state_schema=CustomAgentState, checkpointer=InMemorySaver())
```

---

## Long-term Memory (Persistent Store)

### Basic Store Setup

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore(index={"embed": embed_fn, "dims": 2})

namespace = ("user_123", "chitchat")
store.put(namespace, "a-memory", {
    "rules": ["User likes short, direct language", "User only speaks English & python"],
    "my-key": "my-value",
})

item = store.get(namespace, "a-memory")
items = store.search(namespace, filter={"my-key": "my-value"}, query="language preferences")
```

### Reading Long-term Memory in Tools

```python
from dataclasses import dataclass
from langchain.tools import tool, ToolRuntime
from langgraph.store.memory import InMemoryStore

@dataclass
class Context:
    user_id: str

store = InMemoryStore()
store.put(("users",), "user_123", {"name": "John Smith", "language": "English"})

@tool
def get_user_info(runtime: ToolRuntime[Context]) -> str:
    """Look up user info."""
    store = runtime.store
    user_id = runtime.context.user_id
    user_info = store.get(("users",), user_id)
    return str(user_info.value) if user_info else "Unknown user"

agent = create_agent(
    model="claude-sonnet-4-5-20250929",
    tools=[get_user_info],
    store=store,
    context_schema=Context
)
agent.invoke(
    {"messages": [{"role": "user", "content": "look up user information"}]},
    context=Context(user_id="user_123")
)
```

### Writing Long-term Memory from Tools

```python
@tool
def save_user_info(user_info: UserInfo, runtime: ToolRuntime[Context]) -> str:
    """Save user info."""
    store = runtime.store
    user_id = runtime.context.user_id
    store.put(("users",), user_id, user_info)
    return "Successfully saved user info."
```

### Store API

| Method | Purpose |
|--------|---------|
| `store.put(namespace, key, data)` | Store or update a memory |
| `store.get(namespace, key)` | Retrieve a specific memory |
| `store.search(namespace, filter, query)` | Search with filtering and vector similarity |

> Use a DB-backed store in production, not InMemoryStore.
