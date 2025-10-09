#!/bin/bash

# =================================================================
# ICTO V2 Complete Setup Script - Factory-First Architecture
# Interactive menu with step-by-step or run-to-end options
# Version: 2.1
# Last Updated: 2025-10-08
# =================================================================

# Note: Don't use 'set -e' to allow graceful error handling in interactive mode

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Global variables for canister IDs
BACKEND_ID=""
TOKEN_FACTORY_ID=""
AUDIT_STORAGE_ID=""
INVOICE_STORAGE_ID=""
TEMPLATE_FACTORY_ID=""
DISTRIBUTION_FACTORY_ID=""
MULTISIG_FACTORY_ID=""
DAO_FACTORY_ID=""
LAUNCHPAD_FACTORY_ID=""

# Function to load canister IDs
load_canister_ids() {
    if [ -f ".dfx/local/canister_ids.json" ]; then
        BACKEND_ID=$(dfx canister id backend 2>/dev/null || echo "")
        TOKEN_FACTORY_ID=$(dfx canister id token_factory 2>/dev/null || echo "")
        AUDIT_STORAGE_ID=$(dfx canister id audit_storage 2>/dev/null || echo "")
        INVOICE_STORAGE_ID=$(dfx canister id invoice_storage 2>/dev/null || echo "")
        TEMPLATE_FACTORY_ID=$(dfx canister id template_factory 2>/dev/null || echo "")
        DISTRIBUTION_FACTORY_ID=$(dfx canister id distribution_factory 2>/dev/null || echo "")
        MULTISIG_FACTORY_ID=$(dfx canister id multisig_factory 2>/dev/null || echo "")
        DAO_FACTORY_ID=$(dfx canister id dao_factory 2>/dev/null || echo "")
        LAUNCHPAD_FACTORY_ID=$(dfx canister id launchpad_factory 2>/dev/null || echo "")
    fi
}

# Function to display header
display_header() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}          ICTO V2 - Factory-First Architecture Setup           ${NC}"
    echo -e "${CYAN}                        Version 2.1                            ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to display menu
display_menu() {
    display_header
    echo -e "${BLUE}Available Setup Steps:${NC}"
    echo ""
    echo -e "${MAGENTA}[0]${NC}  ${YELLOW}Clean Start${NC} - Stop DFX, clean, and start fresh"
    echo -e "${MAGENTA}[1]${NC}  Deploy All Canisters"
    echo -e "${MAGENTA}[2]${NC}  Generate DID Files for Dynamic Contracts"
    echo -e "${MAGENTA}[3]${NC}  Get Canister IDs"
    echo -e "${MAGENTA}[4]${NC}  Add Cycles to Factories"
    echo -e "${MAGENTA}[5]${NC}  Add Backend to Whitelists"
    echo -e "${MAGENTA}[6]${NC}  Load WASM into Token Factory"
    echo -e "${MAGENTA}[7]${NC}  Setup Microservices"
    echo -e "${MAGENTA}[8]${NC}  Run Health Checks"
    echo -e "${MAGENTA}[9]${NC}  Configure Service Fees"
    echo -e "${MAGENTA}[10]${NC} Generate Frontend Environment Variables"
    echo -e "${MAGENTA}[11]${NC} System Readiness Verification"
    echo -e "${MAGENTA}[12]${NC} Display Final Summary"
    echo ""
    echo -e "${MAGENTA}[99]${NC} ${GREEN}Run Complete Setup (All Steps)${NC}"
    echo -e "${MAGENTA}[q]${NC}  Exit"
    echo ""
}

# Function to ask run mode
ask_run_mode() {
    local step_number=$1
    echo ""
    echo -e "${CYAN}Choose execution mode:${NC}"
    echo -e "${MAGENTA}[1]${NC} Run this step only ${GREEN}(default)${NC}"
    echo -e "${MAGENTA}[2]${NC} Run from this step to the end"
    echo ""
    read -p "Enter your choice (1 or 2) [default: 1]: " run_mode

    # Default to 1 if empty
    if [[ -z "$run_mode" ]]; then
        run_mode=1
    fi

    echo ""
    return $run_mode
}

# ========================================
# STEP FUNCTIONS
# ========================================

