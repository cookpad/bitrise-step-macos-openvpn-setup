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

if [ -n "$crt_required_validity_seconds" ]; then
  crt_end=$(openssl x509 -enddate -noout -in client.crt)
  if openssl x509 -checkend "$crt_required_validity_seconds" -noout -in client.crt > /dev/null; then
    echo "VPN client certificate is valid for more than $crt_required_validity_seconds seconds ($crt_end)."
  else
    echo "VPN client certificate will expire in less than $crt_required_validity_seconds seconds ($crt_end)." >&2
    echo "Unset \$crt_required_validity_seconds ("Client Certificate minimum validity in seconds") in the Bitrise step settings while you issue a new VPN client certificate." >&2
    echo "BE CAREFUL: Do not forget to set \$crt_required_validity_seconds to its previous value ($crt_required_validity_seconds) once you have finished updating the certificate." >&2
    exit 1
  fi
fi

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
