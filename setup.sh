#!/bin/sh
# setup.sh — Clone Bonfyre and build only the embedding + search binaries
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BONFYRE_DIR="$SCRIPT_DIR/bonfyre"

if [ -d "$BONFYRE_DIR" ] && [ -f "$BONFYRE_DIR/Makefile" ]; then
    echo "Bonfyre already cloned at $BONFYRE_DIR"
else
    echo "Cloning Bonfyre..."
    git clone https://github.com/Nickgonzales76017/bonfyre.git "$BONFYRE_DIR"
fi

echo ""
echo "Building libraries + embedding/search binaries..."

cd "$BONFYRE_DIR"

# Build libraries first
make lib

# Build only the two binaries we need
echo "  Building BonfyreEmbed..."
make -C cmd/BonfyreEmbed CC="${CC:-cc}" CFLAGS="${CFLAGS:--O3 -march=native -flto=auto -Wall -Wextra -std=c11}"
echo "  Building BonfyreVec..."
make -C cmd/BonfyreVec CC="${CC:-cc}" CFLAGS="${CFLAGS:--O3 -march=native -flto=auto -Wall -Wextra -std=c11}"

echo ""

# Verify
for bin in cmd/BonfyreEmbed/bonfyre-embed cmd/BonfyreVec/bonfyre-vec; do
    if [ -x "$bin" ]; then
        SIZE=$(ls -lh "$bin" | awk '{print $5}')
        echo "  ✓ $(basename "$bin")  ($SIZE)"
    else
        echo "  ✗ $(basename "$bin")  (build failed)"
    fi
done

echo ""
echo "Setup complete. Run ./run.sh to index documents and search."
