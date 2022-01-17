#!/usr/bin/env bash
set -e

working_dir="$HOME/ovpn"

mkdir "$working_dir"
cd "$working_dir"

(
  umask 077
  echo "$ca_crt" | base64 -D -o ca.crt
  echo "$client_crt" | base64 -D -o client.crt
  echo "$client_key" | base64 -D -o client.key
)

log_path="$working_dir/ovpn.log"
sudo openvpn --client --dev tun --proto "$proto" --remote "$host" "$port" --resolv-retry infinite --nobind --persist-key --persist-tun --verb 3 --ca ca.crt --cert client.crt --key client.key > "$log_path" 2>&1 &
openvpn_pid=$!

sleep 5
# Check if the OpenVPN client still running after waiting a few seconds.
if ! ps -p "$openvpn_pid" >&-; then
  echo "OpenVPN did not keep running" >&2
  cat "$log_path"
  exit 1
fi

if [ -n "$dns_server" ]; then
  if [ -z "$dns_domain_suffix" ]; then
    echo "\$dns_domain_suffix is required if \$dns_server is specified." >&2
    exit 1
  fi

  scutil_input="
d.init
d.add ServerAddresses * $dns_server
d.add SupplementalMatchDomains * $dns_domain_suffix
set State:/Network/Service/$dns_domain_suffix/DNS
"
  echo "$scutil_input" | sudo scutil
fi

sudo dscacheutil -flushcache
