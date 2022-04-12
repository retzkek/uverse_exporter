{ config, lib, pkgs, ... }:

let
  # The package itself. It resolves to the package installation directory.
  uverseExporter = pkgs.callPackage ./default.nix {};

  # An object containing user configuration (in /etc/nixos/configuration.nix)
  cfg = config.services.uverseExporter;

in {
  # Create the service options
  options.services.uverseExporter = {
    enable = lib.mkEnableOption "Enable uverse exporter";

    # The following are the options we enable the user to configure for this
    # package.
    # These options can be defined or overriden from the system configuration
    # file at /etc/nixos/configuration.nix
    # The active configuration parameters are available to us through the `cfg`
    # expression.

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      example = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 8080;
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "http://192.168.1.1";
    };
    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [""];
      example = ["-v"];
    };
  };

  # Everything that should be done when/if the service is enabled
  config = lib.mkIf cfg.enable {
    # Open selected port in the firewall.
    # We can reference the port that the user configured.
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # Describe the systemd service file
    systemd.services.uverseExporter = {
      description = "AT&T Uverse broadband metrics exporter for Prometheus";
      environment = {
        PYTHONUNBUFFERED = "1";
      };

      # Wait not only for network configuration, but for it to be online.
      # The functionality of this target is dependent on the system's
      # network manager.
      # Replace the below targets with network.target if you're unsure.
      after = [ "network-online.target" ];
      wantedBy = [ "network-online.target" ];

      # Many of the security options defined here are described
      # in the systemd.exec(5) manual page
      # The main point is to give it as few privileges as possible.
      # This service should only need to talk HTTP on a high numbered port
      # -- not much more.
      serviceConfig = {
        DynamicUser = "true";
        PrivateDevices = "true";
        ProtectKernelTunables = "true";
        ProtectKernelModules = "true";
        ProtectControlGroups = "true";
        RestrictAddressFamilies = "AF_INET AF_INET6";
        LockPersonality = "true";
        RestrictRealtime = "true";
        SystemCallFilter = "@system-service @network-io @signal";
        SystemCallErrorNumber = "EPERM";
        # See how we can reference the installation path of the package,
        # along with all configured options.
        ExecStart = "${uverseExporter}/bin/uverse_exporter.py -u ${cfg.url} -p ${toString cfg.port}${lib.concatStringsSep " " cfg.extraArgs}";
        Restart = "always";
        RestartSec = "5";
      };
    };
  };
}
