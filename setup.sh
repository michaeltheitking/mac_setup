#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
export DOTFILES_DIR

detect_platform() {
  if [ -n "${DOTFILES_PLATFORM:-}" ]; then
    printf '%s\n' "$DOTFILES_PLATFORM"
    return
  fi

  case "$(uname -s)" in
    Darwin)
      printf 'macos\n'
      ;;
    Linux)
      if command -v omarchy >/dev/null 2>&1; then
        printf 'omarchy\n'
      else
        echo "Unsupported Linux system. This setup supports Omarchy only." >&2
        return 1
      fi
      ;;
    *)
      echo "Unsupported operating system: $(uname -s)" >&2
      return 1
      ;;
  esac
}

case "$(detect_platform)" in
  macos)
    exec "$DOTFILES_DIR/setup_macos.sh"
    ;;
  omarchy)
    exec "$DOTFILES_DIR/setup_omarchy.sh"
    ;;
  *)
    echo "DOTFILES_PLATFORM must be macos or omarchy." >&2
    exit 1
    ;;
esac
