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
# Taker EOA (anvil[1])
PK=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
TAKER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

if [[ "$DIRECTION" == "0-1" ]]; then
  ZERO_FOR_ONE=true
else
  ZERO_FOR_ONE=false
fi

# Strategy tuple: (maker, token0, token1, feeBps, salt)
STRATEGY="($MAKER,$TK0,$TK1,$FEE,$SALT)"

cast send "$TRADER" \
  "swapExactIn(address,(address,address,address,uint256,bytes32),bool,uint256,uint256,address)" \
  "$XYC" "$STRATEGY" $ZERO_FOR_ONE "$AMOUNT" 0 "$TAKER" \
  --rpc-url "$RPC" --private-key "$PK" -v
