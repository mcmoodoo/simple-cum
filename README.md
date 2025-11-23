## Overview

Foundry project demonstrating a minimal taker contract that integrates with the Aqua `XYCSwap` example app. It includes deploy/automation scripts, local setup with mock tokens, and mainnet Base recipes.

Key components:
- `SimpleTrader.sol`: executes `XYCSwap.swapExactIn` and implements the app’s callback to push funds via Aqua.
- Scripts to deploy Aqua, the `XYCSwap` app, and `SimpleTrader`, plus a one-shot local setup that ships a strategy and writes deployment metadata.
- Shell helpers for approvals, swaps, and basic checks.
- Optional Base deployment and verification recipes for simple mock ERC20s.

## Layout

- `src/`
  - `SimpleTrader.sol` — Minimal taker implementing `IXYCSwapCallback`; uses `AQUA.push` in the callback.
- `script/`
  - `DeployXYCSwap.s.sol` — Deploys `Aqua` (optional) and `XYCSwap`.
  - `DeploySimpleTrader.s.sol` — Deploys `Aqua` (optional) and `SimpleTrader`.
  - `SetupLocalXYCSwap.s.sol` — Local E2E setup: deploys `Aqua`, `XYCSwap`, two mock ERC20s, mints balances, ships a strategy, and writes `deployments/strategy.json`.
  - `DeployMocks.s.sol` — Deploys three open-mint `MockERC20` tokens (`USDC`, `USDT`, `DAI`) for onchain testing.
  - Shell: `approve_token.sh`, `swap.sh`, `balances.sh`, `allowance_check.sh`, `aqua_check.sh`, `strategy_hash.sh`, `export_deployments.sh`.
- `test/`
  - `AquaIntegration.t.sol` — Integration test covering `XYCSwap.swapExactIn` flow and callback push.
- `deployments/` — Generated artifacts like `addresses.json` and `strategy.json`.
- `broadcast/` — Foundry broadcast outputs (per-chain).
- `Justfile` — Common tasks for local and Base.
- `foundry.toml` — Uses solc 0.8.30, IR, high optimizer, remappings for aqua, OZ, and 1inch utils.

## Contracts

- `SimpleTrader`
  - Constructor takes `IAqua` address.
  - `swapExactIn(app, strategy, zeroForOne, amountIn, amountOutMin, recipient)` pulls `tokenIn`, approves Aqua, and calls the app.
  - `xycSwapCallback(...)` finalizes by calling `AQUA.push(...)` to deliver `tokenIn` to maker.

Note: Mock tokens in scripts allow anyone to mint; they are for testing only.

## Local workflow (anvil)

1) Start a local RPC at `http://127.0.0.1:8545` (e.g., `anvil`).
2) End-to-end setup:

```bash
just setup-local-xycswap
just export-deployments
```

3) Approve trader from taker EOA (anvil[1]) and swap:

```bash
just approve-token0 100e18
just approve-token1 100e18
just swap-0-1 10e18
```

4) Inspect:

```bash
just balances
just allowance 0
just aqua-check
just strategy-hash
```

## Base (mainnet) recipes

Environment:
- `INFURA_BASE_MAINNET_RPC` — Base RPC URL
- `DEPLOYER_PK` — Hex private key
- `ETHERSCAN_API_KEY` — For verification (BaseScan)

Deploy/verify:

```bash
just deploy-xycswap-base-wallet
just deploy-trader-base-wallet
just deploy-mocks-base-wallet   # includes --verify
```

### Base (8453) deployment addresses

```text
Chain: Base mainnet (8453)
- Aqua:     0x499943e74fb0ce105688beee8ef2abec5d936d31
- XYCSwap:  0xaa18a96e328385ea3c1aacda510d34e20c67932b
- mockUSDC: 0x85024ca2797a551dad5c1ac131617ffb59873338
- mockUSDT: 0xc8751a67b2233fe63b687544b81149e09e183864
- mockDAI:  0xaab44e159af76b332e49416037081cbb8d016ed5
```

Mint mocks (anyone can mint on these test tokens):

```bash
# Generic
just mint-mock <address> <to> <amount>

# Or via env shortcuts:
export MOCK_USDC=0x... ; export MOCK_USDT=0x... ; export MOCK_DAI=0x...
just mint-mock-usdc <to> <amount>
just mint-mock-usdt <to> <amount>
just mint-mock-dai  <to> <amount>
```

## Testing

```bash
forge test -vv
```

## Notes

- `SetupLocalXYCSwap.s.sol` persists a strategy snapshot to `deployments/strategy.json` and is used by shell helpers.
- `export_deployments.sh` collects broadcast outputs and writes `deployments/{addresses,deployments}.json`.
- The project relies on `aqua/` example `XYCSwap` (via remappings) and OpenZeppelin interfaces.
