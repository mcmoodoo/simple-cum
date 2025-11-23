default:
	@just --list
set shell := ["bash", "-cu"]

deploy-xycswap:
	@DEPLOYER_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 forge script script/DeployXYCSwap.s.sol:DeployXYCSwap --rpc-url http://127.0.0.1:8545 --broadcast -vv

setup-local-xycswap:
	@DEPLOYER_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 forge script script/SetupLocalXYCSwap.s.sol:SetupLocalXYCSwap --rpc-url http://127.0.0.1:8545 --broadcast -vv

deploy-trader:
	@DEPLOYER_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 forge script script/DeploySimpleTrader.s.sol:DeploySimpleTrader --rpc-url http://127.0.0.1:8545 --broadcast -vv

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
	@just deploy-trader
	@just export-deployments
	@just approve-token0 1000000000000000000 
	@just approve-token1 1000000000000000000 

strategy-hash:
	@bash script/strategy_hash.sh

aqua-check:
	@bash script/aqua_check.sh

allowance token_index:
	@bash script/allowance_check.sh {{token_index}}
