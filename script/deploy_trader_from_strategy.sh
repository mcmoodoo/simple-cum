#!/usr/bin/env bash
set -euo pipefail

AQUA=$(jq -r .aqua deployments/strategy.json)
if [[ -z "$AQUA" || "$AQUA" == "null" ]]; then
  echo "error: deployments/strategy.json missing .aqua" >&2
  exit 1
fi

RPC=http://127.0.0.1:8545
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

AQUA_ADDR="$AQUA" DEPLOYER_PK="$PK" forge script script/DeploySimpleTrader.s.sol:DeploySimpleTrader --rpc-url "$RPC" --broadcast -vv
