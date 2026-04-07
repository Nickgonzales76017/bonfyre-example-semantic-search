#!/bin/sh
# search.sh — One-shot search: ./search.sh "your query here"
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$1" ]; then
    echo "Usage: ./search.sh \"your natural language query\""
    echo ""
    echo "Example:"
    echo "  ./search.sh \"How do containers differ from VMs?\""
    echo "  ./search.sh \"What is gradient descent?\""
    echo "  ./search.sh \"How does DNS resolution work?\""
    exit 1
fi

exec "$SCRIPT_DIR/run.sh" --query "$1"
