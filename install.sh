#!/usr/bin/env bash
set -e

# ==============================================================================
# ARI-DEV GIT WORKSPACE ("gt") INSTALLATION SCRIPT
# ==============================================================================

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_BLUE="\033[38;2;122;162;247m"
C_SKY="\033[38;2;125;207;255m"
C_GREEN="\033[38;2;158;206;106m"
C_AMBER="\033[38;2;224;175;104m"
C_RED="\033[38;2;247;118;142m"

IC_OK=$'\uf058'
IC_ERR=$'\uf057'
IC_WARN=$'\uf071'
IC_TOOL=$'\uf0ad'
IC_CHEV=$'\uf054'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/git-tool.sh"

if [ ! -f "$SOURCE_FILE" ]; then
  echo -e "${C_RED}${C_BOLD}${IC_ERR} Error: 'git-tool.sh' not found in $SCRIPT_DIR${C_RESET}"
  exit 1
fi

echo -e "\n${C_BLUE}${C_BOLD}${IC_TOOL}  ARI-DEV GIT TOOL (gt) INSTALLER${C_RESET}"
echo -e "${C_SKY}────────────────────────────────────────────────────────${C_RESET}"
echo -e "Choose installation mode:"
echo -e "  ${C_BOLD}[1]${C_RESET} Local user installation  (Target: ${C_SKY}~/.local/bin/gt${C_RESET} - No root required)"
echo -e "  ${C_BOLD}[2]${C_RESET} Global system installation (Target: ${C_SKY}/usr/local/bin/gt${C_RESET} - Requires sudo/root)"
echo -e "  ${C_BOLD}[3]${C_RESET} Cancel"
echo -ne "\n${C_SKY}${IC_CHEV}  Select option [1-3, default 1]: ${C_RESET}"
read -r CHOICE

CHOICE="${CHOICE:-1}"

case "$CHOICE" in
  1)
    INSTALL_DIR="$HOME/.local/bin"
    TARGET="$INSTALL_DIR/gt"
    
    echo -e "\n${C_SKY}→ Creating local bin directory: $INSTALL_DIR${C_RESET}"
    mkdir -p "$INSTALL_DIR"
    
    echo -e "${C_SKY}→ Installing 'gt' to $TARGET...${C_RESET}"
    cp "$SOURCE_FILE" "$TARGET"
    chmod +x "$TARGET"
    
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
      echo -e "\n${C_AMBER}${IC_WARN} Note: '$INSTALL_DIR' is not currently in your \$PATH.${C_RESET}"
      echo -e "Add the following line to your ~/.bashrc or ~/.zshrc:"
      echo -e "  ${C_BOLD}export PATH=\"\$HOME/.local/bin:\$PATH\"${C_RESET}"
      
      echo -ne "\n${C_SKY}Would you like to automatically append this to ~/.bashrc and ~/.zshrc if they exist? (y/N): ${C_RESET}"
      read -r auto_path
      if [[ "$auto_path" =~ ^[Yy]$ ]]; then
        for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
          if [ -f "$rc" ]; then
            if ! grep -q "\.local/bin" "$rc"; then
              echo -e '\n# Added by gt installer' >> "$rc"
              echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
              echo -e "${C_GREEN}${IC_OK} Added to $rc${C_RESET}"
            fi
          fi
        done
        echo -e "${C_GREEN}${C_OK} PATH updated! Run 'source ~/.bashrc' or restart your terminal to use 'gt'.${C_RESET}"
      fi
    fi
    
    echo -e "\n${C_GREEN}${C_BOLD}${IC_OK} Successfully installed 'gt' locally!${C_RESET}"
    echo -e "Run ${C_BOLD}gt${C_RESET} in any git repository to start.\n"
    ;;
    
  2)
    INSTALL_DIR="/usr/local/bin"
    TARGET="$INSTALL_DIR/gt"
    
    echo -e "\n${C_SKY}→ Installing 'gt' globally to $TARGET (requires sudo)...${C_RESET}"
    sudo cp "$SOURCE_FILE" "$TARGET"
    sudo chmod +x "$TARGET"
    
    echo -e "\n${C_GREEN}${C_BOLD}${IC_OK} Successfully installed 'gt' globally!${C_RESET}"
    echo -e "Run ${C_BOLD}gt${C_RESET} in any git repository to start.\n"
    ;;
    
  *)
    echo -e "\n${C_AMBER}Installation canceled.${C_RESET}\n"
    exit 0
    ;;
esac
