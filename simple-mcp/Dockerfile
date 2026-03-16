FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

WORKDIR /app

# Copy dependency files
COPY pyproject.toml ./

# Install dependencies using uv
RUN uv pip install --system -r pyproject.toml

# Copy application code
COPY server.py ./

# Expose port (optional, MCP typically uses stdio but useful for HTTP mode)
EXPOSE 8000

# Run the server
CMD ["python", "server.py"]
