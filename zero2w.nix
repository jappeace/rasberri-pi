{ lib
, modulesPath
, pkgs
, ...
}: {
  imports = [
    ./sd-image.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.overlays = [(final: prev: {
    ubootRaspberryPi3_64bit = prev.ubootRaspberryPi3_64bit.override { crossTools = true ; nativeBuildInputs = prev.ubootRaspberryPi3_64bit.nativeBuildInputs ++ [ prev.openssl ]; } ;
  } )];

  # ! Need a trusted user for deploy-rs.
  nix.settings.trusted-users = [ "@wheel" ];
  system.stateVersion = "23.11";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  sdImage = {
    # bzip2 compression takes loads of time with emulation, skip it. Enable this if you're low on space.
    compressImage = false;
    imageName = "zero2.img";

    extraFirmwareConfig = {
      # Give up VRAM for more Free System Memory
      # - Disable camera which automatically reserves 128MB VRAM
      start_x = 0;
      # - Reduce allocation of VRAM to 16MB minimum for non-rotated (32MB for rotated)
      gpu_mem = 16;

      # Configure display to 800x600 so it fits on most screens
      # * See: https://elinux.org/RPi_Configuration
      hdmi_group = 2;
      hdmi_mode = 8;
    };
  };

  # Keep this to make sure wifi works
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  boot = {
    # TODO doesn't work
    # kernelPackages = pkgs.linuxKernel.packages.linux_rpi3;

    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    # Avoids warning: mdadm: Neither MAILADDR nor PROGRAM has been set. This will cause the `mdmon` service to crash.
    # See: https://github.com/NixOS/nixpkgs/issues/254807
    swraid.enable = lib.mkForce false;
  };

  networking = {
    # interfaces."wlan0".useDHCP = true;
    # http://192.168.0.1/webpages/index.1505201829667.html
    interfaces."wlan0".ipv4.addresses = [{
      address = "192.168.0.2";
      prefixLength = 24;
    }];
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
      # ! Change the following to connect to your own network
      networks = {
        "https://jappie.me" = {
          psk = "jappiejappie";
        };
      };
    };
  };

  # Enable OpenSSH out of the box.
  services.sshd.enable = true;

  # NTP time sync.
  services.timesyncd.enable = true;

  # ! Change the following configuration
  users.users.jappie = {
    isNormalUser = true;
    home = "/home/bob";
    description = "jappie";
    extraGroups = [ "wheel" "networkmanager" ];
    # ! Be sure to put your own public key here
    openssh.authorizedKeys.keys = (import ./encrypted/keys.nix { });
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  # ! Be sure to change the autologinUser.
  services.getty.autologinUser = "jappie";
}
