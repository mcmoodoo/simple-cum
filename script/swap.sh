#!/usr/bin/env bash
set -euo pipefail

# Usage: swap.sh 0-1|1-0 <amount>
DIRECTION="${1:?direction 0-1|1-0 required}"
AMOUNT="${2:?amount required}"

STRAT_FILE="deployments/strategy.json"
ADDRS_FILE="deployments/addresses.json"

TRADER=$(jq -r .SimpleTrader "$ADDRS_FILE")
XYC=$(jq -r .xycSwap "$STRAT_FILE")
MAKER=$(jq -r .maker "$STRAT_FILE")
TK0=$(jq -r .token0 "$STRAT_FILE")
TK1=$(jq -r .token1 "$STRAT_FILE")
FEE=$(jq -r .feeBps "$STRAT_FILE")
SALT=$(jq -r .salt "$STRAT_FILE")

RPC=http://127.0.0.1:8545
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

if [[ "$DIRECTION" == "0-1" ]]; then
    ZERO_FOR_ONE=true
else
    ZERO_FOR_ONE=false
fi

# Strategy tuple: (maker, token0, token1, feeBps, salt)
STRATEGY="($MAKER,$TK0,$TK1,$FEE,$SALT)"

cast send "$TRADER" \
    "swapExactIn(address,(address,address,address,uint256,bytes32),bool,uint256,uint256,address)" \
    "$XYC" "$STRATEGY" $ZERO_FOR_ONE "$AMOUNT" 0 "$MAKER" \
    --rpc-url "$RPC" --private-key "$PK" -vvvv
