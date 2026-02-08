# Multi-Agent Systems

> Source: https://docs.langchain.com/oss/python/langchain/multi-agent/index.md

## When to Use

Not every complex task requires multi-agent — a single agent with the right tools and prompt can often achieve similar results.

## Three Core Motivations

1. **Context Management**: Selectively surface relevant information
2. **Distributed Development**: Teams independently develop capabilities
3. **Parallelization**: Execute specialized subtasks concurrently

## Five Main Patterns

| Pattern | Primary Mechanism |
|---------|------------------|
| **Subagents** | Main agent coordinates subagents as tools; routing flows through primary agent |
| **Handoffs** | State-driven dynamic behavior; tool calls trigger routing or configuration changes |
| **Skills** | Single agent loads specialized prompts and knowledge on-demand |
| **Router** | Initial classification directs input to specialized agents; results synthesized |
| **Custom Workflow** | Bespoke execution using LangGraph; mixes deterministic logic with agentic behavior |

## Performance Comparison

**One-shot request** ("Buy coffee"):
- Subagents: 4 calls
- Handoffs/Skills/Router: 3 calls each

**Repeat requests** (stateful advantage):
- Handoffs/Skills: 2 calls on second turn (5 total)
- Subagents: 4 calls again (8 total) — stateless
- Router: 3 calls again (6 total)

**Multi-domain** (parallel execution):
- Subagents/Router: 5 calls, ~9K tokens
- Skills: 3 calls, ~15K tokens
- Handoffs: 7+ calls, ~14K+ tokens

## Selection Guide

- **Subagents**: parallel execution, large-context domains
- **Handoffs/Skills**: single or repeat requests
- **Router**: parallel execution with simple classification
- **Skills**: simple, focused tasks with direct user interaction

Patterns can be mixed! Subagents can invoke custom workflows; subagents can employ skills for on-demand context loading.
