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
