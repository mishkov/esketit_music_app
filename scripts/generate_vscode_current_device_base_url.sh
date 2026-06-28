#!/bin/zsh

set -euo pipefail

readonly workspace_root="${0:A:h:h}"
readonly output_file="$workspace_root/.vscode/launch_defines.json"
readonly port="${BASE_URL_PORT:-8080}"
readonly server_target="${1:-production}"

build_base_url() {
  case "$server_target" in
    emulator-localhost)
      echo "http://10.0.2.2:$port/api/"
      ;;
    localhost)
      echo "http://localhost:$port/api/"
      ;;
    production)
      echo "https://esketitmusic.online/api/"
      ;;
    current-device)
      resolve_current_device_base_url
      ;;
    *)
      echo "Unsupported server target: $server_target" >&2
      exit 1
      ;;
  esac
}

resolve_current_device_base_url() {
  local ip_address=''

  for interface_name in en0 en1 en2 en3 en4 en5 en6 en7 en8 en9; do
    interface_info="$(ifconfig "$interface_name" 2>/dev/null || true)"
    if [[ -z "$interface_info" ]]; then
      continue
    fi

    if ! grep -q 'status: active' <<<"$interface_info"; then
      continue
    fi

    candidate_ip="$(
      awk '$1 == "inet" && $2 !~ /^169\.254\./ { print $2; exit }' <<<"$interface_info"
    )"
    if [[ -n "${candidate_ip:-}" ]]; then
      ip_address="$candidate_ip"
      break
    fi
  done

  if [[ -z "${ip_address:-}" ]]; then
    echo "Unable to determine an active LAN IP address." >&2
    exit 1
  fi

  echo "http://$ip_address:$port/api/"
}

base_url="$(build_base_url)"

mkdir -p "${output_file:h}"

cat > "$output_file" <<EOF
{
  "BASE_URL": "$base_url"
}
EOF

echo "Generated $output_file with BASE_URL=$base_url"
