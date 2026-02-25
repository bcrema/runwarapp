---
name: gcloud-db-access
description: Use when the user needs to retrieve data from Cloud SQL PostgreSQL through MCP. Supports read-only access via @modelcontextprotocol/server-postgres connected to Cloud SQL using the Auth Proxy.
---

## Goal
Retrieve data from Cloud SQL PostgreSQL using MCP only.

## Inputs to collect (ask only if missing)
- `project_id`
- `instance_id`
- `database_name`
- `db_user`
- `local_proxy_port` (default `5432`)

## Execution workflow
1. Authenticate in gcloud:
   `gcloud auth login`
2. Start Cloud SQL Auth Proxy:
   `gcloud beta sql connect <instance_id> --project=<project_id> --user=<db_user> --database=<database_name>`
   or run Cloud SQL Auth Proxy bound to localhost (`127.0.0.1:<local_proxy_port>`).
3. Configure MCP server in `~/.codex/config.toml` with:
   `command = "npx"` and args `["-y", "@modelcontextprotocol/server-postgres", "postgresql://<db_user>@127.0.0.1:<local_proxy_port>/<database_name>"]`
4. Use MCP tools/resources for schema discovery and read-only SQL queries.

## Guardrails
- Pass `--project` in every command.
- Use read-only SQL (`SELECT`, `WITH`, `EXPLAIN`) only.
- Start with schema discovery and constrained queries (`LIMIT`, date filters).
- If auth or permissions fail, fix environment before retrying.

## References
- MCP setup and usage: `references/mcp-cloudsql-postgres.md`
