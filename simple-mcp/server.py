from fastmcp import FastMCP
import sys

# Create an MCP server
mcp = FastMCP("Hello World MCP Server")


@mcp.tool()
def hello(name: str) -> str:
    """Say hello to someone

    Args:
        name: The name of the person to greet
    """
    return f"Hello, {name}! Welcome to FastMCP on AKS!"


@mcp.tool()
def add(a: int, b: int) -> int:
    """Add two numbers together

    Args:
        a: First number
        b: Second number
    """
    return a + b


@mcp.tool()
def health() -> str:
    """Health check endpoint"""
    return "Server is healthy!"


if __name__ == "__main__":
    # Run as HTTP server for Kubernetes
    print("Starting MCP Server on HTTP...", file=sys.stderr)

    # FastMCP supports HTTP transport natively
    # This keeps the server alive and allows proper Kubernetes health checks
    mcp.run(transport="http", host="0.0.0.0", port=8000)
