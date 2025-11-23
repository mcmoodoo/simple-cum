set shell := ["bash", "-cu"]
set dotenv-load := true

default:
	@just --list

deploy-xycswap:
	@DEPLOYER_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 forge script script/DeployXYCSwap.s.sol:DeployXYCSwap --rpc-url http://127.0.0.1:8545 --broadcast -vv

setup-local-xycswap:
	@DEPLOYER_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 forge script script/SetupLocalXYCSwap.s.sol:SetupLocalXYCSwap --rpc-url http://127.0.0.1:8545 --broadcast -vv

deploy-trader:
	@DEPLOYER_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 forge script script/DeploySimpleTrader.s.sol:DeploySimpleTrader --rpc-url http://127.0.0.1:8545 --broadcast -vv

deploy-trader-from-strategy:
	@bash script/deploy_trader_from_strategy.sh

export-deployments:
	@bash script/export_deployments.sh

approve-token0 amount:
	@bash script/approve_token.sh 0 {{amount}}

approve-token1 amount:
	@bash script/approve_token.sh 1 {{amount}}

swap-0-1 amount:
	@bash script/swap.sh 0-1 {{amount}}

swap-1-0 amount:
	@bash script/swap.sh 1-0 {{amount}}

setup-deploy-approve:
	@just setup-local-xycswap
	@just deploy-trader-from-strategy
	@just export-deployments
	@just approve-token0 1000000000000000000 
	@just approve-token1 1000000000000000000 

strategy-hash:
	@bash script/strategy_hash.sh

aqua-check:
	@bash script/aqua_check.sh

allowance token_index:
	@bash script/allowance_check.sh {{token_index}}

balances:
	@bash script/balances.sh

# ========= Base mainnet deployments (requires ENV: INFURA_BASE_MAINNET_RPC, DEPLOYER_PK) =========

deploy-xycswap-base-wallet:
	@AQUA_ADDR=0x499943e74fb0ce105688beee8ef2abec5d936d31 \
	forge script script/DeployXYCSwap.s.sol:DeployXYCSwap \
		--rpc-url "${INFURA_BASE_MAINNET_RPC:?INFURA_BASE_MAINNET_RPC required}" \
		--broadcast \
		--private-key "${DEPLOYER_PK:?DEPLOYER_PK required}" -vv

deploy-trader-base-wallet:
	@AQUA_ADDR=0x499943e74fb0ce105688beee8ef2abec5d936d31 \
	forge script script/DeploySimpleTrader.s.sol:DeploySimpleTrader \
		--rpc-url "${INFURA_BASE_MAINNET_RPC:?INFURA_BASE_MAINNET_RPC required}" \
		--broadcast --verify \
		--etherscan-api-key "${ETHERSCAN_API_KEY:?ETHERSCAN_API_KEY required}" \
		--private-key "${DEPLOYER_PK:?DEPLOYER_PK required}" -vv

deploy-mocks-base-wallet:
	@forge script script/DeployMocks.s.sol:DeployMocks \
		--rpc-url "${INFURA_BASE_MAINNET_RPC:?INFURA_BASE_MAINNET_RPC required}" \
		--broadcast --verify \
		--etherscan-api-key "${ETHERSCAN_API_KEY:?ETHERSCAN_API_KEY required}" \
		--private-key "${DEPLOYER_PK:?DEPLOYER_PK required}" -vv

# ========= Mocks: simple mint/verify helpers (no Python) =========
#
# Usage:
#   just mint-mock <address> <to> <amount>
#
mint-mock address to amount:
	@cast send "{{address}}" "mint(address,uint256)" "{{to}}" "{{amount}}" \
		--rpc-url "${INFURA_BASE_MAINNET_RPC:?INFURA_BASE_MAINNET_RPC required}" \
		--private-key "${DEPLOYER_PK:?DEPLOYER_PK required}"

# Convenience wrappers using env addresses (optional):
#   export MOCK_USDC=0x...
#   export MOCK_USDT=0x...
#   export MOCK_DAI=0x...
mint-mock-usdc to amount:
	@cast send "${MOCK_USDC:?MOCK_USDC required}" "mint(address,uint256)" "{{to}}" "{{amount}}" \
		--rpc-url "${INFURA_BASE_MAINNET_RPC:?INFURA_BASE_MAINNET_RPC required}" \
		--private-key "${DEPLOYER_PK:?DEPLOYER_PK required}"

mint-mock-usdt to amount:
	@cast send "${MOCK_USDT:?MOCK_USDT required}" "mint(address,uint256)" "{{to}}" "{{amount}}" \
		--rpc-url "${INFURA_BASE_MAINNET_RPC:?INFURA_BASE_MAINNET_RPC required}" \
		--private-key "${DEPLOYER_PK:?DEPLOYER_PK required}"

mint-mock-dai to amount:
	@cast send "${MOCK_DAI:?MOCK_DAI required}" "mint(address,uint256)" "{{to}}" "{{amount}}" \
		--rpc-url "${INFURA_BASE_MAINNET_RPC:?INFURA_BASE_MAINNET_RPC required}" \
		--private-key "${DEPLOYER_PK:?DEPLOYER_PK required}"

# Manual verification helper (deploy already uses --verify):
#   just verify-mock <address> <name> <symbol>
verify-mock address name symbol:
	@forge verify-contract --chain-id 8453 \
		--etherscan-api-key "${ETHERSCAN_API_KEY:?ETHERSCAN_API_KEY required}" \
		"{{address}}" script/DeployMocks.s.sol:MockERC20 \
		--constructor-args "$(cast abi-encode "constructor(string,string)" "{{name}}" "{{symbol}}")"
