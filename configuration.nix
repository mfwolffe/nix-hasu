# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').



{ config, pkgs, lib, mfwolffe-pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    mfwolffe-pkgs.nixosModules.default
  ];

  nixpkgs.overlays = [
    mfwolffe-pkgs.overlays.default
  ];

  programs.mfwolffe-packages = {
    enable = true;
    packages = [
      # Rust
      "fackr" "fussr" "wezztershier-rust" "eyescore" "arco" "hyprkvm" "firp" "gump"
      # Go
      "parrot-cli" "shellp"
      # Fortran (FPM)
      "fortress" "facsimile"
      # Fortran (Make)
      "fortsh" "fit" "fuss" "ferp" "fortbite" "sniffert" "fortty"
      # C (CMake)
      "gitswitcher" "gitswitch-c" "shtick" "wmswitch"
      # Python
      "wezztershier" "spotify-cue" "waveterm-vis"
      # Gardesk suite - X11 desktop environment (https://gar.musicsian.com)
      "gar"         # Tiling window manager with Lua config
      "garbar"      # Status bar with Cairo/Pango rendering
      "garbg"       # Wallpaper daemon with video support
      "garshot"     # Screenshot utility
      "garlock"     # Screen locker with PAM
      "garlaunch"   # Application launcher
      "garclip"     # Clipboard manager
      "gardm"       # Display manager (replacing SDDM)
      "gartray"     # System tray with SNI/XEMBED
      "garchomp"    # X11 compositor with GPU rendering
      "garfield"    # File manager with dual-pane
      "garterm"     # GPU-accelerated terminal
      "garnotify"   # Notification daemon
      "gargears"    # Settings/configuration app
      "gartop"      # System monitor
      "garview"     # Document viewer (PDF, images)
      "garcalc"     # TI-Nspire-like calculator suite
    ];
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Disable PCIe ASPM to prevent link instability with RTX 4090
  boot.kernelParams = [ "pcie_aspm=off" ];

  # Disable hibernation (causes unrecoverable state with NVIDIA)
  systemd.sleep.settings.Sleep = {
    AllowHibernation = "no";
    AllowSuspendThenHibernate = "no";
    AllowHybridSleep = "no";
  };

  networking.hostName = "hasu"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Prioritize wired over WiFi (lower metric = higher priority)
  networking.networkmanager.ensureProfiles.profiles = {
    "DogNet" = {
      connection = {
        id = "DogNet";
        type = "wifi";
      };
      wifi = {
        ssid = "DogNet";
        mode = "infrastructure";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
      };
      ipv4 = {
        method = "auto";
        route-metric = 700;
      };
      ipv6 = {
        method = "auto";
        route-metric = 700;
      };
    };
    "Wired connection 1" = {
      connection = {
        id = "Wired connection 1";
        type = "ethernet";
        interface-name = "enp5s0";
      };
      ipv4 = {
        method = "auto";
        route-metric = 50;
      };
      ipv6 = {
        method = "auto";
        route-metric = 50;
      };
    };
    "Wired connection 2" = {
      connection = {
        id = "Wired connection 2";
        type = "ethernet";
        interface-name = "enp114s0";
      };
      ipv4 = {
        method = "auto";
        route-metric = 50;
      };
      ipv6 = {
        method = "auto";
        route-metric = 50;
      };
    };
  };

  # Ensure all ethernet connections have higher priority than WiFi
  networking.networkmanager.dispatcherScripts = [{
    type = "basic";
    source = pkgs.writeText "nm-prioritize-ethernet" ''
      #!/bin/sh
      # Ensure all ethernet connections use metric 50, WiFi uses 700
      if [ "$1" != "lo" ]; then
        if [ "$2" = "up" ]; then
          INTERFACE_TYPE=$(nmcli -t -f GENERAL.TYPE device show "$1" | cut -d: -f2)
          if [ "$INTERFACE_TYPE" = "ethernet" ]; then
            nmcli connection modify "$(nmcli -t -f GENERAL.CONNECTION device show "$1" | cut -d: -f2)" \
              ipv4.route-metric 50 ipv6.route-metric 50 2>/dev/null || true
          fi
        fi
      fi
    '';
  }];

  # SSL/TLS certificates
  security.pki.certificateFiles = [ "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Display manager - gardm (gardesk display manager)
  # Disable SDDM, use gardm instead
  services.displayManager.sddm.enable = false;

  # gardm display manager configuration
  # gardm is installed via mfwolffe-packages, we need to set up the systemd service
  systemd.services.gardm = {
    description = "gar Display Manager";
    after = [ "systemd-user-sessions.service" "getty@tty1.service" "plymouth-quit.service" "systemd-logind.service" ];
    conflicts = [ "getty@tty1.service" ];
    wantedBy = [ "graphical.target" ];
    aliases = [ "display-manager.service" ];

    serviceConfig = {
      Type = "notify";
      ExecStart = "${mfwolffe-pkgs.packages.${pkgs.stdenv.hostPlatform.system}.gardm}/bin/gardmd";
      ExecReload = "/bin/kill -HUP $MAINPID";
      Restart = "always";
      RestartSec = 1;
      PrivateTmp = false;
    };
  };

  # PAM configuration for gardm
  security.pam.services.gardm = {
    allowNullPassword = true;
    startSession = true;
  };

  # PAM configuration for garlock (screen locker)
  security.pam.services.garlock = {};

  # gardm configuration file
  environment.etc."gardm/config.toml".text = ''
    # gardm configuration

    [general]
    default_session = "gar"
    greeter = "${mfwolffe-pkgs.packages.${pkgs.stdenv.hostPlatform.system}.gardm}/bin/gardm-greeter"
    vt = 0
    display = ":0"

    [greeter]
    blur_radius = 20
    blur_brightness = 0.7
    show_power_buttons = true
    show_session_selector = true
    use_garbg_wallpaper = true
    fallback_wallpaper = "/usr/share/backgrounds/default.jpg"

    [security]
    allow_empty_password = false
    lockout_attempts = 5
    lockout_duration = 300
  '';

  # Force nvidia driver for X (needed for gardm which spawns Xorg directly)
  environment.etc."X11/xorg.conf.d/10-nvidia.conf".text = ''
    Section "Device"
        Identifier     "nvidia"
        Driver         "nvidia"
        BusID          "PCI:1:0:0"
        Option         "AllowEmptyInitialConfiguration"
    EndSection
  '';

  # Keep GNOME desktop manager available as a session option
  services.desktopManager.gnome.enable = true;

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Enable i3 window manager (X11)
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      rofi           # Application launcher
      i3status-rust  # Status bar (Rust rewrite, more features)
      i3lock         # Screen locker
    ];
  };

  # gar window manager - tiling WM with Lua config
  # XSession is provided by the gar package in share/xsessions/gar.desktop
  # The gar-session wrapper handles systemd integration, picom, etc.
  services.displayManager.sessionPackages = [
    mfwolffe-pkgs.packages.${pkgs.stdenv.hostPlatform.system}.gar
  ];

  # XDG portal for screen sharing, file dialogs, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
      modesetting.enable = true;
      open = false;  # Use proprietary driver (more stable)
      nvidiaSettings = true;  # Adds nvidia-settings GUI
      package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # NVIDIA kernel module options - disable power management features
  boot.extraModprobeConfig = ''
    options nvidia NVreg_DynamicPowerManagement=0x00
    options nvidia NVreg_EnableGpuFirmware=0
  '';
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;  # 32-bit libs for Steam/games

  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Environment variables for Hyprland + NVIDIA
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # Hint Electron apps to use Wayland
    WLR_NO_HARDWARE_CURSORS = "1";  # Fix invisible cursor on NVIDIA
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    TERMINAL = "alacritty";
    # Force NVIDIA-only Vulkan to prevent Mesa conflicts
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/nvidia_icd.i686.json";

    # Make pkg-config discover system profile .pc files for cargo builds
    # run directly from user shells (outside nix develop/shell).
    PKG_CONFIG_PATH = "/run/current-system/sw/lib/pkgconfig:/run/current-system/sw/share/pkgconfig";
    PKG_CONFIG_LIBDIR = "/run/current-system/sw/lib/pkgconfig:/run/current-system/sw/share/pkgconfig";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.mfwolffe = {
    isNormalUser = true;
    description = "Matthew Forrester Wolffe";
    extraGroups = [ "networkmanager" "wheel" "input" "video" "tty" ];
    shell = pkgs.fish;
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Steam gaming
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;   # For Steam Remote Play
    dedicatedServer.openFirewall = true;  # For Source dedicated servers
    gamescopeSession.enable = true;   # Optimized gaming session
  };
  programs.gamemode.enable = true;  # Feral GameMode for performance optimization
  hardware.steam-hardware.enable = true;  # Udev rules for Steam controllers/hardware

  # DualSense (PS5) controller support
  hardware.uinput.enable = true;  # Virtual input device support
  services.udev.packages = [ pkgs.dualsensectl ];  # DualSense udev rules

  # Enable fish shell
  programs.fish.enable = true;

  # Enable git
  programs.git.enable = true;

  # Enable GPG (for git commit signing via gitswitch)
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false;  # SSH handled by gitswitch-ssh, not GPG agent
  };

  # zoxide (smarter cd) - disabled in favor of gump
  programs.zoxide = {
    enable = false;
  };

  # nix-index: provides nix-locate for finding which package contains a file
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  # Enable nix-ld for running non-NixOS binaries (needed for Claude Code VSCode extension, Tauri)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      # Tauri/WebKitGTK
      gtk3
      webkitgtk_4_1
      libappindicator-gtk3
      librsvg
      libsoup_3
      glib
      cairo
      pango
      gdk-pixbuf
      atk
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # System
    btop
    htop
    fastfetch

    # Hyprland essentials
    alacritty          # Terminal emulator
    wofi               # Application launcher
    waybar             # Status bar

    # i3/X11 utilities
    libxcb             # XCB library (for gar WM development)
    xinit              # xinit/startx for launching X sessions
    xorg-server        # Includes Xephyr for nested X testing
    picom              # X11 compositor (transparency, shadows)
    polybarFull        # Status bar with all features (i3, pulseaudio, etc.)
    feh                # Wallpaper setter
    maim               # Screenshot tool (X11)
    xdotool            # X11 automation (for window screenshots)
    xclip              # Clipboard tool (X11)
    wlogout            # Logout menu
    dunst              # Notification daemon
    hyprpaper          # Wallpaper utility
    grim               # Screenshot tool
    slurp              # Screen region selector
    hyprpicker         # Color picker
    jq                 # JSON processor (for active window screenshots)
    wl-clipboard       # Clipboard utilities (wl-copy, wl-paste)
    cliphist           # Clipboard history manager
    brightnessctl      # Brightness control
    playerctl          # Media player control
    networkmanagerapplet  # Network manager tray
    gh                    # GitHub CLI

    # Browsers
    (vivaldi.override { proprietaryCodecs = true; })  # Chromium-based browser with codecs

    # Communication & Collaboration
    slack              # Team messaging
    discord            # Voice/text chat
    ferdium            # All-in-one messaging (Slack, Discord, etc.)

    # Development tools
    vscode             # Visual Studio Code
    jetbrains-toolbox  # JetBrains IDE manager

    # JetBrains IDEs
    # jetbrains.aqua                # Test automation IDE (discontinued, will be removed in NixOS 26.05)
    jetbrains.clion                 # C/C++ IDE
    jetbrains.datagrip              # Database IDE
    jetbrains.dataspell             # Data science IDE
    jetbrains.gateway               # Remote development gateway
    jetbrains.goland                # Go IDE
    jetbrains.idea                  # Java/Kotlin IDE (Ultimate)
    jetbrains.mps                   # Meta Programming System
    jetbrains.phpstorm              # PHP IDE
    jetbrains.pycharm               # Python IDE (Professional)
    jetbrains.rider                 # .NET IDE
    jetbrains.ruby-mine             # Ruby IDE
    jetbrains.rust-rover            # Rust IDE
    jetbrains.webstorm              # JavaScript/TypeScript IDE
    # jetbrains.writerside          # Documentation IDE (discontinued, will be removed in NixOS 26.05)

    # Build tools
    gnumake
    cmake
    ninja
    meson
    gcc
    gfortran
    fortran-fpm    # Fortran Package Manager (fpm command)
    clang
    llvm
    pkg-config
    autoconf
    automake
    libtool
    binutils
    gdb
    lldb

    # Rust toolchain
    rustc
    cargo
    rust-analyzer
    clippy
    rustfmt

    # Audio development
    alsa-lib
    alsa-lib.dev

    # Python with pip and pipx
    (python3.withPackages (ps: with ps; [ pip setuptools wheel ]))
    pipx

    # Libraries commonly needed for builds
    openssl
    openssl.dev
    zlib
    zlib.dev
    glib
    glib.dev
    cairo
    cairo.dev
    pango
    pango.dev
    harfbuzz
    harfbuzz.dev
    gdk-pixbuf
    gdk-pixbuf.dev
    atk
    atk.dev
    glfw
    freetype
    fontconfig

    # Code quality tools
    valgrind
    cppcheck
    clang-tools        # clang-format, clang-tidy
    flawfinder

    # Documentation
    doxygen
    graphviz

    # Terminal & utilities
    wezterm
    bat
    tmux
    tldr
    trash-cli
    pay-respects
    tree

    # Gaming utilities
    mangohud        # Performance overlay (FPS, GPU/CPU stats)
    protonup-qt     # Manage Proton-GE versions easily
    lutris          # Game launcher for non-Steam games (GOG, Epic, Wine, etc.)
    dualsensectl    # DualSense controller LED/haptic control

    # Wine/WANDA dependencies
    wineWowPackages.stable  # Wine with 32-bit support
    winetricks              # Wine dependency installer
    steam-run               # FHS environment for running Wine/non-NixOS binaries
    freetype                # Font library Wine needs
    fontconfig              # Font configuration

    # WANDA GUI (Tauri) dependencies
    gtk3
    webkitgtk_4_1
    libappindicator-gtk3
    librsvg
    libsoup_3
    glib
    cairo
    pango
    gdk-pixbuf
    atk
    pkg-config

    # Node.js for WANDA frontend
    nodejs_22
    nodePackages.npm

    # Media creation
    audacity        # Audio editing
    reaper          # DAW
    reaper-reapack-extension  # Reaper package manager
    reaper-sws-extension      # Reaper plugin extension
    gimp            # Image editing
    kdePackages.kdenlive  # Video editing
    obs-studio      # Screen recording & streaming

    # Office
    libreoffice     # Office suite (Writer, Calc, Impress, etc.)

    # AI coding tools
    codex            # OpenAI Codex CLI
    code-cursor      # Cursor AI code editor
    claude-code

    # Editing
    neovim
  ];

  # Fonts (Nerd Font for waybar icons, Font Awesome for polybar)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable Tailscale VPN
  services.tailscale.enable = true;

  # Enable nginx
  services.nginx = {
    enable = true;
    virtualHosts."localHost" = {
      root = "/var/www/localhost";
    };
};

  # Cloudflare WARP (bypass carrier throttling)
  services.cloudflare-warp.enable = true;

  # Waydroid (Android container for running Android apps like Kindle)
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;  # Patched for modern kernels using nftables
  };

  # Ollama with NVIDIA GPU support
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;  # Enable password authentication
    };
    openFirewall = true;
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
