#!/bin/bash
# Build native modules and copy to dist/
# Run from repo root: ./scripts/build-native.sh

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --zig        Build Zig modules (fs-safe, archive, compression)"
  echo "  --go         Build Go modules (shell-env, exec-approvals)"
  echo "  --all        Build all modules (default)"
  echo "  --clean      Clean build artifacts first"
  echo "  -h, --help   Show this help"
  echo ""
  echo "Examples:"
  echo "  $0              # Build all"
  echo "  $0 --zig        # Build only Zig"
  echo "  $0 --go --clean # Clean and rebuild Go"
}

BUILD_ZIG=true
BUILD_GO=true
CLEAN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --zig)
      BUILD_GO=false
      shift
      ;;
    --go)
      BUILD_ZIG=false
      shift
      ;;
    --all)
      BUILD_ZIG=true
      BUILD_GO=true
      shift
      ;;
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

echo "Building native modules..."
echo "  Zig: $BUILD_ZIG"
echo "  Go:  $BUILD_GO"
echo ""

# Clean if requested
if [ "$CLEAN" = true ]; then
  echo -e "${YELLOW}Cleaning...${NC}"
  rm -rf "$REPO_ROOT/dist/native"
  rm -f "$REPO_ROOT/native/fs-safe"/*.node "$REPO_ROOT/native/fs-safe/src"/*.so
  rm -f "$REPO_ROOT/native/archive"/*.node "$REPO_ROOT/native/archive/src"/*.so
  rm -f "$REPO_ROOT/native/compression"/*.node "$REPO_ROOT/native/compression/src"/*.so
  rm -f "$REPO_ROOT/native/shell-env/shell-env"
  rm -f "$REPO_ROOT/native/exec-approvals/exec-approvals"
fi

# Build Zig modules
if [ "$BUILD_ZIG" = true ]; then
  echo -e "${GREEN}Building Zig modules...${NC}"

  # fs-safe
  echo "  Building fs-safe..."
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
  echo "  Building archive..."
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
  echo "  Building compression..."
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
fi

# Build Go modules
if [ "$BUILD_GO" = true ]; then
  echo -e "${GREEN}Building Go modules...${NC}"

  echo "  Building shell-env..."
  cd "$REPO_ROOT/native/shell-env"
  go build -o shell-env main.go

  echo "  Building exec-approvals..."
  cd "$REPO_ROOT/native/exec-approvals"
  go build -o exec-approvals main.go
fi

# Copy to dist/
echo -e "${GREEN}Copying to dist/...${NC}"
mkdir -p "$REPO_ROOT/dist/native/fs-safe"
mkdir -p "$REPO_ROOT/dist/native/archive"
mkdir -p "$REPO_ROOT/dist/native/compression"
mkdir -p "$REPO_ROOT/dist/native/shell-env"
mkdir -p "$REPO_ROOT/dist/native/exec-approvals"

[ "$BUILD_ZIG" = true ] && cp "$REPO_ROOT/native/fs-safe/fs_safe.node" "$REPO_ROOT/dist/native/fs-safe/"
[ "$BUILD_ZIG" = true ] && cp "$REPO_ROOT/native/fs-safe/src/libfs_safe.so" "$REPO_ROOT/dist/native/fs-safe/"
[ "$BUILD_ZIG" = true ] && cp "$REPO_ROOT/native/archive/archive.node" "$REPO_ROOT/dist/native/archive/"
[ "$BUILD_ZIG" = true ] && cp "$REPO_ROOT/native/archive/src/libarchive.so" "$REPO_ROOT/dist/native/archive/"
[ "$BUILD_ZIG" = true ] && cp "$REPO_ROOT/native/compression/compression.node" "$REPO_ROOT/dist/native/compression/"
[ "$BUILD_ZIG" = true ] && cp "$REPO_ROOT/native/compression/src/libcompression.so" "$REPO_ROOT/dist/native/compression/"

[ "$BUILD_GO" = true ] && cp "$REPO_ROOT/native/shell-env/shell-env" "$REPO_ROOT/dist/native/shell-env/"
[ "$BUILD_GO" = true ] && cp "$REPO_ROOT/native/exec-approvals/exec-approvals" "$REPO_ROOT/dist/native/exec-approvals/"

echo ""
echo -e "${GREEN}✅ Done! Native modules in dist/native/${NC}"
echo ""
echo "Available modules:"
[ "$BUILD_ZIG" = true ] && echo "  - fs-safe (Zig)"
[ "$BUILD_ZIG" = true ] && echo "  - archive (Zig)"
[ "$BUILD_ZIG" = true ] && echo "  - compression (Zig)"
[ "$BUILD_GO" = true ] && echo "  - shell-env (Go)"
[ "$BUILD_GO" = true ] && echo "  - exec-approvals (Go)"

exit 0
