#!/bin/bash
WORDLIST="/usr/share/wordlists/rockyou.txt"

for z in *.zip; do
  base="${z%.zip}"
  echo -e "\n[*] Cracking $z …"

  # 1) Try fcrackzip
  output=$(fcrackzip -u -D -p "$WORDLIST" "$z" 2>&1)
  pass=$(printf '%s\n' "$output" \
         | grep 'PASSWORD FOUND' \
         | sed -E 's/.*==[[:space:]]*([^[:space:]]+).*/\1/')

  if [ -n "$pass" ]; then
    echo "[+] fcrackzip cracked $z: $pass"
  else
    echo "[-] fcrackzip failed, trying John…"
    zip2john "$z" > "$base.hash"
    john --wordlist="$WORDLIST" "$base.hash"
    pass=$(john --show "$base.hash" | awk -F: 'NR==1{print $2}')
    [ -z "$pass" ] && echo "[-] John failed on $z" && continue
    echo "[+] John cracked $z: $pass"
  fi

  # 2) Unzip if cracked
  if [ -n "$pass" ]; then
    mkdir -p "./$base"
    unzip -P "$pass" "$z" -d "./$base"
    echo "[*] Extracted to ./$base/"
  fi
done