# LangChain Documentation URL Index

> Python-only URL index curated from `docs.langchain.com/llms.txt`.
> Used by the `langchain` skill to find relevant documentation for WebFetch.

---

## LangChain Python Core (~25 URLs)

- https://docs.langchain.com/oss/python/langchain/overview.md (framework overview, pre-built agent architecture)
- https://docs.langchain.com/oss/python/langchain/quickstart.md (getting started, first app)
- https://docs.langchain.com/oss/python/langchain/install.md (pip install, dependencies)
- https://docs.langchain.com/oss/python/langchain/agents.md (create_agent, agent architecture, ReAct)
- https://docs.langchain.com/oss/python/langchain/tools.md (tool integration, @tool decorator)
- https://docs.langchain.com/oss/python/langchain/models.md (model selection, init_chat_model)
- https://docs.langchain.com/oss/python/langchain/rag.md (RAG agents, retrieval-augmented generation)
- https://docs.langchain.com/oss/python/langchain/structured-output.md (structured output, Pydantic models)
- https://docs.langchain.com/oss/python/langchain/streaming/overview.md (streaming overview, astream_events)
- https://docs.langchain.com/oss/python/langchain/streaming/frontend.md (generative UI, frontend streaming)
- https://docs.langchain.com/oss/python/langchain/short-term-memory.md (session memory, conversation history)
- https://docs.langchain.com/oss/python/langchain/long-term-memory.md (persistent memory, cross-session)
- https://docs.langchain.com/oss/python/langchain/retrieval.md (retrieval patterns, semantic search)
- https://docs.langchain.com/oss/python/langchain/knowledge-base.md (knowledge base, semantic search engine)
- https://docs.langchain.com/oss/python/langchain/multi-agent/index.md (multi-agent orchestration)
- https://docs.langchain.com/oss/python/langchain/multi-agent/handoffs.md (agent handoffs)
- https://docs.langchain.com/oss/python/langchain/multi-agent/router.md (request routing)
- https://docs.langchain.com/oss/python/langchain/multi-agent/subagents.md (subagent delegation)
- https://docs.langchain.com/oss/python/langchain/middleware/overview.md (middleware, execution control)
- https://docs.langchain.com/oss/python/langchain/middleware/built-in.md (built-in middleware)
- https://docs.langchain.com/oss/python/langchain/middleware/custom.md (custom middleware)
- https://docs.langchain.com/oss/python/langchain/human-in-the-loop.md (human oversight, approval)
- https://docs.langchain.com/oss/python/langchain/guardrails.md (safety checks, content filtering)
- https://docs.langchain.com/oss/python/langchain/mcp.md (MCP, Model Context Protocol)
- https://docs.langchain.com/oss/python/langchain/messages.md (message format, BaseMessage)
- https://docs.langchain.com/oss/python/langchain/sql-agent.md (SQL agent, database queries)
- https://docs.langchain.com/oss/python/langchain/context-engineering.md (context optimization)

## LangGraph Python (~15 URLs)

- https://docs.langchain.com/oss/python/langgraph/overview.md (LangGraph overview, graph-based agents)
- https://docs.langchain.com/oss/python/langgraph/quickstart.md (getting started with LangGraph)
- https://docs.langchain.com/oss/python/langgraph/install.md (pip install langgraph)
- https://docs.langchain.com/oss/python/langgraph/thinking-in-langgraph.md (design principles, mental model)
- https://docs.langchain.com/oss/python/langgraph/choosing-apis.md (Graph API vs Functional API)
- https://docs.langchain.com/oss/python/langgraph/graph-api.md (Graph API, StateGraph, nodes, edges)
- https://docs.langchain.com/oss/python/langgraph/functional-api.md (Functional API, @entrypoint, @task)
- https://docs.langchain.com/oss/python/langgraph/use-graph-api.md (Graph API implementation guide)
- https://docs.langchain.com/oss/python/langgraph/use-functional-api.md (Functional API implementation)
- https://docs.langchain.com/oss/python/langgraph/persistence.md (state persistence, checkpointing)
- https://docs.langchain.com/oss/python/langgraph/durable-execution.md (fault-tolerant execution)
- https://docs.langchain.com/oss/python/langgraph/interrupts.md (interrupt, resume, human-in-the-loop)
- https://docs.langchain.com/oss/python/langgraph/add-memory.md (memory integration in graphs)
- https://docs.langchain.com/oss/python/langgraph/streaming.md (stream output, streaming modes)
- https://docs.langchain.com/oss/python/langgraph/workflows-agents.md (workflow vs agent patterns)
- https://docs.langchain.com/oss/python/langgraph/use-subgraphs.md (subgraph composition)
- https://docs.langchain.com/oss/python/langgraph/agentic-rag.md (RAG agent with LangGraph)
- https://docs.langchain.com/oss/python/langgraph/sql-agent.md (SQL agent with LangGraph)

## LangSmith (~30 URLs)

### Observability & Tracing
- https://docs.langchain.com/langsmith/observability.md (observability framework overview)
- https://docs.langchain.com/langsmith/observability-quickstart.md (tracing quickstart)
- https://docs.langchain.com/langsmith/log-llm-trace.md (LLM call tracing)
- https://docs.langchain.com/langsmith/trace-with-langchain.md (LangChain tracing integration)
- https://docs.langchain.com/langsmith/trace-with-langgraph.md (LangGraph tracing integration)
- https://docs.langchain.com/langsmith/trace-anthropic.md (Anthropic Claude tracing)
- https://docs.langchain.com/langsmith/trace-openai.md (OpenAI tracing)
- https://docs.langchain.com/langsmith/add-metadata-tags.md (trace metadata, tags)
- https://docs.langchain.com/langsmith/annotate-code.md (custom instrumentation, @traceable)

