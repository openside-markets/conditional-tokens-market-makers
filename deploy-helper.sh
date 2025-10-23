#!/bin/bash

# Deployment Helper Script for Conditional Tokens Contracts
# Usage: ./deploy-helper.sh [command] [network]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTRACT_NAME="ConditionalTokens"
FLATTENED_FILE="ConditionalTokens_flattened.sol"

# Helper functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if PRIVATE_KEY is set
check_private_key() {
    if [ -z "$PRIVATE_KEY" ]; then
        print_error "PRIVATE_KEY environment variable is not set"
        echo "Please set it with: export PRIVATE_KEY=0x..."
        exit 1
    fi
    print_success "PRIVATE_KEY is set"
}

# Compile contracts
compile_contracts() {
    print_header "Compiling Contracts"
    npm run compile
    print_success "Contracts compiled successfully"
}

# Deploy to network
deploy_to_network() {
    local network=$1
    if [ -z "$network" ]; then
        print_error "Network name is required"
        echo "Usage: $0 deploy [network_name]"
        echo "Available networks: base_sepolia, base_mainnet"
        exit 1
    fi
    
    print_header "Deploying to $network"
    check_private_key
    
    echo "Deploying ConditionalTokens contract to $network..."
    PRIVATE_KEY=$PRIVATE_KEY truffle migrate --network $network
    
    print_success "Deployment completed!"
    
    # Update networks.json
    print_header "Updating networks.json"
    npm run injectnetinfo
    print_success "networks.json updated"
    
    # Show deployment info
    print_header "Deployment Information"
    npm run networks
}

# Flatten contract for verification
flatten_contract() {
    print_header "Flattening Contract"
    
    if ! command -v truffle-flattener &> /dev/null; then
        print_warning "truffle-flattener not found, installing..."
        npm install -g truffle-flattener
    fi
    
    npx truffle-flattener contracts/ConditionalTokens.sol > $FLATTENED_FILE
    print_success "Contract flattened to $FLATTENED_FILE"
    
    # Show file info
    echo "File size: $(wc -c < $FLATTENED_FILE) bytes"
    echo "Lines: $(wc -l < $FLATTENED_FILE)"
}

# Get compiler version
get_compiler_version() {
    print_header "Compiler Information"
    
    if [ ! -f "build/contracts/ConditionalTokens.json" ]; then
        print_error "Build artifacts not found. Run 'npm run compile' first."
        exit 1
    fi
    
    local version=$(grep -A 2 '"compiler"' build/contracts/ConditionalTokens.json | grep '"version"' | cut -d'"' -f4)
    echo "Compiler Version: $version"
    
    # Show contract addresses for each network
    echo ""
    echo "Contract Addresses:"
    npm run networks
}

# Verify contract on BaseScan
verify_contract() {
    local network=$1
    local contract_address=""
    
    case $network in
        "base_sepolia")
            contract_address="0xb29d3bb7c57bc2e8f72a516cd16e998ac0a05b1d"
            echo "Base Sepolia Contract: $contract_address"
            echo "Verification URL: https://sepolia.basescan.org/verifyContract"
            ;;
        "base_mainnet")
            print_warning "Base Mainnet contract not deployed yet"
            echo "Deploy first with: $0 deploy base_mainnet"
            exit 1
            ;;
        *)
            print_error "Unknown network: $network"
            echo "Available networks: base_sepolia, base_mainnet"
            exit 1
            ;;
    esac
    
    print_header "Contract Verification Info"
    echo "Contract Address: $contract_address"
    echo "Contract Name: ConditionalTokens"
    echo "Compiler: v0.5.10+commit.5a6ea5b1.Emscripten.clang"
    echo "Optimization: Yes (enabled)"
    echo "Runs: 200"
    echo "License: LGPL-3.0"
    echo ""
    
    if [ ! -f "$FLATTENED_FILE" ]; then
        print_warning "Flattened contract not found. Flattening now..."
        flatten_contract
    fi
    
    echo "Flattened contract ready: $FLATTENED_FILE"
    echo ""
    echo "Manual verification steps:"
    echo "1. Go to the verification URL above"
    echo "2. Enter contract address: $contract_address"
    echo "3. Select 'Solidity (Single file)'"
    echo "4. Enter compiler version: v0.5.10+commit.5a6ea5b1.Emscripten.clang"
    echo "5. Select license: LGPL-3.0"
    echo "6. Paste content from $FLATTENED_FILE"
    echo "7. Complete CAPTCHA and submit"
}

# Show help
show_help() {
    echo "Deployment Helper Script for Conditional Tokens Contracts"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  compile                    Compile contracts"
    echo "  deploy [network]          Deploy to specified network"
    echo "  flatten                   Flatten contract for verification"
    echo "  verify [network]          Show verification instructions"
    echo "  info                      Show compiler and deployment info"
    echo "  help                      Show this help message"
    echo ""
    echo "Networks:"
    echo "  base_sepolia              Base Sepolia testnet"
    echo "  base_mainnet              Base Mainnet"
    echo ""
    echo "Examples:"
    echo "  $0 compile"
    echo "  $0 deploy base_sepolia"
    echo "  $0 flatten"
    echo "  $0 verify base_sepolia"
    echo "  $0 info"
    echo ""
    echo "Environment Variables:"
    echo "  PRIVATE_KEY               Private key for deployment (required)"
    echo ""
    echo "Prerequisites:"
    echo "  - Node.js and npm installed"
    echo "  - Truffle installed globally"
    echo "  - PRIVATE_KEY environment variable set"
}

# Main script logic
case $1 in
    "compile")
        compile_contracts
        ;;
    "deploy")
        deploy_to_network $2
        ;;
    "flatten")
        flatten_contract
        ;;
    "verify")
        verify_contract $2
        ;;
    "info")
        get_compiler_version
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
