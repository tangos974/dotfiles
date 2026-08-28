#!/usr/bin/env python3
"""Minimal, zero-dependency MCP stdio server exposing one tool: websearch.

Backed by the homelab SearXNG (CT 211 @ 192.168.20.31, pve2) JSON API — the same
backend Open WebUI uses. Stdlib only (no third-party package, no supply chain);
talks ONLY to our own SearXNG. Configured in ~/.config/opencode/opencode.json
under `mcp` because OpenCode 1.15.7's plugin `tool` hook is not bridged to the
model (gh issue #31354); MCP tools are. Override the endpoint with SEARXNG_URL.

Protocol: JSON-RPC 2.0, newline-delimited messages over stdin/stdout (MCP stdio
transport). Implements initialize / tools/list / tools/call.
"""
import json
import os
import sys
import threading
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor

SEARXNG_URL = os.environ.get("SEARXNG_URL", "http://192.168.20.31:8888")
# Max searches running at once. The model fans out tool calls in batches; each
# tools/call is handled on a worker thread so they run concurrently instead of
# queueing. Bounded so we don't hammer SearXNG's rate limiter. Override via env.
MAX_CONCURRENCY = int(os.environ.get("SEARXNG_MAX_CONCURRENCY", "8"))

TOOL = {
    "name": "websearch",
    "description": (
        "Search the web via the homelab SearXNG metasearch engine. Returns ranked "
        "results (title, URL, snippet) plus any direct answers/infoboxes. Use this "
        "for current information, documentation, or finding sources online — do NOT "
        "guess URLs and fetch them blindly."
    ),
    "inputSchema": {
        "type": "object",
        "properties": {
            "query": {"type": "string", "description": "The search query"},
            "count": {
                "type": "integer",
                "minimum": 1,
                "maximum": 20,
                "description": "Max results to return (default 8)",
            },
        },
        "required": ["query"],
    },
}


def do_search(query, count=8):
    qs = urllib.parse.urlencode({"q": query, "format": "json"})
    url = f"{SEARXNG_URL}/search?{qs}"
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=20) as resp:
        data = json.loads(resp.read().decode("utf-8"))

    blocks = []
    for a in data.get("answers") or []:
        txt = a if isinstance(a, str) else a.get("answer")
        if txt:
            blocks.append(f"ANSWER: {txt}")
    for ib in data.get("infoboxes") or []:
        if ib.get("content"):
            blocks.append(f"INFOBOX ({ib.get('infobox', '')}): {ib['content']}".strip())
    results = (data.get("results") or [])[:count]
    for i, r in enumerate(results, 1):
        blocks.append(f"{i}. {r.get('title')}\n   {r.get('url')}\n   {(r.get('content') or '').strip()}")

    if not blocks:
        return f'No results for "{query}".'
    return "\n\n".join(blocks)


# Worker threads write responses concurrently; one JSON message per line must
# never interleave, so serialize all stdout writes.
_stdout_lock = threading.Lock()


def send(msg):
    line = json.dumps(msg) + "\n"
    with _stdout_lock:
        sys.stdout.write(line)
        sys.stdout.flush()


def reply(req_id, result):
    send({"jsonrpc": "2.0", "id": req_id, "result": result})


def error(req_id, code, message):
    send({"jsonrpc": "2.0", "id": req_id, "error": {"code": code, "message": message}})


def handle(req):
    method = req.get("method")
    req_id = req.get("id")
    if method == "initialize":
        proto = (req.get("params") or {}).get("protocolVersion") or "2024-11-05"
        reply(req_id, {
            "protocolVersion": proto,
            "capabilities": {"tools": {}},
            "serverInfo": {"name": "searxng-websearch", "version": "1.0.0"},
        })
    elif method in ("notifications/initialized", "initialized"):
        pass  # notification, no response
    elif method == "tools/list":
        reply(req_id, {"tools": [TOOL]})
    elif method == "tools/call":
        params = req.get("params") or {}
        if params.get("name") != "websearch":
            error(req_id, -32602, f"Unknown tool: {params.get('name')}")
            return
        args = params.get("arguments") or {}
        try:
            text = do_search(args["query"], int(args.get("count", 8)))
            reply(req_id, {"content": [{"type": "text", "text": text}]})
        except Exception as e:  # surface as a tool error, don't crash the server
            reply(req_id, {"content": [{"type": "text", "text": f"search failed: {e}"}], "isError": True})
    elif req_id is not None:
        error(req_id, -32601, f"Method not found: {method}")


def main():
    # tools/call runs on workers so a batch of searches executes in parallel;
    # the fast handshake/list methods stay inline to keep startup ordering simple.
    with ThreadPoolExecutor(max_workers=MAX_CONCURRENCY) as pool:
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            try:
                req = json.loads(line)
            except json.JSONDecodeError:
                continue
            if req.get("method") == "tools/call":
                pool.submit(handle, req)
            else:
                handle(req)
        # stdin closed: ThreadPoolExecutor context exit waits for in-flight searches.


if __name__ == "__main__":
    main()
