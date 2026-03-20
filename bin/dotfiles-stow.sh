#!/bin/sh
# Shared helpers for stowing dotfiles packages. Expects DOTFILES_DIR to be set.
#
# Stow refuses to replace a regular file with a symlink. Omarchy (or manual copies)
# often ship the same paths as plain files — move them aside like *.before-stow
# elsewhere. Uses find -exec instead of find|while so every shell runs backups in
# the main process (no subshell surprises with plain sh).

backup_stow_file_conflicts() {
  pkg="$1"
  pkg_root="${DOTFILES_DIR}/${pkg}"
  prefix="${pkg_root}/"
  [ -d "$pkg_root" ] || return 0
  find "$pkg_root" -type f -exec sh -c '
    prefix="$1"
    HOME="$2"
    src="$3"
    rel="${src#$prefix}"
    target="${HOME}/${rel}"
    if [ -e "$target" ] && [ ! -L "$target" ] && [ ! -e "${target}.before-stow" ]; then
      mv "$target" "${target}.before-stow"
      printf "Backed up conflicting file for stow: %s -> %s.before-stow\n" "$target" "$target"
    fi
  ' _ "$prefix" "$HOME" {} \;
}

stow_pkg() {
  pkg="$1"
  [ -d "${DOTFILES_DIR}/${pkg}" ] || return 0
  backup_stow_file_conflicts "$pkg"
  (cd "$DOTFILES_DIR" && stow -v -t "$HOME" "$pkg")
}
