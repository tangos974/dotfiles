# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Keep Omarchy defaults, but replace the expensive dynamic init with cached init files
source ~/.local/share/omarchy/default/bash/envs
source ~/.local/share/omarchy/default/bash/shell
source ~/.local/share/omarchy/default/bash/aliases
source ~/.local/share/omarchy/default/bash/functions

__omarchy_cache_dir="$HOME/.cache/omarchy/bash"
mkdir -p "$__omarchy_cache_dir"

# mise
if command -v mise >/dev/null 2>&1; then
  __mise_cache="$__omarchy_cache_dir/mise-init.bash"
  if [[ ! -s "$__mise_cache" || "$(command -v mise)" -nt "$__mise_cache" ]]; then
    mise activate bash >| "$__mise_cache"
  fi
  source "$__mise_cache"
fi

# starship
if command -v starship >/dev/null 2>&1; then
  __starship_cache="$__omarchy_cache_dir/starship-init.bash"
  if [[ ! -s "$__starship_cache" || "$(command -v starship)" -nt "$__starship_cache" ]]; then
    starship init bash >| "$__starship_cache"
  fi
  source "$__starship_cache"
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  __zoxide_cache="$__omarchy_cache_dir/zoxide-init.bash"
  if [[ ! -s "$__zoxide_cache" || "$(command -v zoxide)" -nt "$__zoxide_cache" ]]; then
    zoxide init bash >| "$__zoxide_cache"
  fi
  source "$__zoxide_cache"
fi

# try
if command -v try >/dev/null 2>&1; then
  __try_cache="$__omarchy_cache_dir/try-init.bash"
  if [[ ! -s "$__try_cache" || "$(command -v try)" -nt "$__try_cache" ]]; then
    SHELL=/bin/bash command try init ~/Work/tries >| "$__try_cache"
  fi
  source "$__try_cache"
fi

# kubectl (alias k) + kubectx (alias kx) + k9s
if command -v kubectl >/dev/null 2>&1; then
  # shellcheck disable=SC1090
  source <(kubectl completion bash)
  alias k=kubectl
  if declare -F __start_kubectl >/dev/null 2>&1; then
    complete -o default -F __start_kubectl k
  fi
fi

if command -v kubectx >/dev/null 2>&1; then
  alias kx=kubectx
  if [[ -f /usr/share/bash-completion/completions/kubectx ]]; then
    # shellcheck disable=SC1091
    source /usr/share/bash-completion/completions/kubectx
  elif [[ -f /usr/share/bash-completion/completions/kctx ]]; then
    # shellcheck disable=SC1091
    source /usr/share/bash-completion/completions/kctx
  fi
  if declare -F _kube_contexts >/dev/null 2>&1; then
    complete -F _kube_contexts kx
  else
    _kube_contexts() {
      local curr_arg
      curr_arg=${COMP_WORDS[COMP_CWORD]}
      COMPREPLY=( $(compgen -W "- $(kubectl config get-contexts --output='name' 2>/dev/null)" -- "$curr_arg" ) )
    }
    complete -F _kube_contexts kubectx kctx kx
  fi
fi

if command -v k9s >/dev/null 2>&1; then
  # shellcheck disable=SC1090
  source <(k9s completion bash 2>/dev/null) || true
fi

# fzf: keep as-is for identical behavior
if command -v fzf >/dev/null 2>&1; then
  __omarchy_fzf_completion_loader() {
    [[ -f /usr/share/fzf/completion.bash ]] || return 1
    source /usr/share/fzf/completion.bash >/dev/null 2>&1 || return 1
    complete -r -D 2>/dev/null
    unset -f __omarchy_fzf_completion_loader
    return 124
  }

  complete -D -F __omarchy_fzf_completion_loader -o bashdefault -o default

  if [[ -f /usr/share/fzf/key-bindings.bash ]]; then
    source /usr/share/fzf/key-bindings.bash
  fi
fi

bind -f ~/.local/share/omarchy/default/bash/inputrc

unset __omarchy_cache_dir __mise_cache __starship_cache __zoxide_cache __try_cache
