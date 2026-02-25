# MCP Cloud SQL PostgreSQL Setup

## 1) Authenticate with gcloud
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

## 2) Start Cloud SQL Auth Proxy (PostgreSQL)
Use a local TCP port (example `5432`) so the MCP server can connect:

```bash
cloud-sql-proxy YOUR_PROJECT_ID:YOUR_REGION:YOUR_INSTANCE_ID --port 5432
```

Keep this process running while using MCP.

## 3) Configure Codex MCP server
Add this block in `~/.codex/config.toml`:

```toml
[mcp_servers.cloudsql-postgres]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-postgres", "postgresql://DB_USER@127.0.0.1:5432/DB_NAME"]
```

If your DB requires password:

```toml
[mcp_servers.cloudsql-postgres.env]
PGPASSWORD = "YOUR_DB_PASSWORD"
```

## 4) Query workflow
- Discover schema first.
- Run read-only SQL (`SELECT`, `WITH`, `EXPLAIN`).
- Add filters and limits before wide scans.
