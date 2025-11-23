#!/usr/bin/env bash
set -euo pipefail

# Usage: approve_token.sh 0|1 <amount>
TOKEN_INDEX="${1:?token index 0|1 required}"
AMOUNT="${2:?amount required}"

ADDR_FILE="deployments/addresses.json"
TRADER=$(jq -r .SimpleTrader "$ADDR_FILE")
if [[ "$TOKEN_INDEX" == "0" ]]; then
  TOKEN=$(jq -r .Token0 "$ADDR_FILE")
else
  TOKEN=$(jq -r .Token1 "$ADDR_FILE")
fi

PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC=http://127.0.0.1:8545

cast send "$TOKEN" "approve(address,uint256)" "$TRADER" "$AMOUNT" --rpc-url "$RPC" --private-key "$PK" -v
