{ user, ... }:

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
    };
    initExtra = ''
      export ERL_AFLAGS="-kernel shell_history enabled"
      export PATH="$PATH:$HOME/.cargo/bin"

      sudo() {
        unset -f sudo
        if [[ "$(uname)" == "Darwin" ]] && ! grep "pam_tid.so" /etc/pam.d/sudo --silent; then
          command sudo sed -i -e "1s;^;auth       sufficient     pam_tid.so\n;" /etc/pam.d/sudo
        fi
        command sudo "$@"
      }
    '';
  };
}
