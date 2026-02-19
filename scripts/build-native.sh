#!/bin/bash
# Build Zig N-API native modules
# Run from repo root: ./scripts/build-native.sh

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --clean      Clean build artifacts first"
  echo "  -h, --help   Show this help"
  echo ""
  echo "Examples:"
  echo "  $0              # Build Zig modules"
  echo "  $0 --clean      # Clean and rebuild"
}

CLEAN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --clean)
      CLEAN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      usage
      exit 1
      ;;
  esac
done

echo "Building Zig N-API modules..."

# Clean if requested
if [ "$CLEAN" = true ]; then
  echo -e "${YELLOW}Cleaning...${NC}"
  rm -rf "$REPO_ROOT/dist/native"
  rm -f "$REPO_ROOT/native/fs-safe"/*.node "$REPO_ROOT/native/fs-safe/src"/*.so
  rm -f "$REPO_ROOT/native/archive"/*.node "$REPO_ROOT/native/archive/src"/*.so
  rm -f "$REPO_ROOT/native/compression"/*.node "$REPO_ROOT/native/compression/src"/*.so
fi

# fs-safe
echo -e "${GREEN}Building fs-safe...${NC}"
cd "$REPO_ROOT/native/fs-safe/src"
zig build-lib -O ReleaseFast -fPIC -dynamic -lc fs_safe.zig
cd "$REPO_ROOT/native/fs-safe"
g++ -shared -fPIC -O2 \
    -I/usr/include/node \
    -std=c++20 \
    -DNAPI_DISABLE_CPP_EXCEPTIONS \
    napi_wrapper.cc \
    -o fs_safe.node \
    -L./src -lfs_safe \
    -Wl,-rpath,'$ORIGIN'

# archive
echo -e "${GREEN}Building archive...${NC}"
cd "$REPO_ROOT/native/archive/src"
zig build-lib -O ReleaseFast -fPIC -dynamic -lc archive.zig
cd "$REPO_ROOT/native/archive"
g++ -shared -fPIC -O2 \
    -I/usr/include/node \
    -std=c++20 \
    -DNAPI_DISABLE_CPP_EXCEPTIONS \
    napi_wrapper.cc \
    -o archive.node \
    -L./src -larchive \
    -Wl,-rpath,'$ORIGIN'

# compression
echo -e "${GREEN}Building compression...${NC}"
cd "$REPO_ROOT/native/compression/src"
zig build-lib -O ReleaseFast -fPIC -dynamic -lc compression.zig -larchive -lzip
cd "$REPO_ROOT/native/compression"
g++ -shared -fPIC -O2 \
    -I/usr/include/node \
    -std=c++20 \
    -DNAPI_DISABLE_CPP_EXCEPTIONS \
    napi_wrapper.cc \
    -o compression.node \
    -L./src -lcompression -larchive -lzip \
    -Wl,-rpath,'$ORIGIN'

# Copy to dist/
echo -e "${GREEN}Copying to dist/...${NC}"
mkdir -p "$REPO_ROOT/dist/native/fs-safe"
mkdir -p "$REPO_ROOT/dist/native/archive"
mkdir -p "$REPO_ROOT/dist/native/compression"

cp "$REPO_ROOT/native/fs-safe/fs_safe.node" "$REPO_ROOT/dist/native/fs-safe/"
cp "$REPO_ROOT/native/fs-safe/src/libfs_safe.so" "$REPO_ROOT/dist/native/fs-safe/"
cp "$REPO_ROOT/native/archive/archive.node" "$REPO_ROOT/dist/native/archive/"
cp "$REPO_ROOT/native/archive/src/libarchive.so" "$REPO_ROOT/dist/native/archive/"
cp "$REPO_ROOT/native/compression/compression.node" "$REPO_ROOT/dist/native/compression/"
cp "$REPO_ROOT/native/compression/src/libcompression.so" "$REPO_ROOT/dist/native/compression/"

echo ""
echo -e "${GREEN}✅ Done! Zig N-API modules in dist/native/${NC}"
echo ""
echo "Available modules:"
echo "  - fs-safe (Zig N-API)"
echo "  - archive (Zig N-API)"
echo "  - compression (Zig N-API)"

exit 0
