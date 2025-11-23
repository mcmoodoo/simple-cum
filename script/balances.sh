#!/usr/bin/env bash
set -euo pipefail

RPC=http://127.0.0.1:8545
STRAT=deployments/strategy.json

MAKER=$(jq -r .maker "$STRAT")
TAKER=$(jq -r .taker "$STRAT")
TK0=$(jq -r .token0 "$STRAT")
TK1=$(jq -r .token1 "$STRAT")

printf "Maker: %s\nTaker: %s\nToken0: %s\nToken1: %s\n\n" "$MAKER" "$TAKER" "$TK0" "$TK1"

echo "Token0 balances:"
echo -n "  maker: "
cast call "$TK0" 'balanceOf(address)(uint256)' "$MAKER" --rpc-url "$RPC"
echo -n "  taker: "
cast call "$TK0" 'balanceOf(address)(uint256)' "$TAKER" --rpc-url "$RPC"

echo "\nToken1 balances:"
echo -n "  maker: "
cast call "$TK1" 'balanceOf(address)(uint256)' "$MAKER" --rpc-url "$RPC"
echo -n "  taker: "
cast call "$TK1" 'balanceOf(address)(uint256)' "$TAKER" --rpc-url "$RPC"
