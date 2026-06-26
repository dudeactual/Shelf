#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <version>" >&2
  echo "example: $0 1.0.1" >&2
  exit 2
fi

VERSION="$1"
TAG="v$VERSION"

if [[ "$VERSION" == v* ]]; then
  TAG="$VERSION"
  VERSION="${VERSION#v}"
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must look like 1.0.1" >&2
  exit 2
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree has uncommitted changes." >&2
  echo "Commit them before shipping an update." >&2
  exit 1
fi

if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Tag $TAG already exists." >&2
  exit 1
fi

echo "Building local release package for $TAG..."
VERSION="$VERSION" ./script/package_release.sh

echo "Creating tag $TAG..."
git tag "$TAG"

echo "Pushing main and $TAG..."
git push origin main
git push origin "$TAG"

echo "Done. GitHub Actions will publish the release:"
echo "https://github.com/dudeactual/Shelf/releases"
