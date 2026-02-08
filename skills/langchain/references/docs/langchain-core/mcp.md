# MCP (Model Context Protocol) Integration

> Source: https://docs.langchain.com/oss/python/langchain/mcp.md

## Installation

```bash
pip install langchain-mcp-adapters
```

## MultiServerMCPClient

Primary client for connecting to MCP servers. Operates statelessly by default.

```python
from langchain_mcp_adapters.client import MultiServerMCPClient

client = MultiServerMCPClient({
    "math": {
        "transport": "stdio",
        "command": "python",
        "args": ["/path/to/math_server.py"],
    },
    "weather": {
        "transport": "http",
        "url": "http://localhost:8000/mcp",
    }
})
```

## Transport Types

- **HTTP/Streamable-HTTP**: Request-based with optional auth and custom headers
- **stdio**: Local subprocess communication; inherently stateful

## Using MCP Tools with Agents

```python
tools = await client.get_tools()
agent = create_agent(model, tools=tools)
```

## Stateful Sessions

```python
async with client.session("server_name") as session:
    tools = await load_mcp_tools(session)
```

## Resources & Prompts

```python
# Load resources as Blob objects
resources = await client.get_resources(server_name)

# Get reusable prompt templates
messages = await client.get_prompt(server_name, name, arguments={...})
```

## Tool Interceptors

Middleware-like functions for request/response modification:
- Access runtime context: `request.runtime` (user data, store, state, tool call IDs)
- Modify requests: `request.override(args={...}, headers={...})`
- Compose multiple interceptors (onion order)

## Creating MCP Servers with FastMCP

```bash
pip install fastmcp
```

```python
from fastmcp import FastMCP

mcp = FastMCP("MyServer")

@mcp.tool()
def my_tool(param: str) -> str:
    """Tool description."""
    return f"Result: {param}"

if __name__ == "__main__":
    mcp.run(transport="stdio")
```
