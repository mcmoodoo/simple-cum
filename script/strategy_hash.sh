#!/usr/bin/env bash
set -euo pipefail

STRAT_FILE="deployments/strategy.json"
MAKER=$(jq -r .maker "$STRAT_FILE")
TK0=$(jq -r .token0 "$STRAT_FILE")
TK1=$(jq -r .token1 "$STRAT_FILE")
FEE=$(jq -r .feeBps "$STRAT_FILE")
SALT=$(jq -r .salt "$STRAT_FILE")
REC=$(jq -r .strategyHash "$STRAT_FILE")

# Encode the struct as a single tuple and keccak it
ENC=$(cast abi-encode 'tuple(address,address,address,uint256,bytes32)' "$MAKER" "$TK0" "$TK1" "$FEE" "$SALT")
CALC=$(cast keccak "$ENC")

echo "Computed strategyHash: $CALC"
echo "Recorded strategyHash: $REC"
