#!/bin/bash
set -e

# Usage:
# ./toolify.sh <repo_url> <tool_name> <entry_script>

REPO_URL="$1"
TOOL_NAME="$2"
ENTRY_SCRIPT="$3"

BASE_DIR="$HOME/Downloads/tools"
TOOL_DIR="$BASE_DIR/$TOOL_NAME"
VENV_DIR="$TOOL_DIR/env"

echo "[*] Installing $TOOL_NAME into $TOOL_DIR"

# Clone repo
git clone "$REPO_URL" "$TOOL_DIR"

# Create virtual environment
python3 -m venv "$VENV_DIR"

# Install requirements if exists
if [ -f "$TOOL_DIR/requirements.txt" ]; then
    echo "[*] Installing requirements"
    "$VENV_DIR/bin/pip" install -r "$TOOL_DIR/requirements.txt"
fi

# Create wrapper script
WRAPPER="/usr/local/bin/$TOOL_NAME"

echo "[*] Creating wrapper at $WRAPPER"

sudo bash -c "cat > $WRAPPER" <<EOF
#!/bin/bash
"$VENV_DIR/bin/python" "$TOOL_DIR/$ENTRY_SCRIPT" "\$@"
EOF

sudo chmod +x "$WRAPPER"

echo "[+] Installed $TOOL_NAME"
echo "[+] Run it using: $TOOL_NAME"