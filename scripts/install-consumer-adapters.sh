#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/install-consumer-adapters.sh <target-repo> [--force]

What it installs into the target repository:
  - AGENTS.md
  - .agents/skills/
  - .cursor/rules/
  - .windsurf/skills/
  - .github/copilot-instructions.md

Notes:
  - Existing files are preserved unless --force is provided.
  - This script is intended for tools that consume repo-local adapters
    rather than a marketplace-installed plugin.
EOF
}

FORCE=0
TARGET_REPO=""

for arg in "$@"; do
  case "$arg" in
    --force)
      FORCE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$TARGET_REPO" ]]; then
        TARGET_REPO="$arg"
      else
        echo "Unexpected argument: $arg" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$TARGET_REPO" ]]; then
  usage >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
mkdir -p "$TARGET_REPO"
TARGET_REPO="$(cd "$TARGET_REPO" && pwd)"

copy_file() {
  local source_path="$1"
  local target_path="$2"

  mkdir -p "$(dirname "$target_path")"

  if [[ -e "$target_path" && "$FORCE" -ne 1 ]]; then
    echo "Skipping existing file: $target_path"
    return
  fi

  cp "$source_path" "$target_path"
  echo "Installed: $target_path"
}

copy_dir() {
  local source_dir="$1"
  local target_dir="$2"

  if [[ "$FORCE" -eq 1 && -e "$target_dir" ]]; then
    rm -rf "$target_dir"
  fi

  mkdir -p "$target_dir"

  find "$source_dir" \( -type f -o -type l \) | while read -r source_file; do
    local relative_path
    relative_path="${source_file#$source_dir/}"
    copy_file "$source_file" "$target_dir/$relative_path"
  done
}

copy_file "$REPO_ROOT/AGENTS.md" "$TARGET_REPO/AGENTS.md"
copy_file "$REPO_ROOT/.github/copilot-instructions.md" "$TARGET_REPO/.github/copilot-instructions.md"
copy_dir "$REPO_ROOT/.agents/skills" "$TARGET_REPO/.agents/skills"
copy_dir "$REPO_ROOT/.cursor/rules" "$TARGET_REPO/.cursor/rules"
copy_dir "$REPO_ROOT/.windsurf/skills" "$TARGET_REPO/.windsurf/skills"

echo "Adapter installation complete."
