default:
	@just --list
set shell := ["bash", "-cu"]
set dotenv-load := true

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
		--broadcast \
		--private-key "${DEPLOYER_PK:?DEPLOYER_PK required}" -vv

deploy-mocks-base-wallet:
	@forge script script/DeployMocks.s.sol:DeployMocks \
		--rpc-url "${INFURA_BASE_MAINNET_RPC:?INFURA_BASE_MAINNET_RPC required}" \
		--broadcast \
		--private-key "${DEPLOYER_PK:?DEPLOYER_PK required}" -vv
