#!/bin/bash
# Build native modules and copy to dist/
# Run from repo root: ./scripts/build-native.sh

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Building native modules..."

# Build fs-safe
echo "Building fs-safe..."
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

# Build archive
echo "Building archive..."
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

# Copy to dist/
echo "Copying to dist/..."
mkdir -p "$REPO_ROOT/dist/native/fs-safe"
mkdir -p "$REPO_ROOT/dist/native/archive"

cp "$REPO_ROOT/native/fs-safe/fs_safe.node" "$REPO_ROOT/dist/native/fs-safe/"
cp "$REPO_ROOT/native/fs-safe/src/libfs_safe.so" "$REPO_ROOT/dist/native/fs-safe/"
cp "$REPO_ROOT/native/archive/archive.node" "$REPO_ROOT/dist/native/archive/"
cp "$REPO_ROOT/native/archive/src/libarchive.so" "$REPO_ROOT/dist/native/archive/"

echo "✅ Done! Native modules in dist/native/"
