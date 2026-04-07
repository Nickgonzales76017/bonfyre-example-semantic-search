#!/bin/sh
# run.sh — Index sample documents and run interactive search
#
# Usage:
#   ./run.sh                    # index + interactive search (hash backend)
#   ./run.sh --backend onnx     # use ONNX neural embeddings
#   ./run.sh --reindex          # re-embed all documents
#   ./run.sh --query "text"     # single query, non-interactive
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BONFYRE="$SCRIPT_DIR/bonfyre/cmd"
EMBED="$BONFYRE/BonfyreEmbed/bonfyre-embed"
VEC="$BONFYRE/BonfyreVec/bonfyre-vec"
SAMPLE="$SCRIPT_DIR/sample-data"
OUTPUT="$SCRIPT_DIR/output"
DB="$OUTPUT/vectors.db"

BACKEND="hash"
REINDEX=0
SINGLE_QUERY=""

# Parse args
while [ $# -gt 0 ]; do
    case "$1" in
        --backend) BACKEND="$2"; shift 2 ;;
        --reindex) REINDEX=1; shift ;;
        --query)   SINGLE_QUERY="$2"; shift 2 ;;
        *)         echo "Unknown arg: $1"; exit 1 ;;
    esac
done

# Verify binaries exist
if [ ! -x "$EMBED" ] || [ ! -x "$VEC" ]; then
    echo "Error: Binaries not found. Run ./setup.sh first."
    exit 1
fi

mkdir -p "$OUTPUT"

echo "╔══════════════════════════════════════════════════════╗"
echo "║      Bonfyre Semantic Search — 20 Document Demo     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Backend: $BACKEND"
echo ""

# ── Index documents ───────────────────────────────────────────
if [ ! -f "$DB" ] || [ "$REINDEX" = "1" ]; then
    rm -f "$DB"

    echo "━━━ Indexing documents ━━━"
    echo ""

    # Init the vector database
    "$VEC" init "$DB" 2>/dev/null

    # Batch mode: embed all docs at once and insert into DB
    START_TS=$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || echo 0)

    "$EMBED" --input-dir "$SAMPLE" \
             --insert-db "$DB" \
             --backend "$BACKEND" 2>/dev/null && BATCH_OK=1 || BATCH_OK=0

    END_TS=$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || echo 0)

    if [ "$BATCH_OK" = "1" ]; then
        COUNT=$(ls "$SAMPLE"/*.txt 2>/dev/null | wc -l | tr -d ' ')
        if [ "$START_TS" != "0" ] && [ "$END_TS" != "0" ]; then
            ELAPSED=$((END_TS - START_TS))
            echo "  ✓ Indexed $COUNT documents in ${ELAPSED} ms (batch mode)"
        else
            echo "  ✓ Indexed $COUNT documents (batch mode)"
        fi
    else
        # Fallback: embed one at a time
        echo "  (batch mode not available, embedding one at a time)"
        COUNT=0
        for f in "$SAMPLE"/*.txt; do
            [ -f "$f" ] || continue
            NAME=$(basename "$f" .txt)
            COUNT=$((COUNT + 1))
            printf "  [%2d] %-40s" "$COUNT" "$NAME"

            "$EMBED" --text "$f" \
                     --out "$OUTPUT/${NAME}.vecf" \
                     --output-format binary \
                     --backend "$BACKEND" 2>/dev/null

            "$VEC" insert "$DB" "$OUTPUT/${NAME}.vecf" \
                   --doc-id "$NAME" 2>/dev/null

            echo "✓"
        done
    fi

    # Show DB size
    if [ -f "$DB" ]; then
        DB_SIZE=$(ls -lh "$DB" | awk '{print $5}')
        echo "  Database: $DB ($DB_SIZE)"
    fi

    echo ""
else
    echo "  Using existing index at $DB (use --reindex to rebuild)"
    echo ""
fi

# ── Search ────────────────────────────────────────────────────
do_search() {
    QUERY_TEXT="$1"
    QUERY_FILE="$OUTPUT/_query.txt"

    # Write query to temp file
    printf '%s' "$QUERY_TEXT" > "$QUERY_FILE"

    # Embed the query
    "$EMBED" --text "$QUERY_FILE" \
             --out "$OUTPUT/_query.vecf" \
             --output-format binary \
             --backend "$BACKEND" 2>/dev/null

    # Search
    echo ""
    "$VEC" search "$DB" "$OUTPUT/_query.vecf" --top 5 --exact 2>/dev/null || \
    "$VEC" search "$DB" "$OUTPUT/_query.vecf" --top 5 2>/dev/null || \
        echo "  (no results)"
    echo ""

    # Clean up
    rm -f "$QUERY_FILE" "$OUTPUT/_query.vecf"
}

if [ -n "$SINGLE_QUERY" ]; then
    echo "━━━ Search ━━━"
    echo "  Query: \"$SINGLE_QUERY\""
    do_search "$SINGLE_QUERY"
    exit 0
fi

# Interactive search loop
echo "━━━ Interactive Search ━━━"
echo "  Type a question and press Enter. Type 'quit' to exit."
echo ""

while true; do
    printf "  🔍 Query: "
    read -r QUERY
    [ -z "$QUERY" ] && continue
    [ "$QUERY" = "quit" ] || [ "$QUERY" = "exit" ] && break
    do_search "$QUERY"
done

echo ""
echo "Done. Your vector database is at: $DB"
