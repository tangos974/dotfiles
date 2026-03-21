#!/bin/sh
# Shared helpers for stowing dotfiles packages. Expects DOTFILES_DIR to be set.

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

      if [ ! -e "$backup" ]; then
        mv -- "$target" "$backup"
        printf "Backed up conflicting file for stow: %s -> %s\n" "$target" "$backup"
      fi
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