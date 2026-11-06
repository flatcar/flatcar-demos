#!/bin/sh
# Gather build artifacts for distribution / CI upload
set -e

echo "📦 Gathering artifacts..."
mkdir -p artifacts

if ! ls build/*.pdf > /dev/null 2>&1; then
    echo "❌ No PDFs found in build/, run scripts/build.sh first"
    exit 1
fi

cp build/*.pdf artifacts/
# PowerPoint is optional (built by make pptx)
cp build/*.pptx artifacts/ 2>/dev/null || true
echo "✅ Artifacts ready:"
ls -lh artifacts/
