#!/bin/sh
# Clean all build and artifact directories
set -e

echo "🧹 Cleaning build artifacts..."
rm -rf build artifacts
echo "✅ Clean complete"
