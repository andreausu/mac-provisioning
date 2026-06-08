{ lib, ... }:

{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    set -euo pipefail

    /bin/mkdir -p /usr/local/bin

    if [[ ! -x /usr/local/bin/biscuit ]]; then
      tmpdir="$(/usr/bin/mktemp -d)"
      /usr/bin/curl -fsSL \
        "https://github.com/primait/biscuit/releases/download/v0.1.7/biscuit-darwin_amd64.tgz" \
        -o "$tmpdir/biscuit-darwin_amd64.tgz"
      /usr/bin/tar -xzf "$tmpdir/biscuit-darwin_amd64.tgz" -C "$tmpdir"
      /bin/mv "$tmpdir/biscuit" /usr/local/bin/biscuit
      /bin/chmod 0755 /usr/local/bin/biscuit
      /bin/rm -rf "$tmpdir"
    fi

    /usr/bin/curl -fsSL \
      "https://raw.githubusercontent.com/aleinside/dotfiles/master/future/electro-future.sh" \
      -o /usr/local/bin/electro
    /bin/chmod 0755 /usr/local/bin/electro
  '';
}
