#!/usr/bin/env bash
# Build ik_llama.cpp llama-server/cli/quantize/bench tuned for the host CPU.
# Usage:
#   ./build-native.sh
#   BUILD=/tmp/foo JOBS=8 ./build-native.sh

set -euo pipefail

SRC="${SRC:-$(cd "$(dirname "$0")" && pwd)}"
BUILD="${BUILD:-$SRC/build-native}"
JOBS="${JOBS:-$(nproc)}"

# Debian/Ubuntu dep check (skipped on other distros)
if command -v dpkg >/dev/null 2>&1; then
    missing=()
    for pkg in build-essential cmake ninja-build pkg-config libssl-dev libcurl4-openssl-dev; do
        dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing packages: ${missing[*]}"
        echo "Run: sudo apt-get install -y ${missing[*]}"
        exit 1
    fi
fi

echo "==> Source : $SRC"
echo "==> Build  : $BUILD"
echo "==> Jobs   : $JOBS"
echo "==> CPU    : $(grep -m1 '^model name' /proc/cpuinfo | sed 's/.*: //')"
echo "==> Configure"

cmake -S "$SRC" -B "$BUILD" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_SERVER=ON \
    -DLLAMA_SERVER_SSL=ON \
    -DLLAMA_CURL=ON \
    -DGGML_NATIVE=ON \
    -DGGML_LTO=ON \
    -DGGML_CUDA=OFF -DGGML_MUSA=OFF \
    -DGGML_HIPBLAS=OFF -DGGML_VULKAN=OFF \
    -DGGML_SYCL=OFF -DGGML_KOMPUTE=OFF \
    -DGGML_METAL=OFF -DGGML_RPC=OFF \
    -DGGML_BLAS=OFF -DGGML_ACCELERATE=OFF

echo "==> Build"
time cmake --build "$BUILD" -j "$JOBS" \
    --target llama-server llama-cli llama-quantize llama-bench

echo ""
echo "==> Done. Binaries:"
for b in llama-server llama-cli llama-quantize llama-bench; do
    printf "  %s\n" "$BUILD/bin/$b"
done
