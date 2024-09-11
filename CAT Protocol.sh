#!/bin/bash

# Display links at the start
echo -e "\nWelcome to the Fractal Node & $CAT Miner Setup Script.\n"
echo -e "Join Telegram channel: https://t.me/maranscrypto"
echo -e "Follow us on 𝕏 : https://x.com/maranscrypto\n"

# Colors for styling
COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_YELLOW="\e[33m"
COLOR_BLUE="\e[34m"
COLOR_CYAN="\e[36m"
COLOR_RESET="\e[0m"

# Log function with emoji support
log() {
    echo -e "${COLOR_CYAN}$1${COLOR_RESET}"
}

# Error handling with emoji support
handle_error() {
    echo -e "${COLOR_RED}❌ Error: $1${COLOR_RESET}"
    exit 1
}

# Check if file exists
check_file_exists() {
    if [ -f "$1" ]; then
        log "${COLOR_YELLOW}⚠️  File $1 already exists, skipping download.${COLOR_RESET}"
        return 1
    fi
    return 0
}

# Check if directory exists
check_directory_exists() {
    if [ -d "$1" ]; then
        log "${COLOR_GREEN}📁 Directory $1 already exists.${COLOR_RESET}"
    else
        log "${COLOR_YELLOW}📂 Creating directory $1...${COLOR_RESET}"
        mkdir -p "$1" || handle_error "Failed to create directory $1."
    fi
}

# Check and install missing packages
check_and_install_package() {
    if ! dpkg -l | grep -qw "$1"; then
        log "${COLOR_YELLOW}📦 Installing $1...${COLOR_RESET}"
        sudo apt-get install -y "$1" || handle_error "Failed to install $1."
    else
        log "${COLOR_GREEN}✔️  $1 is already installed!${COLOR_RESET}"
    fi
}

# Prepare server: update and install necessary packages
prepare_server() {
    log "${COLOR_BLUE}🔄 Updating server and installing necessary packages...${COLOR_RESET}"
    sudo apt-get update -y && sudo apt-get upgrade -y || handle_error "Failed to update server."

    local packages=("make" "build-essential" "pkg-config" "libssl-dev" "unzip" "tar" "lz4" "gcc" "git" "jq")
    for package in "${packages[@]}"; do
        check_and_install_package "$package"
    done
}

# Download and extract Fractal Node
download_and_extract() {
    local url="https://github.com/fractal-bitcoin/fractald-release/releases/download/v0.1.7/fractald-0.1.7-x86_64-linux-gnu.tar.gz"
    local filename="fractald-0.1.7-x86_64-linux-gnu.tar.gz"
    local dirname="fractald-0.1.7-x86_64-linux-gnu"

    check_file_exists "$filename"
    if [ $? -eq 0 ]; then
        log "${COLOR_BLUE}⬇️  Downloading Fractal Node...${COLOR_RESET}"
        wget -q "$url" -O "$filename" || handle_error "Failed to download $filename."
    fi

    log "${COLOR_BLUE}🗜️  Extracting $filename...${COLOR_RESET}"
    tar -zxvf "$filename" || handle_error "Failed to extract $filename."

    check_directory_exists "$dirname/data"
    cp "$dirname/bitcoin.conf" "$dirname/data" || handle_error "Failed to copy bitcoin.conf to $dirname/data."
}

# Check if wallet already exists
check_wallet_exists() {
    if [ -f "$HOME/.bitcoin/wallets/wallet/wallet.dat" ]; then
        log "${COLOR_GREEN}💰 Wallet already exists, skipping wallet creation.${COLOR_RESET}"
        return 1
    fi
    return 0
}

# Create new wallet
create_wallet() {
    log "${COLOR_BLUE}🔍 Checking if wallet exists...${COLOR_RESET}"
    check_wallet_exists
    if [ $? -eq 1 ]; then
        log "${COLOR_GREEN}✅ Wallet already exists, no need to create a new one.${COLOR_RESET}"
        return
    fi

    log "${COLOR_BLUE}💼 Creating new wallet...${COLOR_RESET}"

    cd fractald-0.1.7-x86_64-linux-gnu/bin || handle_error "Failed to enter bin directory."
    ./bitcoin-wallet -wallet=wallet -legacy create || handle_error "Failed to create wallet."

    log "${COLOR_BLUE}🔑 Exporting wallet private key...${COLOR_RESET}"
    ./bitcoin-wallet -wallet=$HOME/.bitcoin/wallets/wallet/wallet.dat -dumpfile=$HOME/.bitcoin/wallets/wallet/MyPK.dat dump || handle_error "Failed to export wallet private key."

    PRIVATE_KEY=$(awk -F 'checksum,' '/checksum/ {print "Wallet private key:" $2}' $HOME/.bitcoin/wallets/wallet/MyPK.dat)
    log "${COLOR_RED}$PRIVATE_KEY${COLOR_RESET}"
    log "${COLOR_YELLOW}⚠️  Please make sure to record your private key!${COLOR_RESET}"
}

# Create systemd service file for Fractal Node
create_service_file() {
    log "${COLOR_BLUE}🛠️  Creating system service for Fractal Node...${COLOR_RESET}"

    if [ -f "/etc/systemd/system/fractald.service" ]; then
        log "${COLOR_YELLOW}⚠️  Service file already exists, skipping creation.${COLOR_RESET}"
    else
        sudo tee /etc/systemd/system/fractald.service > /dev/null << EOF
[Unit]
Description=Fractal Node
After=network-online.target
[Service]
User=$USER
ExecStart=$HOME/fractald-0.1.7-x86_64-linux-gnu/bin/bitcoind -datadir=$HOME/fractald-0.1.7-x86_64-linux-gnu/data/ -maxtipage=504576000
Restart=always
RestartSec=5
LimitNOFILE=infinity
[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload || handle_error "Failed to execute daemon-reload."
        sudo systemctl enable fractald || handle_error "Failed to enable fractald service."
    fi
}

# Start Fractal Node service
start_node() {
    log "${COLOR_BLUE}🚀 Starting Fractal Node...${COLOR_RESET}"
    sudo systemctl start fractald || handle_error "Failed to start fractald service."
    log "${COLOR_GREEN}🎉 Fractal Node has been successfully started!${COLOR_RESET}"
    log "${COLOR_CYAN}📝 To view node logs, run: ${COLOR_BLUE}sudo journalctl -u fractald -f --no-hostname -o cat${COLOR_RESET}"
}

# Main function to control script execution flow
main() {
    prepare_server
    download_and_extract
    create_service_file
    create_wallet
    start_node
}

# Start main process
main
