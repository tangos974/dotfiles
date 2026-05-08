#!/bin/sh
# Shared helpers for stowing dotfiles packages. Expects DOTFILES_DIR to be set.

# Move a non-symlink file aside before symlinking something in its place.
# For files inside a stow package, prefer stow_pkg() — it backs up conflicts
# automatically into ~/.local/state/dotfiles-stow-backups/. Use this helper
# only for ad-hoc symlinks outside any stow package (e.g. ln -sfn into a
# Mozilla profile directory).
backup_if_needed() {
  path="$1"
  [ -e "$path" ] || return 0
  [ -L "$path" ] && return 0
  dest="${path}.before-stow"
  [ -e "$dest" ] && dest="${path}.before-stow.$(date +%s)"
  mv -- "$path" "$dest"
  printf 'Backed up: %s -> %s\n' "$path" "$dest"
}

backup_stow_file_conflicts() {
  pkg="$1"
  pkg_root="${DOTFILES_DIR}/${pkg}"
  prefix="${pkg_root}/"
  backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-stow-backups/${pkg}"

  [ -d "$pkg_root" ] || return 0

  find "$pkg_root" -type f \
    ! -name '*.before-stow' \
    ! -name '*.before-stow.*' \
    -exec sh -c '
      prefix="$1"
      home="$2"
      backup_root="$3"
      src="$4"

      rel="${src#$prefix}"
      target="${home}/${rel}"
      backup="${backup_root}/${rel}"

      [ -e "$target" ] || exit 0
      [ -L "$target" ] && exit 0

      mkdir -p "$(dirname "$backup")"

      # If a backup already exists, decide what to do without leaving the live
      # file in place — otherwise stow would refuse to link it and abort the
      # entire package (silently breaking sibling files like bindings.conf).
      if [ -e "$backup" ]; then
        if cmp -s "$target" "$backup"; then
          rm -f -- "$target"
          printf "Dropped redundant target (matches existing backup): %s\n" "$target"
          exit 0
        fi
        backup="${backup}.$(date +%s)"
      fi

      mv -- "$target" "$backup"
      printf "Backed up conflicting file for stow: %s -> %s\n" "$target" "$backup"
    ' _ "$prefix" "$HOME" "$backup_root" {} \;
}

stow_pkg() {
  pkg="$1"
  [ -d "${DOTFILES_DIR}/${pkg}" ] || return 0
  backup_stow_file_conflicts "$pkg"
  (
    cd "$DOTFILES_DIR" &&
    stow -v --no-folding -t "$HOME" --ignore='\.before-stow(\..*)?$' "$pkg"
  )
}
