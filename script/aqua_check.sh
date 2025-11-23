#!/usr/bin/env bash
set -euo pipefail

RPC=http://127.0.0.1:8545
STRAT_FILE="deployments/strategy.json"

AQUA=$(jq -r .aqua "$STRAT_FILE")
APP=$(jq -r .xycSwap "$STRAT_FILE")
MAKER=$(jq -r .maker "$STRAT_FILE")
HASH=$(jq -r .strategyHash "$STRAT_FILE")
TK0=$(jq -r .token0 "$STRAT_FILE")
TK1=$(jq -r .token1 "$STRAT_FILE")

echo "Aqua:        $AQUA"
echo "App (XYC):  $APP"
echo "Maker:      $MAKER"
echo "Hash:       $HASH"
echo "Token0:     $TK0"
echo "Token1:     $TK1"

echo "\nrawBalances for token0:" 
cast call "$AQUA" 'rawBalances(address,address,bytes32,address)(uint248,uint8)' "$MAKER" "$APP" "$HASH" "$TK0" --rpc-url "$RPC"

echo "\nrawBalances for token1:"
cast call "$AQUA" 'rawBalances(address,address,bytes32,address)(uint248,uint8)' "$MAKER" "$APP" "$HASH" "$TK1" --rpc-url "$RPC"