### Evaluation
- https://docs.langchain.com/langsmith/evaluation.md (evaluation framework overview)
- https://docs.langchain.com/langsmith/evaluation-quickstart.md (evaluation quickstart)
- https://docs.langchain.com/langsmith/evaluation-concepts.md (evaluation design concepts)
- https://docs.langchain.com/langsmith/evaluate-llm-application.md (evaluate LLM application)
- https://docs.langchain.com/langsmith/evaluate-rag-tutorial.md (RAG evaluation tutorial)
- https://docs.langchain.com/langsmith/evaluate-complex-agent.md (complex agent evaluation)
- https://docs.langchain.com/langsmith/llm-as-judge.md (LLM-as-judge evaluator)
- https://docs.langchain.com/langsmith/prebuilt-evaluators.md (pre-built evaluators)
- https://docs.langchain.com/langsmith/code-evaluator-sdk.md (code-based evaluators)
- https://docs.langchain.com/langsmith/pytest.md (pytest evaluation integration)

### Datasets & Experiments
- https://docs.langchain.com/langsmith/manage-datasets.md (dataset management)
- https://docs.langchain.com/langsmith/manage-datasets-programmatically.md (programmatic datasets)
- https://docs.langchain.com/langsmith/experiment-configuration.md (experiment setup)
- https://docs.langchain.com/langsmith/compare-experiment-results.md (experiment comparison)

### Prompts
- https://docs.langchain.com/langsmith/create-a-prompt.md (prompt creation)
- https://docs.langchain.com/langsmith/manage-prompts-programmatically.md (programmatic prompt management)
- https://docs.langchain.com/langsmith/prompt-engineering.md (prompt engineering best practices)

### Deployment
- https://docs.langchain.com/langsmith/deployments.md (deployment overview)
- https://docs.langchain.com/langsmith/deployment-quickstart.md (deploy to cloud quickstart)
- https://docs.langchain.com/langsmith/deploy-to-cloud.md (cloud deployment guide)
- https://docs.langchain.com/langsmith/local-server.md (run LangGraph app locally)
- https://docs.langchain.com/langsmith/studio.md (LangSmith Studio)

## Python Integrations (~15 URLs)

### Chat Model Providers
- https://docs.langchain.com/oss/python/integrations/providers/anthropic.md (Anthropic Claude, ChatAnthropic)
- https://docs.langchain.com/oss/python/integrations/providers/openai.md (OpenAI, ChatOpenAI)
- https://docs.langchain.com/oss/python/integrations/providers/google.md (Google Gemini, ChatGoogleGenerativeAI)
- https://docs.langchain.com/oss/python/integrations/providers/aws.md (AWS Bedrock, ChatBedrock)
- https://docs.langchain.com/oss/python/integrations/providers/microsoft.md (Azure OpenAI, ChatAzureOpenAI)
- https://docs.langchain.com/oss/python/integrations/providers/groq.md (Groq API, ChatGroq)
- https://docs.langchain.com/oss/python/integrations/providers/ollama.md (Ollama local models, ChatOllama)
- https://docs.langchain.com/oss/python/integrations/providers/huggingface.md (HuggingFace models)
- https://docs.langchain.com/oss/python/integrations/providers/overview.md (all providers overview)

### Retrieval & Storage
- https://docs.langchain.com/oss/python/integrations/vectorstores/index.md (vector stores: FAISS, Chroma, Pinecone)
- https://docs.langchain.com/oss/python/integrations/text_embedding/index.md (embedding models)
- https://docs.langchain.com/oss/python/integrations/retrievers/index.md (retrievers)
- https://docs.langchain.com/oss/python/integrations/document_loaders/index.md (document loaders)
- https://docs.langchain.com/oss/python/integrations/splitters/index.md (text splitters)
- https://docs.langchain.com/oss/python/integrations/tools/index.md (tool integrations)

## Deep Agents Python (~5 URLs)

- https://docs.langchain.com/oss/python/deepagents/overview.md (deep agents overview, planning, subagents)
- https://docs.langchain.com/oss/python/deepagents/quickstart.md (deep agents quickstart)
- https://docs.langchain.com/oss/python/deepagents/customization.md (agent customization)
- https://docs.langchain.com/oss/python/deepagents/skills.md (skill extension)
- https://docs.langchain.com/oss/python/deepagents/subagents.md (subagent delegation)

## Migration & Changelog (~5 URLs)

- https://docs.langchain.com/oss/python/migrate/langchain-v1.md (LangChain v1 migration guide)
- https://docs.langchain.com/oss/python/migrate/langgraph-v1.md (LangGraph v1 migration guide)
- https://docs.langchain.com/oss/python/releases/changelog.md (Python packages changelog)
- https://docs.langchain.com/oss/python/langchain/changelog-py.md (LangChain changelog)
- https://docs.langchain.com/oss/python/langgraph/changelog-py.md (LangGraph changelog)

## SDK References (~5 URLs)

- https://docs.langchain.com/oss/python/reference/langchain-python.md (LangChain Python SDK reference)
- https://docs.langchain.com/oss/python/reference/langgraph-python.md (LangGraph Python SDK reference)
- https://docs.langchain.com/oss/python/reference/deepagents-python.md (Deep Agents SDK reference)
- https://docs.langchain.com/oss/python/reference/integrations-python.md (Integrations SDK reference)
- https://docs.langchain.com/oss/python/concepts/products.md (LangChain vs LangGraph vs Deep Agents)
