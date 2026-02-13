#!/bin/bash

#==================================================================#
# Script Name: install.sh
# Description: Tor + InspIRCd Hidden Service Installer
# Author: Abel Philippe
#==================================================================#

TORRC="/etc/tor/torrc"
INSPIRCD_CONF="/etc/inspircd/inspircd.conf"
HS_DIR="/var/lib/tor/hidden_service"
PORT="6667"

# ===============================
# Colors
# ===============================
BLUE="\e[94m"
GREEN="\e[92m"
YELLOW="\e[93m"
RED="\e[91m"
RESET="\e[0m"

# ===============================
# Message Functions
# ===============================

msg_info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

msg_ok() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

msg_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

msg_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
    exit 1
}

separator() {
    echo "--------------------------------------------------"
}

pause() {
    sleep 2
}

# ===============================
#            Banner
# ===============================
banner() {
    echo -e "\e[96m
          ████████╗ ██████╗ ██████╗       ██╗██████╗  ██████╗
          ╚══██╔══╝██╔═══██╗██╔══██╗      ██║██╔══██╗██╔════╝
             ██║   ██║   ██║██████╔╝█████╗██║██████╔╝██║     
             ██║   ██║   ██║██╔══██╗╚════╝██║██╔══██╗██║     
             ██║   ╚██████╔╝██║  ██║      ██║██║  ██║╚██████╗
             ╚═╝    ╚═════╝ ╚═╝  ╚═╝      ╚═╝╚═╝  ╚═╝ ╚═════╝
                                                   
    ===================== TOR-IRC Installer =======================
    ---------------------------------------------------------------
           Script to configure InspIRCd as a Tor Hidden Service
    ---------------------------------------------------------------
    ================= Developed by Abel Philippe ==================
    \e[0m"

}
banner

# ===============================
# Check Root
# ===============================
check_root() {
    if [ "$EUID" -ne 0 ]; then
        msg_error "Run this script as root (sudo)."
    fi
}

# ===============================
# Backup Files
# ===============================
backup_files() {

    msg_info "Creating backups..."

    cp "$TORRC" "$TORRC.bak" 2>/dev/null
    cp "$INSPIRCD_CONF" "$INSPIRCD_CONF.bak" 2>/dev/null

    msg_ok "Backups created."
}

# ===============================
# Configure Tor
# ===============================
config_tor() {

    msg_info "Configuring Tor Hidden Service..."

    # Remove old commented lines
    sed -i '/#HiddenServiceDir/d' "$TORRC"
    sed -i '/#HiddenServicePort/d' "$TORRC"

    # Remove duplicate settings
    sed -i '/HiddenServiceDir/d' "$TORRC"
    sed -i '/HiddenServicePort/d' "$TORRC"

    # Add the correct configuration.
    cat <<EOF >> "$TORRC"

# Tor IRC Hidden Service
HiddenServiceDir $HS_DIR
HiddenServicePort $PORT 127.0.0.1:$PORT

EOF

    msg_ok "Tor was configured automatically."
}

# ===============================
# Configure InspIRCd
# ===============================
config_inspircd() {

    msg_info "Opening InspIRCd configuration..."

    pause

    nano "$INSPIRCD_CONF"

    msg_ok "InspIRCd configured."
}

# ===============================
# Permissions
# ===============================
fix_permissions() {

    msg_info "Correcting permissions..."

    mkdir -p "$HS_DIR"

    chown -R debian-tor:debian-tor /var/lib/tor
    chmod 700 "$HS_DIR"

    msg_ok "Permissions adjusted."
}

# ===============================
# Restart Services
# ===============================
restart_services() {

    msg_info "Restarting services..."

    systemctl enable tor inspircd >/dev/null 2>&1
    systemctl restart tor
    systemctl restart inspircd

    sleep 3

    msg_ok "Active services."
}

# ===============================
# Show Onion
# ===============================
show_onion() {

    separator

    msg_info "Adress .onion:"

    if [ -f "$HS_DIR/hostname" ]; then
        ONION=$(cat "$HS_DIR/hostname")
        echo
        echo "   $ONION"
        echo
        msg_ok "Hidden Service ativo."
    else
        msg_warn "Hostname file not found."
    fi

    separator
}

# ===============================
# HexChat Guide
# ===============================
hexchat_guide() {

separator

echo -e "${BLUE}
================ HEXCHAT CONFIGURATION ================

1) Open HexChat
2) Ignore any error messages
3) Click: Add → Edit

4) Replace:
   newserver/6697

   Por:
   $ONION/$PORT

5) Uncheck:
   [ ] Use SSL for all servers

6) Click on: Connect

========================================================
${RESET}"

separator
}

# ===============================
# Final Message
# ===============================
final_message() {

echo -e "${BLUE}

====================== FINAL STEP =========================

In another terminal, run:

sudo service inspircd start && sudo service inspircd status

After that, terminate this program.

===========================================================
${RESET}"

msg_ok "Installation complete."
}

# ===============================
# Main
# ===============================
main() {

    banner

    check_root

    msg_info "Starting configuration..."

    pause

    backup_files
    config_inspircd
    config_tor
    fix_permissions
    restart_services
    show_onion
    hexchat_guide
    final_message

}

main