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

# Initialize tracker and database
initialize_tracker_and_db() {
    log "Initializing tracker and database..."
    cd ~/cat-token-box
    sudo docker-compose down
    sudo docker volume rm cat-token-box_postgres_data
    sudo docker-compose up -d
    sleep 30  # Wait for the services to start
    log "Tracker and database initialization complete."
}

# Check tracker status
check_tracker_status() {
    log "Checking tracker status..."
    status=$(sudo docker exec -it tracker yarn cli tracker status 2>&1)
    if echo "$status" | grep -q "relation \"block\" does not exist"; then
        handle_error "Tracker database not initialized properly. Attempting to reinitialize..."
        initialize_tracker_and_db
    elif echo "$status" | grep -q "tracker status is abnormal"; then
        handle_error "Tracker status is abnormal. Attempting to restart..."
        sudo docker-compose restart tracker
        sleep 30  # Wait for the tracker to restart
    else
        log "Tracker status: $status"
    fi
}

# Start mint script
start_mint_cat() {
    cd ~/cat-token-box/packages/cli
    echo '#!/bin/bash

    check_balance() {
        balance_output=$(sudo yarn cli wallet balances 2>&1)
        if echo "$balance_output" | grep -q "No tokens found!"; then
            echo "No tokens found in the wallet. Waiting for tokens..."
            return 1
        elif echo "$balance_output" | grep -q "Get Balance failed!"; then
            echo "Failed to get balance. Checking tracker status..."
            check_tracker_status
            return 1
        else
            echo "Balance check successful."
            return 0
        fi
    }

    while true; do
        if check_balance; then
            command="sudo yarn cli mint -i 59d566844f434e419bf5b21b5c601745fcaaa24482b8d68f32b2582c61a95af2_0 5 --fee-rate $(curl -s https://explorer.unisat.io/fractal-mainnet/api/bitcoin-info/fee | jq '\''.data.fastestFee'\'')"
            
            eval $command

            if [ $? -ne 0 ]; then
                echo "Command execution failed, retrying in 60 seconds"
                sleep 60
            else
                sleep 1
            fi
        else
            echo "Waiting 60 seconds before retrying..."
            sleep 60
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
    balance_output=$(sudo yarn cli wallet balances 2>&1)
    if echo "$balance_output" | grep -q "No tokens found!"; then
        handle_error "No tokens found in the wallet."
    elif echo "$balance_output" | grep -q "Get Balance failed!"; then
        handle_error "Failed to get balance. Checking tracker status..."
        check_tracker_status
    else
        echo "$balance_output"
    fi
}

# Display main menu
echo -e "\n
Welcome to the CAT Token Box installation script.
This script is completely free and open source.
Please choose an operation as needed:
1. Install dependencies and full node
2. Create wallet
3. Start minting CAT
4. Check node synchronization log
5. Check wallet balance
6. Initialize tracker and database
7. Check tracker status
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
6)
    initialize_tracker_and_db
    ;;
7)
    check_tracker_status
    ;;
*)
    echo -e "Error: Please enter a valid number."
    ;;
esac