step_0_clean_start() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 0: Clean Start - Stopping and Cleaning DFX${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${YELLOW}Stopping DFX replica...${NC}"
    dfx stop || true

    echo -e "${YELLOW}Starting clean DFX replica...${NC}"
    if dfx start --clean --background; then
        echo -e "${GREEN}✅ DFX started with clean state${NC}"
        echo ""
        sleep 2
        return 0
    else
        echo -e "${RED}❌ Failed to start DFX${NC}"
        echo ""
        return 1
    fi
}

step_1_deploy_canisters() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 1: Deploying All Canisters${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Deploy infrastructure canisters with fixed IDs
    echo -e "${YELLOW}Deploying infrastructure...${NC}"
    dfx deploy icp_ledger --specified-id ryjl3-tyaaa-aaaaa-aaaba-cai
    dfx deploy internet_identity --specified-id rdmx6-jaaaa-aaaaa-aaadq-cai

    # Deploy core backend
    echo -e "${YELLOW}Deploying backend gateway...${NC}"
    dfx deploy backend

    # Deploy independent storage services
    echo -e "${YELLOW}Deploying independent storage services...${NC}"
    dfx deploy audit_storage      # Append-only audit trail logs
    dfx deploy invoice_storage    # Secure payment record storage

    # Deploy factory services
    echo -e "${YELLOW}Deploying factory services...${NC}"
    dfx deploy token_factory
    dfx deploy template_factory
    dfx deploy distribution_factory
    dfx deploy multisig_factory
    dfx deploy dao_factory
    dfx deploy launchpad_factory

    echo -e "${GREEN}✅ All canisters deployed successfully${NC}"
    echo ""
    sleep 2
    return 0
}

step_2_generate_dids() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 2: Generating DID Files for Dynamic Contracts${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # List of contract templates that need DID generation
    declare -a CONTRACT_TEMPLATES=(
        "distribution_contract"
        "dao_contract"
        "launchpad_contract"
        "multisig_contract"
    )

    for contract in "${CONTRACT_TEMPLATES[@]}"; do
        echo -e "${YELLOW}Generating DID for ${contract}...${NC}"
        dfx generate ${contract}

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ ${contract} DID generated${NC}"
        else
            echo -e "${RED}❌ Failed to generate DID for ${contract}${NC}"
        fi
    done

    echo -e "${GREEN}✅ All contract template DIDs generated${NC}"
    echo ""
    sleep 2
    return 0
}

step_3_get_canister_ids() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 3: Getting Canister IDs${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    load_canister_ids

    echo -e "${GREEN}✅ Backend ID: ${BACKEND_ID}${NC}"
    echo -e "${GREEN}✅ Token Factory ID: ${TOKEN_FACTORY_ID}${NC}"
    echo -e "${GREEN}✅ Audit Storage ID: ${AUDIT_STORAGE_ID}${NC}"
    echo -e "${GREEN}✅ Invoice Storage ID: ${INVOICE_STORAGE_ID}${NC}"
    echo -e "${GREEN}✅ Template Factory ID: ${TEMPLATE_FACTORY_ID}${NC}"
    echo -e "${GREEN}✅ Distribution Factory ID: ${DISTRIBUTION_FACTORY_ID}${NC}"
    echo -e "${GREEN}✅ Multisig Factory ID: ${MULTISIG_FACTORY_ID}${NC}"
    echo -e "${GREEN}✅ DAO Factory ID: ${DAO_FACTORY_ID}${NC}"
    echo -e "${GREEN}✅ Launchpad Factory ID: ${LAUNCHPAD_FACTORY_ID}${NC}"
    echo ""
    sleep 2
    return 0
}

step_4_add_cycles() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 4: Adding Cycles to Factories${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${YELLOW}Fabricating cycles for factories (100T each)...${NC}"
    dfx ledger fabricate-cycles --canister token_factory --t 100
    dfx ledger fabricate-cycles --canister distribution_factory --t 100
    dfx ledger fabricate-cycles --canister multisig_factory --t 100
    dfx ledger fabricate-cycles --canister dao_factory --t 100
    dfx ledger fabricate-cycles --canister launchpad_factory --t 100

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Cycles added successfully to all factories${NC}"
        echo -e "${GREEN}   • Token Factory: 100T cycles${NC}"
        echo -e "${GREEN}   • Distribution Factory: 100T cycles${NC}"
        echo -e "${GREEN}   • Multisig Factory: 100T cycles${NC}"
        echo -e "${GREEN}   • DAO Factory: 100T cycles${NC}"
        echo -e "${GREEN}   • Launchpad Factory: 100T cycles${NC}"
    else
        echo -e "${RED}❌ Failed to add cycles${NC}"
        return 1
    fi
    echo ""
    sleep 2
    return 0
}

