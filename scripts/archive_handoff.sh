#!/usr/bin/env bash
set -euo pipefail

DOCS_DIR="${1:?Usage: $0 /path/to/agent-docs}"

if [[ ! -d "$DOCS_DIR" ]]; then
  echo "ERROR: agent-docs directory does not exist: $DOCS_DIR" >&2
  echo "Run scenario A initialization first." >&2
  exit 1
fi

HANDOFF="$DOCS_DIR/AGENT_HANDOFF.md"
ARCHIVE_DIR="$DOCS_DIR/handoff_archive"

if [[ ! -f "$HANDOFF" ]]; then
  echo "No AGENT_HANDOFF.md to archive — skipping."
  exit 0
fi

mkdir -p "$ARCHIVE_DIR"
TIMESTAMP=$(date +%Y-%m-%d_%H%M)
mv "$HANDOFF" "$ARCHIVE_DIR/AGENT_HANDOFF_${TIMESTAMP}.md"
echo "Archived to $ARCHIVE_DIR/AGENT_HANDOFF_${TIMESTAMP}.md"
