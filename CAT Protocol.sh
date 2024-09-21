#!/bin/bash

# Colors for styling
COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_YELLOW="\e[33m"
COLOR_BLUE="\e[34m"
COLOR_CYAN="\e[36m"
COLOR_RESET="\e[0m"

# Function to display and open links
display_and_open_links() {
    local telegram_link="https://telegram.me/Maranscrypto"
    local twitter_link="https://x.com/Maranscrypto"

    echo -e "\nWelcome to the Fractal Node Setup Script.\n"
    echo -e "Join Telegram channel: ${COLOR_BLUE}${telegram_link}${COLOR_RESET}"
    echo -e "Follow us on 𝕏 : ${COLOR_BLUE}${twitter_link}${COLOR_RESET}\n"
}

# Call the function to display and potentially open links
display_and_open_links

# Log function with emoji support
log() {
    echo -e "${COLOR_CYAN}$1${COLOR_RESET}"
}

# Error handling with emoji support
handle_error() {
    echo -e "${COLOR_RED}❌ Error: $1${COLOR_RESET}"
    exit 1
}

Crontab_file="/usr/bin/crontab"

# Check if root user
check_root() {
    [[ $EUID != 0 ]] && echo "Error: Not currently root user. Please switch to root account or use 'sudo su' to obtain temporary root privileges." && exit 1
}

# Install dependencies and full node
install_env_and_full_node() {
    check_root
    # ... (rest of the function remains the same)
}

# Create wallet
create_wallet() {
    echo -e "\n"
    cd ~/cat-token-box/packages/cli
    sudo yarn cli wallet create
    echo -e "\n"
    sudo yarn cli wallet address
    echo -e "Please save the wallet address and mnemonic phrase created above."
}

# Start mint script
start_mint_cat() {
    cd ~/cat-token-box/packages/cli
    echo '#!/bin/bash

    while true; do
        command="sudo yarn cli mint -i 59d566844f434e419bf5b21b5c601745fcaaa24482b8d68f32b2582c61a95af2_0 5 --fee-rate $(curl -s https://explorer.unisat.io/fractal-mainnet/api/bitcoin-info/fee | jq '\''.data.fastestFee'\'')"
        
        eval $command

        if [ $? -ne 0 ]; then
            echo "Command execution failed, retrying in 60 seconds"
            sleep 60
        else
            sleep 1
        fi
    done' > ~/cat-token-box/packages/cli/mint_script.sh
    chmod +x ~/cat-token-box/packages/cli/mint_script.sh
    bash ~/cat-token-box/packages/cli/mint_script.sh
}

# Check node synchronization log
check_node_log() {
    docker logs -f --tail 100 tracker
}

# Check wallet balance
check_wallet_balance() {
    cd ~/cat-token-box/packages/cli
    sudo yarn cli wallet balances
}

# Display main menu
echo -e "\n
Welcome to the CAT_Pizza Token Box installation script.
This script is completely free and open source.
Please choose an operation as needed:
1. Install dependencies and full node
2. Create wallet
3. Start minting CAT_PIZZA
4. Check node synchronization log
5. Check wallet balance
"

# Get user selection and perform corresponding operation
read -e -p "Please enter your choice: " num
case "$num" in
1)
    install_env_and_full_node
    ;;
2)
    create_wallet
    ;;
3)
    start_mint_cat
    ;;
4)
    check_node_log
    ;;
5)
    check_wallet_balance
    ;;
*)
    echo -e "Error: Please enter a valid number."
    ;;
esac
