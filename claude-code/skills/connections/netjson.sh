#!/bin/bash
# netjson.sh — all network connections with process info and IP ownership as JSON
# Requires: lsof, dig, whois, jq
# Run with sudo for full visibility of all processes.

cache_dir=$(mktemp -d)
trap 'rm -rf "$cache_dir"' EXIT

lookup_ip() {
  local ip=$1
  local cache_file="$cache_dir/$(echo "$ip" | tr '.:%' '_')"
  if [ -f "${cache_file}.rdns" ]; then
    return
  fi
  local rdns owner
  rdns=$(dig +short -x "$ip" 2>/dev/null | sed 's/\.$//' | head -1 | tr -cd '[:print:]')
  owner=$(whois "$ip" 2>/dev/null | grep -i '^OrgName:' | head -1 | sed 's/^OrgName:[[:space:]]*//' | tr -cd '[:print:]')
  echo "${rdns:-}" > "${cache_file}.rdns"
  echo "${owner:-}" > "${cache_file}.owner"
}

get_rdns() { cat "$cache_dir/$(echo "$1" | tr '.:%' '_').rdns" 2>/dev/null; }
get_owner() { cat "$cache_dir/$(echo "$1" | tr '.:%' '_').owner" 2>/dev/null; }

results="[]"

while IFS= read -r line; do
  pid=$(echo "$line" | awk '{print $2}')
  proc=$(ps -p "$pid" -o comm= 2>/dev/null | awk -F'/' '{print $NF}' | tr -cd '[:print:]')
  proto=$(echo "$line" | awk '{print $8}')
  name_field=$(echo "$line" | awk '{print $9}')
  state=$(echo "$line" | awk '{print $10}' | tr -d '()')

  # Parse connection direction
  case "$name_field" in
    *"->"*)
      direction="outbound"
      local_addr=$(echo "$name_field" | awk -F'->' '{print $1}')
      remote_addr=$(echo "$name_field" | awk -F'->' '{print $2}')
      ;;
    *)
      direction="listen"
      local_addr="$name_field"
      remote_addr=""
      ;;
  esac

  # Extract local port
  local_port=$(echo "$local_addr" | awk -F: '{print $NF}')
  [ "$local_port" = "*" ] && local_port="0"

  # Extract remote IP and port, do lookups
  remote_ip=""
  remote_port="0"
  rdns=""
  owner=""
  if [ -n "$remote_addr" ]; then
    remote_ip=$(echo "$remote_addr" | sed 's/:[0-9]*$//')
    remote_port=$(echo "$remote_addr" | awk -F: '{print $NF}')
    if [ -n "$remote_ip" ] && [ "$remote_ip" != "*" ]; then
      lookup_ip "$remote_ip"
      rdns=$(get_rdns "$remote_ip")
      owner=$(get_owner "$remote_ip")
    fi
  fi

  [ -z "$state" ] && state="-"

  results=$(echo "$results" | jq \
    --arg pid "$pid" \
    --arg process "${proc:-unknown}" \
    --arg proto "$proto" \
    --arg direction "$direction" \
    --arg state "$state" \
    --arg local_addr "$local_addr" \
    --arg local_port "$local_port" \
    --arg remote_ip "${remote_ip:-}" \
    --arg remote_port "$remote_port" \
    --arg rdns "${rdns:-}" \
    --arg owner "${owner:-}" \
    '. + [{
      "pid": ($pid | tonumber),
      "process": $process,
      "proto": $proto,
      "direction": $direction,
      "state": $state,
      "local_addr": $local_addr,
      "local_port": ($local_port | tonumber),
      "remote_ip": $remote_ip,
      "remote_port": ($remote_port | tonumber),
      "rdns": $rdns,
      "owner": $owner
    }]')
done < <(lsof -i -nP 2>/dev/null | grep -v "^COMMAND")

echo "$results" | jq .
