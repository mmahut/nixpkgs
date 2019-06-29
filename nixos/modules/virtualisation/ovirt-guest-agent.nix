{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.ovirtGuest;
  user = "ovirt-agent";
  group = "ovirt-agent"
in {

  options.services.ovirtGuest = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the oVirt guest agent.";
      };
  };

  config = mkIf cfg.enable (
      mkMerge [
    {

      services.udev.extraRules = ''
        SYMLINK=="virtio-ports/com.redhat.rhevm.vdsm", OWNER="ovirt-agent", GROUP="ovirt-agent"
        SYMLINK=="virtio-ports/ovirt-guest-agent.0", OWNER="ovirt-agent", GROUP="ovirt-agent"
      '';

      systemd.services.ovirt-guest-agent = {
        description = "Run the oVirt Guest Agent";
        serviceConfig = {
          ExecStartPre = "${modprobe} virtio_console";
          ExecStart = "${pkgs.python2}/bin/python ${pkgs.ovirt-guest-agent}/share/ovirt-guest-agent/ovirt-guest-agent.py";
          Restart = "always";
          RestartSec = 0;
        };
      };
    }
  ]
  );
}
