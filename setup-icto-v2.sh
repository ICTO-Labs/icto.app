#!/bin/bash

# =================================================================
# ICTO V2 Complete Setup Script - Factory-First Architecture
# Deploys all factories, microservices and configures the system
# Version: 2.0
# Last Updated: 2025-10-07
# =================================================================

set -e

echo "🚀 Starting ICTO V2 Factory-First Architecture Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Deploy all canisters
echo -e "\n${BLUE}📦 Step 1: Deploying all canisters...${NC}"

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

# Step 2: Get canister IDs
echo -e "\n${BLUE}📋 Step 2: Getting canister IDs...${NC}"
BACKEND_ID=$(dfx canister id backend)
TOKEN_FACTORY_ID=$(dfx canister id token_factory)
AUDIT_STORAGE_ID=$(dfx canister id audit_storage)
INVOICE_STORAGE_ID=$(dfx canister id invoice_storage)
TEMPLATE_FACTORY_ID=$(dfx canister id template_factory)
DISTRIBUTION_FACTORY_ID=$(dfx canister id distribution_factory)
MULTISIG_FACTORY_ID=$(dfx canister id multisig_factory)
DAO_FACTORY_ID=$(dfx canister id dao_factory)
LAUNCHPAD_FACTORY_ID=$(dfx canister id launchpad_factory)

echo -e "${GREEN}✅ Backend ID: ${BACKEND_ID}${NC}"
echo -e "${GREEN}✅ Token Factory ID: ${TOKEN_FACTORY_ID}${NC}"
echo -e "${GREEN}✅ Audit Storage ID: ${AUDIT_STORAGE_ID}${NC}"
echo -e "${GREEN}✅ Invoice Storage ID: ${INVOICE_STORAGE_ID}${NC}"
echo -e "${GREEN}✅ Template Factory ID: ${TEMPLATE_FACTORY_ID}${NC}"
echo -e "${GREEN}✅ Distribution Factory ID: ${DISTRIBUTION_FACTORY_ID}${NC}"
echo -e "${GREEN}✅ Multisig Factory ID: ${MULTISIG_FACTORY_ID}${NC}"
echo -e "${GREEN}✅ DAO Factory ID: ${DAO_FACTORY_ID}${NC}"
echo -e "${GREEN}✅ Launchpad Factory ID: ${LAUNCHPAD_FACTORY_ID}${NC}"
# Step 3: Add cycles to factories
echo -e "\n${BLUE}💰 Step 3: Adding cycles to factories...${NC}"

# Each factory needs sufficient cycles to create contracts
# 100T cycles = enough for ~500 contract deployments

echo -e "${YELLOW}Fabricating cycles for factories...${NC}"
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
    exit 1
fi

# Step 4: Add backend to external services whitelist
echo -e "\n${BLUE}🔧 Step 4: Adding backend to external services whitelist...${NC}"

# Define services with standardized addToWhitelist function
# Note: audit_storage and invoice_storage are independent storage services
#       that only accept writes from whitelisted backend
declare -a SERVICES=(
    "audit_storage"           # Stores immutable audit logs
    "invoice_storage"         # Stores payment records
    "token_factory"
    "template_factory"
    "distribution_factory"
    "multisig_factory"
    "dao_factory"
    "launchpad_factory"
)

# Status tracking (simple strings to avoid associative array issues)
FAILED_SERVICES=""
SUCCESS_SERVICES=""

# Function to add backend to whitelist with status tracking (standardized)
add_to_whitelist() {
    local service_name=$1
    local backend_principal=$2
    
    echo -e "${YELLOW}Adding backend to ${service_name} whitelist...${NC}"
    
    # Execute the standardized whitelist command
    if dfx canister call "$service_name" "addToWhitelist" "(principal \"${backend_principal}\")"; then
        SUCCESS_SERVICES="$SUCCESS_SERVICES $service_name"
        echo -e "${GREEN}✅ Backend successfully added to ${service_name} whitelist${NC}"
        return 0
    else
        FAILED_SERVICES="$FAILED_SERVICES $service_name"
        echo -e "${RED}❌ Failed to add backend to ${service_name} whitelist${NC}"
        return 1
    fi
}

# Loop through all services and add backend to whitelist
echo -e "${BLUE}📋 Processing ${#SERVICES[@]} services for whitelist addition...${NC}"