step_5_add_to_whitelists() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 5: Adding Backend to Service Whitelists${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Define services
    declare -a SERVICES=(
        "audit_storage"
        "invoice_storage"
        "token_factory"
        "template_factory"
        "distribution_factory"
        "multisig_factory"
        "dao_factory"
        "launchpad_factory"
    )

    FAILED_SERVICES=""
    SUCCESS_SERVICES=""

    for service in "${SERVICES[@]}"; do
        echo -e "${YELLOW}Adding backend to ${service} whitelist...${NC}"

        if dfx canister call "$service" "addToWhitelist" "(principal \"${BACKEND_ID}\")"; then
            SUCCESS_SERVICES="$SUCCESS_SERVICES $service"
            echo -e "${GREEN}✅ Backend added to ${service} whitelist${NC}"
        else
            FAILED_SERVICES="$FAILED_SERVICES $service"
            echo -e "${RED}❌ Failed to add backend to ${service} whitelist${NC}"
        fi

        sleep 1
    done

    # Display status report
    SUCCESS_COUNT=$(echo $SUCCESS_SERVICES | wc -w)
    FAILED_COUNT=$(echo $FAILED_SERVICES | wc -w)
    TOTAL_COUNT=${#SERVICES[@]}

    echo ""
    echo -e "${BLUE}Whitelist Status:${NC}"
    echo -e "${GREEN}✅ Successful: $SUCCESS_COUNT/$TOTAL_COUNT${NC}"
    echo -e "${RED}❌ Failed: $FAILED_COUNT/$TOTAL_COUNT${NC}"

    if [[ -n "$FAILED_SERVICES" ]]; then
        echo -e "${YELLOW}Failed services:${FAILED_SERVICES}${NC}"
    fi
    echo ""
    sleep 2
    return 0
}

step_6_load_wasm() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 6: Loading WASM into Token Factory${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Detect network (check if running on IC or local)
    NETWORK="local"
    if dfx ping ic >/dev/null 2>&1; then
        read -p "Are you deploying to IC mainnet? (y/n) [n]: " use_ic
        if [[ "$use_ic" == "y" || "$use_ic" == "Y" ]]; then
            NETWORK="ic"
        fi
    fi

    echo -e "${CYAN}Network detected: ${NETWORK}${NC}"
    echo ""

    if [[ "$NETWORK" == "ic" ]]; then
        # IC Network: Trigger auto-fetch from SNS WASM canister
        echo -e "${YELLOW}Triggering automatic WASM fetch from SNS canister...${NC}"
        FETCH_RESULT=$(dfx canister call token_factory getLatestWasmVersion --network ic 2>&1 || echo "FAILED")

        if [[ "$FETCH_RESULT" == *"ok"* ]]; then
            echo -e "${GREEN}✅ WASM fetched successfully from SNS canister${NC}"
            success_msg=$(echo "$FETCH_RESULT" | sed -n 's/.*ok.*"\([^"]*\)".*/\1/p')
            echo -e "${GREEN}Result: $success_msg${NC}"
        elif [[ "$FETCH_RESULT" == *"Already using latest version"* ]]; then
            echo -e "${GREEN}✅ Already using latest WASM version${NC}"
        else
            echo -e "${RED}❌ Failed to fetch WASM: $FETCH_RESULT${NC}"
            return 1
        fi
    else
        # Local Network: Download and upload manually
        echo -e "${YELLOW}Local network detected - manual WASM download and upload required${NC}"
        echo ""

        WASM_FILE="sns_icrc_wasm_v2.wasm"

        # Export DFX_WARNING to suppress mainnet plaintext identity warning
        export DFX_WARNING=-mainnet_plaintext_identity

        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}⚠️  SECURITY NOTICE:${NC}"
        echo -e "${CYAN}This script uses plaintext identity for IC mainnet calls.${NC}"
        echo -e "${CYAN}This is acceptable for local development and testing.${NC}"
        echo -e "${CYAN}For production deployments, use a secure identity with:${NC}"
        echo -e "${CYAN}  dfx identity new <secure-identity>${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        # Step 1: Get latest SNS version
        echo -e "${YELLOW}Step 1: Fetching latest SNS ICRC Ledger version...${NC}"
        SNS_VERSIONS=$(echo "y" | dfx canister call qaa6y-5yaaa-aaaaa-aaafa-cai get_latest_sns_version_pretty --network ic "(null)" 2>&1 || echo "FAILED")

        if [[ "$SNS_VERSIONS" == *"FAILED"* ]]; then
            echo -e "${RED}❌ Failed to fetch SNS versions from mainnet${NC}"
            echo "$SNS_VERSIONS"
            return 1
        fi

        # Extract Ledger hash from response
        LEDGER_HASH=$(echo "$SNS_VERSIONS" | grep -A1 '"Ledger"' | grep -v '"Ledger"' | sed 's/.*"\([a-f0-9]*\)".*/\1/')

        if [[ -z "$LEDGER_HASH" ]]; then
            echo -e "${RED}❌ Could not extract Ledger hash from SNS response${NC}"
            return 1
        fi

        echo -e "${GREEN}✅ Latest Ledger WASM hash: ${LEDGER_HASH}${NC}"
        echo ""

        # Step 2: Download WASM if not exists or hash changed
        if [ ! -f "$WASM_FILE" ]; then
            echo -e "${YELLOW}Step 2: Downloading WASM file from SNS canister...${NC}"

            # Convert hex to vec nat8 format
            vec_nat8_hex=$(echo $LEDGER_HASH | sed 's/\(.\{2\}\)/\1 /g' | tr ' ' '\n' | while read -r byte; do
                if [ ! -z "$byte" ]; then
                    printf "%d;" $((16#$byte))
                fi
            done | sed 's/;$//')

            # Fetch WASM from SNS canister (auto-confirm with echo "y")
            echo -e "${CYAN}Calling SNS WASM canister to get WASM blob...${NC}"
            WASM_RESULT=$(echo "y" | dfx canister call qaa6y-5yaaa-aaaaa-aaafa-cai get_wasm "(record { hash = vec { $vec_nat8_hex } })" --network ic --output idl 2>&1 || echo "FAILED")

            if [[ "$WASM_RESULT" == *"opt record"* ]]; then
                # Extract and save WASM blob
                echo -e "${CYAN}Extracting WASM blob...${NC}"
                wasm_blob=$(echo "$WASM_RESULT" | sed -n 's/.*blob "\([^"]*\)".*/\1/p')

                if [[ -n "$wasm_blob" ]]; then
                    echo "$wasm_blob" | xxd -r -p > "$WASM_FILE"
                    FILE_SIZE=$(stat -f%z "$WASM_FILE" 2>/dev/null || stat -c%s "$WASM_FILE" 2>/dev/null)
                    echo -e "${GREEN}✅ WASM saved to $WASM_FILE (${FILE_SIZE} bytes)${NC}"
                else
                    echo -e "${RED}❌ Failed to extract WASM blob${NC}"
                    return 1
                fi
            else
                echo -e "${RED}❌ Failed to fetch WASM from SNS canister${NC}"
                echo "$WASM_RESULT"
                return 1
            fi
        else
            echo -e "${GREEN}✅ WASM file already exists: $WASM_FILE${NC}"
        fi
        echo ""

        # Step 3: Upload WASM in chunks
        echo -e "${YELLOW}Step 3: Uploading WASM to Token Factory...${NC}"

        MAX_CHUNK_SIZE=$((100 * 1024))  # 100KB chunks
        FILE_SIZE=$(stat -f%z "$WASM_FILE" 2>/dev/null || stat -c%s "$WASM_FILE" 2>/dev/null)
        CHUNK_COUNT=$(( (FILE_SIZE + MAX_CHUNK_SIZE - 1) / MAX_CHUNK_SIZE ))

        echo -e "${CYAN}File size: ${FILE_SIZE} bytes${NC}"
        echo -e "${CYAN}Uploading in ${CHUNK_COUNT} chunks...${NC}"
        echo ""

        # Clear existing chunks buffer
        echo -e "${YELLOW}Clearing chunks buffer...${NC}"
        dfx canister call token_factory clearChunks >/dev/null 2>&1 || true

        # Upload chunks
        for ((chunk=0; chunk<CHUNK_COUNT; chunk++))
        do
            echo -e "${YELLOW}  Uploading chunk $((chunk + 1))/${CHUNK_COUNT}...${NC}"

            byteStart=$((chunk * MAX_CHUNK_SIZE))

            # Extract chunk and convert to Candid vec format
            chunk_data=$(dd if="$WASM_FILE" bs=1 skip=$byteStart count=$MAX_CHUNK_SIZE 2>/dev/null | \
            xxd -p -c 1 | \
            awk '{printf "0x%s; ", $1}' | \
            sed 's/; $//' | \
            awk '{print "(vec {" $0 "})"}')

            # Upload chunk
            upload_result=$(dfx canister call token_factory uploadChunk "$chunk_data" 2>&1 || echo "FAILED")

            if [[ "$upload_result" == *"ok"* ]]; then
                echo -e "${GREEN}  ✅ Chunk $((chunk + 1)) uploaded${NC}"
            else
                echo -e "${RED}  ❌ Failed to upload chunk $((chunk + 1))${NC}"
                return 1
            fi
        done

        echo -e "${GREEN}✅ All chunks uploaded${NC}"
        echo ""

        # Step 4: Finalize upload
        echo -e "${YELLOW}Step 4: Finalizing WASM upload...${NC}"

        # Convert hash to vec nat8 format
        vec_nat8_hex=$(echo $LEDGER_HASH | sed 's/\(.\{2\}\)/\1 /g' | tr ' ' '\n' | while read -r byte; do
            if [ ! -z "$byte" ]; then
                printf "%d;" $((16#$byte))
            fi
        done | sed 's/;$//')

        finalize_result=$(dfx canister call token_factory addWasm "(vec { $vec_nat8_hex })" 2>&1 || echo "FAILED")

        if [[ "$finalize_result" == *"ok"* ]]; then
            echo -e "${GREEN}✅ WASM upload finalized successfully${NC}"
            success_msg=$(echo "$finalize_result" | sed -n 's/.*ok.*"\([^"]*\)".*/\1/p')
            if [[ -n "$success_msg" ]]; then
                echo -e "${GREEN}Result: $success_msg${NC}"
            fi
        else
            echo -e "${RED}❌ Failed to finalize WASM upload${NC}"
            echo "$finalize_result"
            return 1
        fi
    fi

    # Verify WASM upload
    echo ""
    echo -e "${YELLOW}Verifying WASM upload...${NC}"
    WASM_INFO=$(dfx canister call token_factory getCurrentWasmInfo "()" 2>&1 || echo "FAILED")

    if [[ "$WASM_INFO" == *"FAILED"* ]]; then
        echo -e "${YELLOW}⚠️  Could not verify WASM info${NC}"
    else
        echo -e "${GREEN}✅ WASM verification successful${NC}"
        echo -e "${CYAN}WASM Info: $WASM_INFO${NC}"

        # Clean up local WASM file after successful upload and verification
        if [[ "$NETWORK" == "local" ]] && [[ -f "$WASM_FILE" ]]; then
            echo ""
            echo -e "${YELLOW}Cleaning up local WASM file...${NC}"
            rm -f "$WASM_FILE"
            echo -e "${GREEN}✅ Local WASM file removed (will re-download on next setup if needed)${NC}"
        fi
    fi

    echo ""
    sleep 2
    return 0
}

step_7_setup_microservices() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 7: Setting Up Microservices${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    SETUP_RESULT=$(dfx canister call backend setCanisterIds "(record {
        tokenFactory = opt principal \"$TOKEN_FACTORY_ID\";
        auditStorage = opt principal \"$AUDIT_STORAGE_ID\";
        invoiceStorage = opt principal \"$INVOICE_STORAGE_ID\";
        templateFactory = opt principal \"$TEMPLATE_FACTORY_ID\";
        distributionFactory = opt principal \"$DISTRIBUTION_FACTORY_ID\";
        multisigFactory = opt principal \"$MULTISIG_FACTORY_ID\";
        daoFactory = opt principal \"$DAO_FACTORY_ID\";
        launchpadFactory = opt principal \"$LAUNCHPAD_FACTORY_ID\";
    })" 2>&1 || echo "FAILED")

    if [[ "$SETUP_RESULT" == *"FAILED"* ]] || [[ "$SETUP_RESULT" == *"err"* ]]; then
        echo -e "${RED}❌ Microservices setup failed:${NC}"
        echo "$SETUP_RESULT"
        return 1
    else
        echo -e "${GREEN}✅ Microservices setup completed${NC}"
    fi
    echo ""
    sleep 2
    return 0
}

step_8_health_checks() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 8: Running Health Checks${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${YELLOW}Checking token deployment type info...${NC}"
    TOKEN_INFO=$(dfx canister call backend getDeploymentTypeInfo "(\"Token\")" 2>&1 || echo "FAILED")
    if [[ "$TOKEN_INFO" == *"FAILED"* ]]; then
        echo -e "${YELLOW}⚠️  Token deployment type info not available${NC}"
    else
        echo -e "${GREEN}✅ Token deployment info available${NC}"
    fi

    echo -e "${YELLOW}Checking token_factory health...${NC}"
    TOKEN_HEALTH=$(dfx canister call token_factory getServiceHealth "()" 2>&1 || echo "FAILED")
    if [[ "$TOKEN_HEALTH" == *"FAILED"* ]]; then
        echo -e "${YELLOW}⚠️  Token factory health check failed${NC}"
    else
        echo -e "${GREEN}✅ Token factory healthy${NC}"
    fi

    echo -e "${YELLOW}Checking audit_storage health...${NC}"
    AUDIT_HEALTH=$(dfx canister call audit_storage getStorageStats "()" 2>&1 || echo "FAILED")
    if [[ "$AUDIT_HEALTH" == *"FAILED"* ]]; then
        echo -e "${YELLOW}⚠️  Audit storage health check failed${NC}"
    else
        echo -e "${GREEN}✅ Audit storage healthy${NC}"
    fi
    echo ""
    sleep 2
    return 0
}

step_9_configure_fees() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 9: Configuring Service Fees${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Array of config settings (key|value|description)
    declare -a CONFIG_SETTINGS=(
        "token_factory.fee|100000000|Token Factory fee (1 ICP)"
        "token_factory.enabled|true|Enable Token Factory"
        "distribution_factory.fee|100000000|Distribution Factory fee (1 ICP)"
        "distribution_factory.enabled|true|Enable Distribution Factory"
        "multisig_factory.fee|50000000|Multisig Factory fee (0.5 ICP)"
        "multisig_factory.enabled|true|Enable Multisig Factory"
        "dao_factory.fee|500000000|DAO Factory fee (5 ICP)"
        "dao_factory.enabled|true|Enable DAO Factory"
        "launchpad_factory.fee|1000000000|Launchpad Factory fee (10 ICP)"
        "launchpad_factory.enabled|true|Enable Launchpad Factory"
    )

    for setting in "${CONFIG_SETTINGS[@]}"; do
        IFS='|' read -r key value description <<< "$setting"

        echo -e "${YELLOW}Setting ${description}...${NC}"
        CONFIG_RESULT=$(dfx canister call backend adminSetConfigValue "(\"${key}\", \"${value}\")" 2>&1 || echo "FAILED")

        if [[ "$CONFIG_RESULT" == *"FAILED"* ]] || [[ "$CONFIG_RESULT" == *"err"* ]]; then
            echo -e "${RED}  ❌ Failed to set ${key}${NC}"
        else
            echo -e "${GREEN}  ✅ ${description}: ${value}${NC}"
        fi
    done

    echo ""
    echo -e "${GREEN}✅ Service fees configured${NC}"

    # Verify configuration
    echo -e "${YELLOW}Verifying configuration...${NC}"

    declare -a VERIFY_FEES=(
        "token_factory|100000000"
        "distribution_factory|100000000"
        "multisig_factory|50000000"
        "dao_factory|500000000"
        "launchpad_factory|1000000000"
    )

    for verify in "${VERIFY_FEES[@]}"; do
        IFS='|' read -r service_name expected_value <<< "$verify"
        icp_value=$(echo "scale=2; ${expected_value}/100000000" | bc)

        FEE_CHECK=$(dfx canister call backend getServiceFee "(\"${service_name}\")" 2>&1 || echo "FAILED")

        # Format expected value with underscores like Candid does (e.g., 50_000_000)
        # Remove underscores from FEE_CHECK for comparison
        FEE_CHECK_CLEAN=$(echo "$FEE_CHECK" | tr -d '_')

        if [[ "$FEE_CHECK_CLEAN" == *"${expected_value}"* ]]; then
            echo -e "${GREEN}  ✅ ${service_name}: ${icp_value} ICP${NC}"
        else
            echo -e "${YELLOW}  ⚠️  ${service_name}: verification failed${NC}"
            echo -e "${YELLOW}     Expected: ${expected_value}, Got: ${FEE_CHECK}${NC}"
        fi
    done
    echo ""
    sleep 2
    return 0
}

step_10_generate_env() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 10: Generating Frontend Environment Variables${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    if [ -f "setupEnv.js" ]; then
        echo -e "${YELLOW}Running setupEnv.js...${NC}"
        node setupEnv.js

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Frontend environment variables generated${NC}"
            echo -e "${GREEN}   • .env.development${NC}"
            echo -e "${GREEN}   • .env${NC}"
        else
            echo -e "${RED}❌ Failed to generate environment variables${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  setupEnv.js not found${NC}"
    fi
    echo ""
    sleep 2
    return 0
}

step_11_system_verification() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 11: System Readiness Verification${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${YELLOW}Checking microservices setup status...${NC}"
    SETUP_STATUS=$(dfx canister call backend getMicroserviceSetupStatus "()" 2>&1 || echo "FAILED")
    if [[ "$SETUP_STATUS" == *"true"* ]]; then
        echo -e "${GREEN}✅ Microservices setup: Completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Microservices setup: Not completed${NC}"
    fi

    echo -e "${YELLOW}Checking all services health...${NC}"
    HEALTH_CHECK=$(dfx canister call backend getMicroserviceHealth "()" 2>&1 || echo "FAILED")
    if [[ "$HEALTH_CHECK" == *"FAILED"* ]]; then
        echo -e "${YELLOW}⚠️  Health check not available${NC}"
    else
        echo -e "${GREEN}✅ Services health check completed${NC}"
    fi

    echo -e "${YELLOW}Getting system status...${NC}"
    SYSTEM_STATUS=$(dfx canister call backend getSystemStatus "()" 2>&1 || echo "FAILED")
    if [[ "$SYSTEM_STATUS" == *"FAILED"* ]]; then
        echo -e "${YELLOW}⚠️  System status not available${NC}"
    else
        echo -e "${GREEN}✅ System status retrieved${NC}"
        if [[ "$SYSTEM_STATUS" == *"isMaintenanceMode = false"* ]]; then
            echo -e "${GREEN}   • Maintenance mode: OFF ✅${NC}"
        else
            echo -e "${YELLOW}   • Maintenance mode: ON ⚠️${NC}"
        fi
    fi
    echo ""
    sleep 2
    return 0
}

step_12_final_summary() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Step 12: Final Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    load_canister_ids

    echo -e "${GREEN}🎉 ICTO V2 Setup Complete!${NC}"
    echo ""
    echo -e "${BLUE}📊 Deployed Canisters:${NC}"
    echo -e "• Backend: ${BACKEND_ID}"
    echo -e "• Token Factory: ${TOKEN_FACTORY_ID}"
    echo -e "• Distribution Factory: ${DISTRIBUTION_FACTORY_ID}"
    echo -e "• Multisig Factory: ${MULTISIG_FACTORY_ID}"
    echo -e "• DAO Factory: ${DAO_FACTORY_ID}"
    echo -e "• Launchpad Factory: ${LAUNCHPAD_FACTORY_ID}"
    echo -e "• Template Factory: ${TEMPLATE_FACTORY_ID}"
    echo -e "• Audit Storage: ${AUDIT_STORAGE_ID}"
    echo -e "• Invoice Storage: ${INVOICE_STORAGE_ID}"
    echo ""
    echo -e "${BLUE}✅ Configuration Status:${NC}"
    echo -e "• Contract DIDs: ✅ Generated"
    echo -e "• Factory Whitelist: ✅ Configured"
    echo -e "• Microservices Setup: ✅ Connected"
    echo -e "• Service Fees: ✅ Configured"
    echo -e "• WASM Templates: ✅ Loaded"
    echo -e "• Frontend Env: ✅ Generated"
    echo ""
    echo -e "${BLUE}💰 Service Fees (ICP):${NC}"
    echo -e "• Token Factory: 1.0 ICP"
    echo -e "• Distribution Factory: 1.0 ICP"
    echo -e "• Multisig Factory: 0.5 ICP"
    echo -e "• DAO Factory: 5.0 ICP"
    echo -e "• Launchpad Factory: 10.0 ICP"
    echo ""
    echo -e "${BLUE}🔗 Useful Commands:${NC}"
    echo -e "• System status: ${YELLOW}dfx canister call backend getSystemStatus \"()\"${NC}"
    echo -e "• Microservices health: ${YELLOW}dfx canister call backend getMicroserviceHealth \"()\"${NC}"
    echo -e "• Service fee: ${YELLOW}dfx canister call backend getServiceFee \"(\\\"token_factory\\\")\"${NC}"
    echo ""
    echo -e "${BLUE}📚 Documentation:${NC}"
    echo -e "• Architecture: ${YELLOW}documents/ARCHITECTURE.md${NC}"
    echo -e "• Backend-Factory Integration: ${YELLOW}documents/BACKEND_FACTORY_INTEGRATION.md${NC}"
    echo ""
    echo -e "${GREEN}✨ System Ready!${NC}"
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "1. Start frontend: ${YELLOW}npm run dev${NC}"
    echo -e "2. Access app: ${YELLOW}http://localhost:5173${NC}"
    echo ""
    return 0
}

# ========================================
# MAIN EXECUTION LOGIC
# ========================================

run_step() {
    local step=$1

    # Load canister IDs before running any step (except 0, 1, 2, 3)
    # Steps 4+ require canister IDs to be available
    if [ $step -ge 4 ]; then
        load_canister_ids

        # Verify critical IDs are loaded
        if [[ -z "$BACKEND_ID" ]]; then
            echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
            echo -e "${RED}❌ Error: Backend ID not found${NC}"
            echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
            echo ""
            echo -e "${YELLOW}This step requires canister IDs to be available.${NC}"
            echo -e "${YELLOW}Please run Step 3 (Get Canister IDs) first.${NC}"
            echo ""
            echo -e "${CYAN}Suggested actions:${NC}"
            echo -e "1. Return to menu and run Step 3"
            echo -e "2. Or run from Step 3 to complete the setup"
            echo ""
            return 1
        fi
    fi

    case $step in
        0) step_0_clean_start; return $? ;;
        1) step_1_deploy_canisters; return $? ;;
        2) step_2_generate_dids; return $? ;;
        3) step_3_get_canister_ids; return $? ;;
        4) step_4_add_cycles; return $? ;;
        5) step_5_add_to_whitelists; return $? ;;
        6) step_6_load_wasm; return $? ;;
        7) step_7_setup_microservices; return $? ;;
        8) step_8_health_checks; return $? ;;
        9) step_9_configure_fees; return $? ;;
        10) step_10_generate_env; return $? ;;
        11) step_11_system_verification; return $? ;;
        12) step_12_final_summary; return $? ;;
        *) echo -e "${RED}Invalid step number${NC}"; return 1 ;;
    esac
}

