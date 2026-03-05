{ config, pkgs, ... }:

{
  # HyprKVM: managed via standalone systemd service at
  # ~/.config/systemd/user/hyprkvm.service (not home-manager)
  # This allows the GUI restart feature to work properly

  # Home Manager needs this info
  home.username = "mfwolffe";
  home.homeDirectory = "/home/mfwolffe";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Packages to install to user profile
  home.packages = with pkgs; [
    fd   # used by fzf
    eza  # used by fzf alt-c preview

    # Wine for running Windows apps
    wineWowPackages.stable  # 32-bit + 64-bit Wine
    winetricks              # Helper for installing Windows dependencies
    bottles                 # GUI for managing Wine prefixes

    # Ebook management
    calibre                 # Comprehensive ebook manager
  ];

  # Set SHELL environment variable (needed for zellij)
  home.sessionVariables = {
    SHELL = "${pkgs.fish}/bin/fish";
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  # ──────────────────────────────────────────────────────────────
  # Git configuration
  # ──────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user.name = "mfwolffe";  # Change to your name
      user.email = "wolffemf@dukes.jmu.edu";  # Change to your email
      init.defaultBranch = "trunk";
      pull.rebase = false;
      commit.gpgsign = true;
      tag.gpgsign = true;
      gpg.program = "gpg";
      # user.signingkey is set per-account by gitswitch
    };
  };

  # ──────────────────────────────────────────────────────────────
  # Fish shell (managed by Home Manager)
  # ──────────────────────────────────────────────────────────────
  programs.fish = {
    enable = true;
    shellInit = ''
      set -gx SSH_AUTH_SOCK /run/user/1000/gitswitch-ssh/current.sock
    '';
    interactiveShellInit = ''
      set fish_greeting  # Disable greeting
      pay-respects fish | source
      gump init fish | source
    '';
    shellAliases = {
      ll = "ls -la";
      nrs = "cd /etc/nixos && nix flake update mfwolffe-pkgs && sudo nixos-rebuild switch --flake .#hasu";
    };
  };

  # ──────────────────────────────────────────────────────────────
  # Bash shell
  # ──────────────────────────────────────────────────────────────
  programs.bash = {
    enable = true;
    initExtra = ''
      eval "$(gump init bash)"
    '';
  };

  # ──────────────────────────────────────────────────────────────
  # Zsh shell
  # ──────────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    initContent = ''
      eval "$(gump init zsh)"
    '';
  };

  # ──────────────────────────────────────────────────────────────
  # Starship prompt (CachyOS-style)
  # ──────────────────────────────────────────────────────────────
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };

      directory = {
        style = "bold cyan";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        style = "bold purple";
        symbol = " ";
      };

      git_status.style = "bold red";

      cmd_duration = {
        min_time = 2000;
        style = "bold yellow";
      };

      # Language icons with brand colors
      rust.symbol = "[](bold #f74c00) ";
      python.symbol = "[](bold #3776ab) ";
      golang.symbol = "[](bold #00add8) ";
      nodejs.symbol = "[](bold #5fa04e) ";
      c.symbol = "[](bold #a8b9cc) ";
      lua.symbol = "[](bold #000080) ";
      nix_shell.symbol = "[](bold #5277c3) ";
    };
  };

  # ──────────────────────────────────────────────────────────────
  # Zellij terminal multiplexer
  # ──────────────────────────────────────────────────────────────
  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
    attachExistingSession = false;
    settings = {
      theme = "minimal";
      pane_frames = false;
      simplified_ui = true;
      default_mode = "normal";
      mouse_mode = true;
      copy_on_select = true;
      scrollback_editor = "nvim";
      show_startup_tips = false;
    };
    # KDL config appended after settings
    extraConfig = ''
      default_layout "compact"

      // Minimal theme matching tmux config
      themes {
        minimal {
          fg "#b8c0cc"
          bg "#1f2430"
          black "#0b0b0b"
          red "#e05f5f"
          green "#7bd88f"
          yellow "#ffd866"
          blue "#5c9fd7"
          magenta "#c59ac5"
          cyan "#5fb4b4"
          white "#e5e9f0"
          orange "#f9ae58"
        }
      }

      keybinds clear-defaults=true {
        // Shared binds available in all modes
        shared_except "locked" {
          // Tab management
          bind "Alt t" { NewTab; }
          bind "Ctrl w" { CloseTab; }
          bind "Ctrl Alt Left" { GoToPreviousTab; }
          bind "Ctrl Alt Right" { GoToNextTab; }
          bind "Alt 1" { GoToTab 1; }
          bind "Alt 2" { GoToTab 2; }
          bind "Alt 3" { GoToTab 3; }
          bind "Alt 4" { GoToTab 4; }
          bind "Alt 5" { GoToTab 5; }

          // Pane splits
          bind "Alt \\" { NewPane "Right"; }
          bind "Alt Shift \\" { NewPane "Down"; }

          // Pane focus (arrow keys)
          bind "Ctrl Shift Left" { MoveFocus "Left"; }
          bind "Ctrl Shift Right" { MoveFocus "Right"; }
          bind "Ctrl Shift Up" { MoveFocus "Up"; }
          bind "Ctrl Shift Down" { MoveFocus "Down"; }

          // Pane focus (Alt+Shift arrows - SSH friendly)
          bind "Alt Shift Left" { MoveFocus "Left"; }
          bind "Alt Shift Right" { MoveFocus "Right"; }
          bind "Alt Shift Up" { MoveFocus "Up"; }
          bind "Alt Shift Down" { MoveFocus "Down"; }

          // Pane focus (IJKL alternative)
          bind "Alt Shift j" { MoveFocus "Left"; }
          bind "Alt Shift l" { MoveFocus "Right"; }
          bind "Alt Shift i" { MoveFocus "Up"; }
          bind "Alt Shift k" { MoveFocus "Down"; }

          // Pane resize
          bind "Ctrl Alt Shift Left" { Resize "Increase Left"; }
          bind "Ctrl Alt Shift Right" { Resize "Increase Right"; }
          bind "Ctrl Alt Shift Up" { Resize "Increase Up"; }
          bind "Ctrl Alt Shift Down" { Resize "Increase Down"; }

          // Close pane
          bind "Alt Shift w" { CloseFocus; }
          bind "Ctrl Alt w" { CloseFocus; }

          // Mode switching
          bind "Ctrl g" { SwitchToMode "Locked"; }
          bind "Ctrl Space" { SwitchToMode "Pane"; }
          bind "Alt s" { SwitchToMode "Scroll"; }
          bind "Ctrl o" { SwitchToMode "Session"; }

          // Quick actions
          bind "Alt q" { Quit; }
          bind "Alt f" { ToggleFloatingPanes; }
          bind "Alt z" { ToggleFocusFullscreen; }
          bind "Alt Shift d" { Detach; }
        }

        locked {
          bind "Ctrl g" { SwitchToMode "Normal"; }
        }

        pane {
          bind "Esc" { SwitchToMode "Normal"; }
          bind "Ctrl Space" { SwitchToMode "Normal"; }
          bind "h" { MoveFocus "Left"; }
          bind "l" { MoveFocus "Right"; }
          bind "j" { MoveFocus "Down"; }
          bind "k" { MoveFocus "Up"; }
          bind "n" { NewPane; }
          bind "x" { CloseFocus; }
          bind "f" { ToggleFocusFullscreen; }
          bind "z" { TogglePaneFrames; }
          bind "w" { ToggleFloatingPanes; }
        }

        scroll {
          bind "Esc" { SwitchToMode "Normal"; }
          bind "Alt s" { SwitchToMode "Normal"; }
          bind "j" { ScrollDown; }
          bind "k" { ScrollUp; }
          bind "d" { HalfPageScrollDown; }
          bind "u" { HalfPageScrollUp; }
          bind "g" { ScrollToTop; }
          bind "G" { ScrollToBottom; }
          bind "/" { SwitchToMode "EnterSearch"; SearchInput 0; }
        }

        search {
          bind "Esc" { SwitchToMode "Normal"; }
          bind "n" { Search "down"; }
          bind "N" { Search "up"; }
        }

        entersearch {
          bind "Esc" { SwitchToMode "Normal"; }
          bind "Enter" { SwitchToMode "Search"; }
        }

        session {
          bind "Esc" { SwitchToMode "Normal"; }
          bind "Ctrl o" { SwitchToMode "Normal"; }
          bind "d" { Detach; }
          bind "w" {
            LaunchOrFocusPlugin "session-manager" {
              floating true
              move_to_focused_tab true
            };
            SwitchToMode "Normal";
          }
        }

        normal {
          // Normal mode - most binds are in shared_except
        }
      }
    '';
  };

  # ──────────────────────────────────────────────────────────────
  # bat (better cat)
  # ──────────────────────────────────────────────────────────────
  programs.bat = {
    enable = true;
    config = {
      theme = "base16";
      style = "numbers,changes,header";
      pager = "less -FR";
      map-syntax = [ "*.conf:INI" "*.kdl:Rust" ];
    };
  };

  # ──────────────────────────────────────────────────────────────
  # fzf (fuzzy finder)
  # ──────────────────────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [ "--height 40%" "--border" "--reverse" ];

    # Ctrl+T (file widget)
    fileWidgetCommand = "fd --type f --hidden --exclude .git";
    fileWidgetOptions = [ "--preview 'bat --color=always --style=numbers --line-range=:500 {}'" ];

    # Alt+C (cd widget)
    changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
    changeDirWidgetOptions = [ "--preview 'eza --tree --color=always {} | head -50'" ];

    # Ctrl+R (history)
    historyWidgetOptions = [ "--sort" "--exact" ];

    # Colors matching zellij theme
    colors = {
      fg = "#b8c0cc";
      bg = "#1f2430";
      hl = "#7bd88f";
      "fg+" = "#e5e9f0";
      "bg+" = "#2d3441";
      "hl+" = "#7bd88f";
      info = "#5c9fd7";
      prompt = "#7bd88f";
      pointer = "#f9ae58";
      marker = "#e05f5f";
    };
  };

  # ──────────────────────────────────────────────────────────────
  # zoxide (smarter cd) - disabled in favor of gump
  # ──────────────────────────────────────────────────────────────
  programs.zoxide = {
    enable = false;
  };

  # ──────────────────────────────────────────────────────────────
  # GitHub CLI
  # ──────────────────────────────────────────────────────────────
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
        pl = "pr list";
        il = "issue list";
        iv = "issue view";
      };
    };
  };

  # ──────────────────────────────────────────────────────────────
  # ripgrep
  # ──────────────────────────────────────────────────────────────
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
      "--hidden"
      "--glob=!.git/*"
      "--max-columns=150"
      "--max-columns-preview"
    ];
  };

  # ──────────────────────────────────────────────────────────────
  # tealdeer (tldr pages)
  # ──────────────────────────────────────────────────────────────
  programs.tealdeer = {
    enable = true;
    settings = {
      display = {
        compact = false;
        use_pager = true;
      };
      updates = {
        auto_update = true;
        auto_update_interval_hours = 720;  # 30 days
      };
    };
  };

  # ──────────────────────────────────────────────────────────────
  # Ungoogled Chromium (privacy-focused, FOSS)
  # ──────────────────────────────────────────────────────────────
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;

    # Extensions (from Chrome Web Store - use extension ID)
    # Find IDs at: chrome.google.com/webstore -> extension URL ends with /[ID]
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }  # uBlock Origin
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; }  # Dark Reader
      { id = "nngceckbapebfimnlniiiahkandclblb"; }  # Bitwarden
    ];

    # Command-line flags for performance and privacy
    commandLineArgs = [
      "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"  # Hardware video acceleration
      "--disable-features=UseChromeOSDirectVideoDecoder"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
      "--disable-reading-from-canvas"  # Fingerprinting protection
      "--disable-breakpad"             # Disable crash reporting
      "--no-default-browser-check"
      "--disable-sync"                 # Disable Google sync remnants
      "--ozone-platform-hint=auto"     # Wayland/X11 auto-detect
    ];

    # Browser policies for additional hardening
    # See: chromeenterprise.google/policies/
    dictionaries = [
      pkgs.hunspellDictsChromium.en_US
    ];
  };

  # ──────────────────────────────────────────────────────────────
  # wezterm (package only - uses existing config)
  # ──────────────────────────────────────────────────────────────
  programs.wezterm = {
    enable = true;
    # Not managing config - your existing ~/.config/wezterm is preserved
  };

  # ──────────────────────────────────────────────────────────────
  # waybar (package only - uses existing config)
  # ──────────────────────────────────────────────────────────────
  programs.waybar = {
    enable = true;
    # Not managing config - your existing ~/.config/waybar is preserved
  };

  # ──────────────────────────────────────────────────────────────
  # Hyprland config (link your existing config)
  # ──────────────────────────────────────────────────────────────
  # Option 1: Symlink your existing dotfiles
  # home.file.".config/hypr".source = ~/GithubOrgs/tenseleyFlow/ndotfiles/hypr2;

  # Option 2: Manage inline (example)
  # wayland.windowManager.hyprland = {
  #   enable = true;
  #   settings = {
  #     # your hyprland config here
  #   };
  # };

  # ──────────────────────────────────────────────────────────────
  # Waybar (link your existing config)
  # ──────────────────────────────────────────────────────────────
  # home.file.".config/waybar".source = ~/GithubOrgs/tenseleyFlow/ndotfiles/waybar2;

  # ──────────────────────────────────────────────────────────────
  # Wezterm
  # ──────────────────────────────────────────────────────────────
  # home.file.".config/wezterm".source = ~/GithubOrgs/tenseleyFlow/ndotfiles/wezterm;

  # ──────────────────────────────────────────────────────────────
  # Example: Managing a service (dunst notifications)
  # ──────────────────────────────────────────────────────────────
  # services.dunst = {
  #   enable = true;
  #   settings = {
  #     global = {
  #       font = "JetBrainsMono Nerd Font 10";
  #       frame_width = 2;
  #     };
  #   };
  # };

  # This value determines the Home Manager release compatibility.
  # Don't change this unless you know what you're doing.
  home.stateVersion = "24.11";
}
