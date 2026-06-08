{ ... }:

{
  programs.zsh.oh-my-zsh.plugins = [
    "aws"
    "git"
    "kube-ps1"
    "kubectl"
    "poetry"
  ];

  programs.zsh.initExtra = ''
    export PATH="$HOME/bin:/usr/local/bin:$PATH"
    export PATH="$HOME/.local/bin:/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
    export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
    export PATH="/Users/andreausuelli/Library/Python/3.12/bin:$PATH"

    export OP_ACCOUNT="prima.1password.eu"
    export AWS_REGION="eu-west-1"
    PROMPT='$(kube_ps1)'$PROMPT

    export PATH="$PATH:$HOME/.rd/bin"

    unalias brew 2>/dev/null
    if command -v brew >/dev/null 2>&1; then
      brewser=$(/usr/bin/stat -f "%Su" "$(command -v brew)")
      alias brew='sudo -Hu '$brewser' brew'
    fi
  '';
}
