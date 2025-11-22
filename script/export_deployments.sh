#!/usr/bin/env bash
set -euo pipefail

CHAIN_ID=31337
mkdir -p deployments
TMP=$(mktemp)

# Collect created contract names and addresses from latest broadcasts
for f in \
  broadcast/DeployXYCSwap.s.sol/${CHAIN_ID}/run-latest.json \
  broadcast/SetupLocalXYCSwap.s.sol/${CHAIN_ID}/run-latest.json \
  broadcast/DeploySimpleTrader.s.sol/${CHAIN_ID}/run-latest.json
do
  [ -f "$f" ] || continue
  jq -r '
    [ range(0; (.transactions|length)) as $i |
      {name: .transactions[$i].contractName,
       addr: .receipts[$i].contractAddress,
       typ: .transactions[$i].transactionType}
    ]
    | map(select(.typ=="CREATE" and .name!=null and .addr!=null))
    | .[]
    | "\(.name) \(.addr)"' "$f" >> "$TMP"
done

# Parse into variables (choose first two MiniERC20 as Token0/Token1)
aqua=""; xyc=""; trader=""; tok0=""; tok1="";
while read -r name addr; do
  case "$name" in
    Aqua) aqua="$addr" ;;
    XYCSwap) xyc="$addr" ;;
    SimpleTrader) trader="$addr" ;;
    MiniERC20)
      if [[ -z "$tok0" ]]; then tok0="$addr"; elif [[ -z "$tok1" ]]; then tok1="$addr"; fi ;;
  esac
done < "$TMP"
rm -f "$TMP"

# Helper to read ABI from out artifacts
read_abi() {
  local cn="$1"
  local p
  p=$(find out -type f -name "${cn}.json" | head -n1 || true)
  if [[ -n "$p" ]]; then jq '.abi' "$p"; else echo '[]'; fi
}

aquaAbi=$(read_abi Aqua)
xycAbi=$(read_abi XYCSwap)
traderAbi=$(read_abi SimpleTrader)
miniAbi=$(read_abi MiniERC20)

# addresses.json
jq -n \
  --argjson chainId "$CHAIN_ID" \
  --arg aqua "$aqua" \
  --arg xyc "$xyc" \
  --arg trader "$trader" \
  --arg token0 "$tok0" \
  --arg token1 "$tok1" \
  '{chainId: $chainId, Aqua: $aqua, XYCSwap: $xyc, SimpleTrader: $trader, Token0: $token0, Token1: $token1}' \
  > deployments/addresses.json

# deployments.json with ABIs
jq -n \
  --argjson chainId "$CHAIN_ID" \
  --arg aqua "$aqua" --argjson aquaAbi "$aquaAbi" \
  --arg xyc "$xyc" --argjson xycAbi "$xycAbi" \
  --arg trader "$trader" --argjson traderAbi "$traderAbi" \
  --arg token0 "$tok0" --arg token1 "$tok1" --argjson miniAbi "$miniAbi" \
  '{
    chainId: $chainId,
    Aqua: {address: $aqua, abi: $aquaAbi},
    XYCSwap: {address: $xyc, abi: $xycAbi},
    SimpleTrader: {address: $trader, abi: $traderAbi},
    Token0: {address: $token0, abi: $miniAbi},
    Token1: {address: $token1, abi: $miniAbi}
  }' > deployments/deployments.json

echo "Wrote deployments/deployments.json and deployments/addresses.json"
