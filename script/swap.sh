#!/usr/bin/env bash
set -euo pipefail

# Usage: swap.sh 0-1|1-0 <amount>
DIRECTION="${1:?direction 0-1|1-0 required}"
AMOUNT="${2:?amount required}"

ADDR_FILE="deployments/addresses.json"
TRADER=$(jq -r .SimpleTrader "$ADDR_FILE")
XYC=$(jq -r .XYCSwap "$ADDR_FILE")
TK0=$(jq -r .Token0 "$ADDR_FILE")
TK1=$(jq -r .Token1 "$ADDR_FILE")
MAKER=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
RPC=http://127.0.0.1:8545
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

if [[ "$DIRECTION" == "0-1" ]]; then
  ZERO_FOR_ONE=true
else
  ZERO_FOR_ONE=false
fi

# bytes32 salt must be 32 bytes hex
SALT=0x0000000000000000000000000000000000000000000000000000000000000000
# Strategy tuple: (maker, token0, token1, feeBps, salt)
STRATEGY="($MAKER,$TK0,$TK1,30,$SALT)"

cast send "$TRADER" \
  "swapExactIn(address,(address,address,address,uint256,bytes32),bool,uint256,uint256,address)" \
  "$XYC" "$STRATEGY" $ZERO_FOR_ONE "$AMOUNT" 0 "$MAKER" \
  --rpc-url "$RPC" --private-key "$PK" -v
