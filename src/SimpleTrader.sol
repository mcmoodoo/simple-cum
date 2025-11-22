// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IAqua } from "aqua/src/interfaces/IAqua.sol";
import { XYCSwap } from "aqua/examples/apps/XYCSwap.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IXYCSwapCallback } from "aqua/examples/apps/interfaces/IXYCSwapCallback.sol";

// Minimal trader that can initiate swaps against XYCSwap and satisfy the callback
contract SimpleTrader is IXYCSwapCallback {
    IAqua public immutable AQUA;

    constructor(IAqua aqua) {
        AQUA = aqua;
    }

    // Caller (EOA) must approve this contract to pull amountIn of tokenIn before calling
    function swapExactIn(
        XYCSwap app,
        XYCSwap.Strategy calldata strategy,
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) external returns (uint256 amountOut) {
        address tokenIn = zeroForOne ? strategy.token0 : strategy.token1;

        // Pull input tokens from caller to this contract and pre-approve Aqua for push
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(AQUA), amountIn);

        // takerData can optionally encode parameters; we pass direction for symmetry
        amountOut = app.swapExactIn(strategy, zeroForOne, amountIn, amountOutMin, recipient, abi.encode(zeroForOne));
    }

    // XYCSwap callback: complete the swap by pushing tokenIn to maker via Aqua
    function xycSwapCallback(
        address tokenIn,
        address /* tokenOut */,
        uint256 amountIn,
        uint256 /* amountOut */,
        address maker,
        address app,
        bytes32 strategyHash,
        bytes calldata /* takerData */
    ) external override {
        // This contract already holds tokenIn and approved Aqua; push to maker
        AQUA.push(maker, app, strategyHash, tokenIn, amountIn);
    }
}
