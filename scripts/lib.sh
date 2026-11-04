#!/bin/bash
# Shared helpers for the SoleCount Mac scripts. Other scripts source this file.
# It does nothing when you run it by itself. bash 3.2 safe.

SOLECOUNT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$SOLECOUNT_ROOT/fastlane/.env"

is_placeholder() {
  case "$1" in
    ""|*XXXXXXXXXX*|*REPLACE_ME*) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_env_file() {
  if [ ! -f "$ENV_FILE" ]; then
    cp "$SOLECOUNT_ROOT/fastlane/.env.example" "$ENV_FILE"
  fi
  chmod 600 "$ENV_FILE"
}

# Read one KEY=value. Strips one pair of quotes. Empty if the file or key is missing.
get_env() {
  raw=""
  if [ -f "$ENV_FILE" ]; then
    raw="$(grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- || true)"
  fi
  case "$raw" in
    \"*\") raw="${raw#\"}"; raw="${raw%\"}" ;;
    \'*\') raw="${raw#\'}"; raw="${raw%\'}" ;;
  esac
  printf '%s' "$raw"
}

set_env() {
  key="$1"
  value="$2"
  case "$value" in
    *$'\n'*)
      echo "That answer cannot contain a new line."
      return 1
      ;;
    *[[:space:]]*)
      value="\"${value}\""
      ;;
  esac
  ensure_env_file
  if grep -qE "^${key}=" "$ENV_FILE"; then
    /usr/bin/sed -i '' "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

# A path that starts with ~/ becomes the home folder.
expand_home() {
  path="$1"
  prefix=$(printf '%s' '~')
  if [ "${path#"$prefix"/}" != "$path" ]; then
    printf '%s' "$HOME/${path#"$prefix"/}"
  else
    printf '%s' "$path"
  fi
}

key_id_from_authkey() {
  base=$(basename "$1")
  base="${base#AuthKey_}"
  base="${base%.p8}"
  printf '%s' "$base"
}

# Newest real AuthKey_*.p8 in Downloads or the private key folder. Empty if none.
find_newest_authkey() {
  newest=""
  newest_mtime=0
  for dir in "$HOME/Downloads" "$HOME/.appstoreconnect/private_keys"; do
    if [ ! -d "$dir" ]; then
      continue
    fi
    for f in "$dir"/AuthKey_*.p8; do
      if [ ! -f "$f" ]; then
        continue
      fi
      base=$(basename "$f")
      case "$base" in
        *XXXXXXXXXX*) continue ;;
      esac
      mtime=$(stat -f %m "$f" 2>/dev/null || printf '0')
      if [ "$mtime" -gt "$newest_mtime" ]; then
        newest="$f"
        newest_mtime="$mtime"
      fi
    done
  done
  printf '%s' "$newest"
}

# Copy the key outside the project and save the Key ID taken from the file name.
adopt_authkey() {
  src="$1"
  key_id="$(key_id_from_authkey "$src")"
  case "$key_id" in
    ""|*[!A-Za-z0-9]*)
      echo "Could not read a Key ID from $(basename "$src"). The name must look like AuthKey_ABC123XYZ9.p8."
      return 1
      ;;
  esac
  dest_dir="$HOME/.appstoreconnect/private_keys"
  dest="$dest_dir/AuthKey_${key_id}.p8"
  mkdir -p "$dest_dir"
  chmod 700 "$HOME/.appstoreconnect" "$dest_dir" || true
  if [ "$src" != "$dest" ]; then
    cp "$src" "$dest"
  fi
  chmod 600 "$dest"
  set_env ASC_KEY_ID "$key_id"
  set_env ASC_KEY_PATH "$dest"
  printf '%s' "$dest"
}

saved_key_path() {
  key_id="$(get_env ASC_KEY_ID)"
  key_path="$(expand_home "$(get_env ASC_KEY_PATH)")"
  if is_placeholder "$key_path" && ! is_placeholder "$key_id"; then
    key_path="$HOME/.appstoreconnect/private_keys/AuthKey_${key_id}.p8"
  fi
  printf '%s' "$key_path"
}