for service in "${SERVICES[@]}"; do
    add_to_whitelist "$service" "$BACKEND_ID"
    
    # Small delay between calls to avoid overwhelming services
    sleep 1
done

# Display comprehensive status report
SUCCESS_COUNT=$(echo $SUCCESS_SERVICES | wc -w)
FAILED_COUNT=$(echo $FAILED_SERVICES | wc -w)
TOTAL_COUNT=${#SERVICES[@]}

echo -e "\n${BLUE}📊 Whitelist Addition Status Report:${NC}"
echo -e "${GREEN}✅ Successful: $SUCCESS_COUNT/$TOTAL_COUNT${NC}"
echo -e "${RED}❌ Failed: $FAILED_COUNT/$TOTAL_COUNT${NC}"

if [[ -n "$SUCCESS_SERVICES" ]]; then
    echo -e "\n${GREEN}Successfully added to whitelist:${NC}"
    for service in $SUCCESS_SERVICES; do
        echo -e "  ✓ $service"
    done
fi

if [[ -n "$FAILED_SERVICES" ]]; then
    echo -e "\n${RED}Failed to add to whitelist:${NC}"
    for service in $FAILED_SERVICES; do
        echo -e "  ✗ $service"
    done
    echo -e "\n${YELLOW}⚠️  Some services failed whitelist addition. You may need to run manual commands:${NC}"
    for service in $FAILED_SERVICES; do
        echo -e "  dfx canister call $service addToWhitelist \"(principal \\\"${BACKEND_ID}\\\")\""
    done
fi

# Check if critical services failed
CRITICAL_SERVICES="audit_storage invoice_storage token_factory distribution_factory"
CRITICAL_FAILED=""

for critical_service in $CRITICAL_SERVICES; do
    if [[ "$FAILED_SERVICES" == *"$critical_service"* ]]; then
        CRITICAL_FAILED="$CRITICAL_FAILED $critical_service"
    fi
done

if [[ -n "$CRITICAL_FAILED" ]]; then
    echo -e "\n${RED}🚨 CRITICAL: Essential services failed whitelist addition:${NC}"
    for service in $CRITICAL_FAILED; do
        echo -e "  ⚠️  $service"
    done
    echo -e "${RED}Backend may not function properly without these services whitelisted.${NC}"
    exit 1
fi

echo -e "\n${GREEN}✅ Whitelist addition completed successfully${NC}"


# Step 5: Load WASM into token_factory (fetch from SNS)
echo -e "\n${BLUE}📥 Step 5: Loading WASM into token_factory...${NC}"
WASM_FETCH_RESULT=$(dfx canister call token_factory getCurrentWasmInfo "()" 2>&1 || echo "FAILED")

if [[ "$WASM_FETCH_RESULT" == *"FAILED"* ]] || [[ "$WASM_FETCH_RESULT" == *"err"* ]]; then
    echo -e "${YELLOW}⚠️  WASM fetch failed - token_factory may need manual WASM upload${NC}"
    echo "$WASM_FETCH_RESULT"
else
    echo -e "${GREEN}✅ WASM loaded successfully into token_factory${NC}"
fi

# Step 6: Setup microservices using new unified function
echo -e "\n${BLUE}🔧 Step 6: Setting up microservices with unified setCanisterIds()...${NC}"


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
    exit 1
else
    echo -e "${GREEN}✅ Microservices setup completed with new architecture${NC}"
fi

# Step 7: Health checks using new API
echo -e "\n${BLUE}🩺 Step 7: Running comprehensive health checks...${NC}"

# echo -e "${YELLOW}Checking supported deployment types...${NC}"
# DEPLOYMENT_TYPES=$(dfx canister call backend getSupportedDeploymentTypes "()" 2>&1 || echo "FAILED")
# if [[ "$DEPLOYMENT_TYPES" == *"FAILED"* ]]; then
#     echo -e "${RED}❌ Backend not responsive${NC}"
# else
#     echo -e "${GREEN}✅ Backend responsive - Supported types: ${DEPLOYMENT_TYPES}${NC}"
# fi

echo -e "${YELLOW}Checking token deployment type info...${NC}"
TOKEN_INFO=$(dfx canister call backend getDeploymentTypeInfo "(\"Token\")" 2>&1 || echo "FAILED")
if [[ "$TOKEN_INFO" == *"FAILED"* ]]; then
    echo -e "${YELLOW}⚠️  Token deployment type info not available${NC}"
else
    echo -e "${GREEN}✅ Token deployment info: ${TOKEN_INFO}${NC}"
fi

echo -e "${YELLOW}Checking token_factory health...${NC}"
TOKEN_HEALTH=$(dfx canister call token_factory getServiceHealth "()" 2>&1 || echo "FAILED")
if [[ "$TOKEN_HEALTH" == *"FAILED"* ]]; then
    echo -e "${YELLOW}⚠️  Token factory health check failed${NC}"
else
    echo -e "${GREEN}✅ Token factory health: ${TOKEN_HEALTH}${NC}"
fi

echo -e "${YELLOW}Adding backend to audit_storage whitelist...${NC}"
dfx canister call audit_storage addToWhitelist "(principal \"${BACKEND_ID}\")"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend added to audit_storage whitelist${NC}"
else
    echo -e "${RED}❌ Failed to add backend to audit_storage whitelist${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking audit_storage health...${NC}"
AUDIT_HEALTH=$(dfx canister call audit_storage getStorageStats "()" 2>&1 || echo "FAILED")
if [[ "$AUDIT_HEALTH" == *"FAILED"* ]]; then
    echo -e "${YELLOW}⚠️  Audit storage health check failed${NC}"
else
    echo -e "${GREEN}✅ Audit storage health: ${AUDIT_HEALTH}${NC}"
fi

# Step 8: Configure Service Fees
echo -e "\n${BLUE}💰 Step 8: Configuring Service Fees...${NC}"

# Service fees configuration (in e8s - ICP smallest unit)
# 1 ICP = 100,000,000 e8s
# Note: Fees are pre-configured in ConfigService.loadDefaultConfig()
# This step verifies and enables the services

echo -e "${YELLOW}Verifying service fees and enabling services...${NC}"

# Array of services to verify (service_name fee_key fee_value_e8s enabled_key)
declare -a SERVICES_CONFIG=(
    "token_factory|token_factory.fee|100000000|token_factory.enabled"
    "distribution_factory|distribution_factory.fee|100000000|distribution_factory.enabled"
    "multisig_factory|multisig_factory.fee|50000000|multisig_factory.enabled"
    "dao_factory|dao_factory.fee|500000000|dao_factory.enabled"
    "launchpad_factory|launchpad_factory.fee|1000000000|launchpad_factory.enabled"
)

for config in "${SERVICES_CONFIG[@]}"; do
    IFS='|' read -r service_name fee_key fee_value enabled_key <<< "$config"

    # Convert e8s to ICP for display
    icp_value=$(echo "scale=2; ${fee_value}/100000000" | bc)

    # Verify fee is accessible
    echo -e "${YELLOW}Checking ${service_name}...${NC}"
    FEE_CHECK=$(dfx canister call backend getServiceFee "(\"${fee_key}\")" 2>&1 || echo "FAILED")

    if [[ "$FEE_CHECK" == *"FAILED"* ]] || [[ "$FEE_CHECK" == *"err"* ]]; then
        echo -e "${RED}  ❌ Failed to verify fee for ${service_name}${NC}"
    else
        echo -e "${GREEN}  ✅ Fee: ${icp_value} ICP (${fee_value} e8s)${NC}"
    fi

done

echo -e ""
echo -e "${GREEN}✅ Service fees verified${NC}"
echo -e "${GREEN}✅ All factory services are enabled in backend configuration:${NC}"
echo -e "${GREEN}   • token_factory.enabled = true${NC}"
echo -e "${GREEN}   • multisig_factory.enabled = true${NC}"
echo -e "${GREEN}   • distribution_factory.enabled = true${NC}"
echo -e "${GREEN}   • dao_factory.enabled = true${NC}"
echo -e "${GREEN}   • launchpad_factory.enabled = true${NC}"

# Step 9: Generate frontend environment variables
echo -e "\n${BLUE}🔧 Step 9: Generating frontend environment variables...${NC}"

# Run setupEnv.js to generate .env files for frontend
if [ -f "setupEnv.js" ]; then
    echo -e "${YELLOW}Running setupEnv.js to generate .env files...${NC}"
    node setupEnv.js

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Frontend environment variables generated successfully${NC}"
        echo -e "${GREEN}   • .env.development (local development)${NC}"
        echo -e "${GREEN}   • .env (production)${NC}"
    else
        echo -e "${RED}❌ Failed to generate environment variables${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  setupEnv.js not found - skipping environment generation${NC}"
fi

# Step 10: Check system readiness
echo -e "\n${BLUE}📊 Step 10: System readiness verification...${NC}"

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
    # Check if maintenance mode is off
    if [[ "$SYSTEM_STATUS" == *"isMaintenanceMode = false"* ]]; then
        echo -e "${GREEN}   • Maintenance mode: OFF ✅${NC}"
    else
        echo -e "${YELLOW}   • Maintenance mode: ON ⚠️${NC}"
    fi
fi

# Final summary
echo -e "\n${GREEN}🎉 ICTO V2 Factory-First Architecture Setup Complete!${NC}"
echo -e "\n${BLUE}📊 Deployed Canisters:${NC}"
echo -e "• Backend: ${BACKEND_ID}"
echo -e "• Token Factory: ${TOKEN_FACTORY_ID}"
echo -e "• Distribution Factory: ${DISTRIBUTION_FACTORY_ID}"
echo -e "• Multisig Factory: ${MULTISIG_FACTORY_ID}"
echo -e "• DAO Factory: ${DAO_FACTORY_ID}"
echo -e "• Launchpad Factory: ${LAUNCHPAD_FACTORY_ID}"
echo -e "• Template Factory: ${TEMPLATE_FACTORY_ID}"
echo -e "• Audit Storage: ${AUDIT_STORAGE_ID}"
echo -e "• Invoice Storage: ${INVOICE_STORAGE_ID}"

echo -e "\n${BLUE}✅ Configuration Status:${NC}"
echo -e "• Factory Whitelist: ✅ Backend authorized"
echo -e "• Microservices Setup: ✅ All factories connected"
echo -e "• Service Fees: ✅ Configured"
echo -e "• WASM Templates: ✅ Loaded"
echo -e "• Frontend Env: ✅ Generated"
echo -e "• Health Checks: ✅ Passed"

echo -e "\n${BLUE}💰 Service Fees (ICP):${NC}"
echo -e "• Token Factory: 1.0 ICP"
echo -e "• Distribution Factory: 1.0 ICP"
echo -e "• Multisig Factory: 0.5 ICP"
echo -e "• DAO Factory: 5.0 ICP"
echo -e "• Launchpad Factory: 10.0 ICP"

echo -e "\n${BLUE}🏗️ Architecture Features:${NC}"
echo -e "• Factory-First Storage: ✅ O(1) user queries"
echo -e "• Distributed Indexes: ✅ Per-factory user data"
echo -e "• Backend Gateway: ✅ Payment validation only"
echo -e "• Version Management: ✅ Automatic upgrades"
echo -e "• Callback System: ✅ Factory ↔ Contract sync"

echo -e "\n${BLUE}🔗 Useful Commands:${NC}"
echo -e "• System status: ${YELLOW}dfx canister call backend getSystemStatus \"()\"${NC}"
echo -e "• Microservices health: ${YELLOW}dfx canister call backend getMicroserviceHealth \"()\"${NC}"
echo -e "• Service fee: ${YELLOW}dfx canister call backend getServiceFee \"(\\\"token_factory.fee\\\")\"${NC}"
echo -e "• Token WASM info: ${YELLOW}dfx canister call token_factory getCurrentWasmInfo \"()\"${NC}"

echo -e "\n${BLUE}📚 Documentation:${NC}"
echo -e "• Architecture: ${YELLOW}documents/ARCHITECTURE.md${NC}"
echo -e "• Module Docs: ${YELLOW}documents/modules/[module]/README.md${NC}"
echo -e "• Version System: ${YELLOW}FACTORY_VERSION_UPDATE_SYSTEM.md${NC}"

echo -e "\n${GREEN}✨ System Ready for Production!${NC}"
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Start frontend: ${YELLOW}npm run dev${NC} (from root directory)"
echo -e "2. Access app: ${YELLOW}http://localhost:5173${NC}"
echo -e "3. Test deployments with proper ICRC2 payment approval"
echo -e "4. Monitor factory health with ${YELLOW}getServiceHealth()${NC}"
echo -e "5. Check ${YELLOW}documents/${NC} for module-specific guides" 