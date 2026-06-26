# Distributed llama.cpp pool — CUDA RPC worker + direct-tailnet firewall.
# Partner side runs on nomad: ~/bin/pool-llama-server.sh (llama-server orchestrator).
# Added as a self-contained module; imported from configuration.nix.
{ ... }:
{
  # Trust the tailnet interface so nomad can reach the RPC port directly over
  # WireGuard. This replaces the SSH tunnel (no TCP-over-TCP / double-encryption).
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Reboot-proof CUDA RPC worker for the pool. Binds all interfaces, but only
  # reachable via tailscale0 (LAN/other ifaces still firewalled). No auth — fine
  # on the private tailnet.
  systemd.services.llama-rpc = {
    description = "llama.cpp RPC server (CUDA worker for nomad distributed LLM pool)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "mfwolffe";
      ExecStart = "/home/mfwolffe/llama-cuda/bin/rpc-server -H 0.0.0.0 -p 50052";
      Restart = "always";
      RestartSec = 3;
      # libcuda.so (driver) lives here on NixOS; the rest is in the binary's RPATH.
      Environment = "LD_LIBRARY_PATH=/run/opengl-driver/lib";
    };
  };
}
