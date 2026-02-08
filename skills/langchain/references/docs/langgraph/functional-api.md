# LangGraph Functional API

> Source: https://docs.langchain.com/oss/python/langgraph/functional-api.md

## Core Building Blocks

- **`@entrypoint`**: Marks workflow entry points, manages execution
- **`@task`**: Discrete work units, returns future-like objects

## Entrypoint Definition

```python
from langgraph.func import entrypoint
from langgraph.checkpoint.memory import InMemorySaver

@entrypoint(checkpointer=InMemorySaver())
def my_workflow(some_input: dict) -> int:
    # workflow logic
    return result
```

### Async Variant

```python
@entrypoint(checkpointer=checkpointer)
async def my_workflow(some_input: dict) -> int:
    return result
```

## Injectable Parameters

| Parameter | Purpose |
|-----------|---------|
| `previous` | Previous checkpoint state (short-term memory) |
| `store` | BaseStore instance (long-term memory) |
| `writer` | StreamWriter for streaming |
| `config` | RunnableConfig for runtime config |

```python
@entrypoint(checkpointer=checkpointer, store=store)
def my_workflow(
    some_input: dict,
    *,
    previous: Any = None,
    store: BaseStore,
    config: RunnableConfig
) -> dict:
    return {}
```

## Execution Methods

```python
config = {"configurable": {"thread_id": "some_thread_id"}}

my_workflow.invoke(some_input, config)
await my_workflow.ainvoke(some_input, config)

for chunk in my_workflow.stream(some_input, config):
    print(chunk)

async for chunk in my_workflow.astream(some_input, config):
    print(chunk)
```

## Tasks

```python
from langgraph.func import task

@task()
def slow_computation(input_value):
    return result

# Sync usage
@entrypoint(checkpointer=checkpointer)
def my_workflow(some_input: int) -> int:
    future = slow_computation(some_input)
    return future.result()

# Async usage
@entrypoint(checkpointer=checkpointer)
async def my_workflow(some_input: int) -> int:
    return await slow_computation(some_input)
```

## Short-Term Memory (previous)

```python
@entrypoint(checkpointer=checkpointer)
def my_workflow(number: int, *, previous: Any = None) -> int:
    previous = previous or 0
    return number + previous

config = {"configurable": {"thread_id": "1"}}
my_workflow.invoke(1, config)  # Returns 1
my_workflow.invoke(2, config)  # Returns 3 (2 + 1)
```

## entrypoint.final (Decouple Return and Saved Values)

```python
@entrypoint(checkpointer=checkpointer)
def my_workflow(number: int, *, previous: Any = None) -> entrypoint.final[int, int]:
    previous = previous or 0
    return entrypoint.final(value=previous, save=2 * number)

config = {"configurable": {"thread_id": "1"}}
my_workflow.invoke(3, config)  # Returns 0, saves 6
my_workflow.invoke(1, config)  # Returns 6, saves 2
```

## Resuming After Interrupts

```python
from langgraph.types import Command

my_workflow.invoke(Command(resume=resume_value), config)
my_workflow.invoke(None, config)  # Resume after error
```

## Complete Example: Essay Review

```python
from langgraph.func import entrypoint, task
from langgraph.types import interrupt, Command
from langgraph.checkpoint.memory import InMemorySaver

@task
def write_essay(topic: str) -> str:
    return f"An essay about topic: {topic}"

@entrypoint(checkpointer=InMemorySaver())
def workflow(topic: str) -> dict:
    essay = write_essay("cat").result()
    is_approved = interrupt({
        "essay": essay,
        "action": "Please approve/reject the essay",
    })
    return {"essay": essay, "is_approved": is_approved}

# Execute
config = {"configurable": {"thread_id": str(uuid.uuid4())}}
for item in workflow.stream("cat", config):
    print(item)

# Resume with human review
for item in workflow.stream(Command(resume=True), config):
    print(item)
```

## Best Practices

- Encapsulate side effects in `@task` functions
- Encapsulate non-deterministic operations (time, random) in `@task`
- Inputs/outputs must be JSON-serializable
- Code before `interrupt()` re-executes on resume — make it idempotent
