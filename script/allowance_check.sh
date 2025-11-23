#!/usr/bin/env bash
set -euo pipefail

# Usage: allowance_check.sh 0|1
IDX="${1:?token index 0|1 required}"
ADDRS="deployments/addresses.json"
STRAT="deployments/strategy.json"

TRADER=$(jq -r .SimpleTrader "$ADDRS")
TAKER=$(jq -r .taker "$STRAT")
if [[ "$IDX" == "0" ]]; then
  TOK=$(jq -r .token0 "$STRAT")
else
  TOK=$(jq -r .token1 "$STRAT")
fi

RPC=http://127.0.0.1:8545

echo "Token:   $TOK"
echo "Taker:   $TAKER"
echo "Spender: $TRADER (Trader)"
cast call "$TOK" "allowance(address,address)(uint256)" "$TAKER" "$TRADER" --rpc-url "$RPC"
