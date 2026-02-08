# LangGraph Interrupts

> Source: https://docs.langchain.com/oss/python/langgraph/interrupts.md

## Basic Usage

### Pausing Execution

```python
from langgraph.types import interrupt

def approval_node(state: State):
    approved = interrupt("Do you approve this action?")
    return {"approved": approved}
```

### Resuming Execution

```python
from langgraph.types import Command

config = {"configurable": {"thread_id": "thread-1"}}
result = graph.invoke({"input": "data"}, config=config)
print(result["__interrupt__"])  # Shows interrupt payload

graph.invoke(Command(resume=True), config=config)  # Resume with value
```

## Requirements

- A **checkpointer** to persist state
- A **thread_id** in config
- JSON-serializable values passed to `interrupt()`

## Common Patterns

### 1. Approval Workflows

```python
def approval_node(state: ApprovalState) -> Command[Literal["proceed", "cancel"]]:
    decision = interrupt({
        "question": "Approve this action?",
        "details": state["action_details"],
    })
    return Command(goto="proceed" if decision else "cancel")
```

### 2. Review and Edit State

```python
def review_node(state: State):
    edited_content = interrupt({
        "instruction": "Review and edit this content",
        "content": state["generated_text"]
    })
    return {"generated_text": edited_content}
```

### 3. Tool Call Approval

```python
@tool
def send_email(to: str, subject: str, body: str):
    response = interrupt({
        "action": "send_email",
        "to": to, "subject": subject, "body": body,
        "message": "Approve sending this email?"
    })
    if response.get("action") == "approve":
        return f"Email sent to {response.get('to', to)}"
    return "Email cancelled by user"
```

### 4. Input Validation

```python
def get_age_node(state: State):
    prompt = "What is your age?"
    while True:
        answer = interrupt(prompt)
        if isinstance(answer, int) and answer > 0:
            break
        prompt = f"'{answer}' is not valid. Enter a positive number."
    return {"age": answer}
```

## Critical Rules

- Do NOT wrap `interrupt()` in bare `try/except`
- Keep interrupt calls in consistent order (matched by index)
- Do NOT conditionally skip interrupt calls
- Only pass JSON-serializable values
- Make side effects before `interrupt()` idempotent (code re-executes on resume)

## Static Interrupts (Debugging)

```python
graph = builder.compile(
    interrupt_before=["node_a"],
    interrupt_after=["node_b"],
    checkpointer=checkpointer,
)

config = {"configurable": {"thread_id": "some_thread"}}
graph.invoke(inputs, config=config)   # Run until breakpoint
graph.invoke(None, config=config)     # Resume to next breakpoint
```