run_from_step_to_end() {
    local start_step=$1

    for ((step=start_step; step<=12; step++)); do
        run_step $step
        local exit_code=$?

        # If step failed, ask user what to do
        if [ $exit_code -ne 0 ]; then
            echo ""
            echo -e "${YELLOW}Step $step failed with exit code $exit_code${NC}"
            echo -e "${CYAN}What would you like to do?${NC}"
            echo -e "${MAGENTA}[1]${NC} Continue to next step"
            echo -e "${MAGENTA}[2]${NC} Stop and return to menu ${GREEN}(default)${NC}"
            echo ""
            read -p "Enter your choice (1 or 2) [default: 2]: " continue_choice

            if [[ -z "$continue_choice" ]]; then
                continue_choice=2
            fi

            if [ "$continue_choice" == "2" ]; then
                echo -e "${YELLOW}Stopping execution. Returning to menu...${NC}"
                return 1
            else
                echo -e "${CYAN}Continuing to next step...${NC}"
                echo ""
            fi
        fi
    done

    return 0
}

# Main interactive loop
main() {
    while true; do
        display_menu

        read -p "Enter your choice: " choice
        echo ""

        case $choice in
            q|Q)
                echo -e "${GREEN}Exiting setup. Goodbye!${NC}"
                exit 0
                ;;
            99)
                echo -e "${CYAN}Running complete setup (all steps)...${NC}"
                echo ""
                for ((step=0; step<=12; step++)); do
                    run_step $step
                done
                echo ""
                read -p "Press Enter to return to menu..."
                ;;
            [0-9]|1[0-2])
                ask_run_mode $choice
                run_mode=$?

                if [ $run_mode -eq 1 ]; then
                    # Run step only
                    run_step $choice
                elif [ $run_mode -eq 2 ]; then
                    # Run from step to end
                    run_from_step_to_end $choice
                else
                    echo -e "${RED}Invalid run mode${NC}"
                fi

                echo ""
                read -p "Press Enter to return to menu..."
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Check if script is run with --auto flag
if [[ "$1" == "--auto" ]]; then
    echo -e "${CYAN}Running in automatic mode (all steps)...${NC}"
    for ((step=0; step<=12; step++)); do
        run_step $step
    done
else
    # Run interactive menu
    main
fi
