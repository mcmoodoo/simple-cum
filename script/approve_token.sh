#!/usr/bin/env bash
set -euo pipefail

# Usage: approve_token.sh 0|1 <amount>
TOKEN_INDEX="${1:?token index 0|1 required}"
AMOUNT="${2:?amount required}"

ADDR_FILE="deployments/addresses.json"
STRAT_FILE="deployments/strategy.json"
TRADER=$(jq -r .SimpleTrader "$ADDR_FILE")
if [[ "$TOKEN_INDEX" == "0" ]]; then
  TOKEN=$(jq -r .token0 "$STRAT_FILE")
else
  TOKEN=$(jq -r .token1 "$STRAT_FILE")
fi

# Taker EOA (anvil[1])
PK=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
RPC=http://127.0.0.1:8545

cast send "$TOKEN" "approve(address,uint256)" "$TRADER" "$AMOUNT" --rpc-url "$RPC" --private-key "$PK" -v
