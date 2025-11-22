// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import "forge-std/Test.sol";

import { Aqua } from "aqua/src/Aqua.sol";
import { IAqua } from "aqua/src/interfaces/IAqua.sol";
import { XYCSwap } from "aqua/examples/apps/XYCSwap.sol";
import { IXYCSwapCallback } from "aqua/examples/apps/interfaces/IXYCSwapCallback.sol";

contract MiniERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory n, string memory s) {
        name = n;
        symbol = s;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        uint256 fromBal = balanceOf[msg.sender];
        require(fromBal >= amount, "bal");
        unchecked {
            balanceOf[msg.sender] = fromBal - amount;
            balanceOf[to] += amount;
        }
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "allowance");
        uint256 fromBal = balanceOf[from];
        require(fromBal >= amount, "bal");
        unchecked {
            allowance[from][msg.sender] = allowed - amount;
            balanceOf[from] = fromBal - amount;
            balanceOf[to] += amount;
        }
        return true;
    }
}

contract AquaIntegrationTest is Test, IXYCSwapCallback {
    IAqua public AQUA;
    XYCSwap public app;
    MiniERC20 public token0;
    MiniERC20 public token1;

    address public maker = address(0x1);

    function setUp() public {
        // Deploy Aqua and XYCSwap app
        AQUA = IAqua(address(new Aqua()));
        app = new XYCSwap(AQUA);

        // Deploy and mint mock tokens
        token0 = new MiniERC20("TK0", "TK0");
        token1 = new MiniERC20("TK1", "TK1");

        token0.mint(maker, 1_000 ether);
        token1.mint(maker, 1_000 ether);
        token0.mint(address(this), 100 ether);
        token1.mint(address(this), 100 ether);

        // Maker approves Aqua once
        vm.prank(maker);
        token0.approve(address(AQUA), type(uint256).max);
        vm.prank(maker);
        token1.approve(address(AQUA), type(uint256).max);

        // Taker (this test contract) approves Aqua for push during callback
        token0.approve(address(AQUA), type(uint256).max);
        token1.approve(address(AQUA), type(uint256).max);
    }

    function test_swapExactIn_XYCSwap() public {
        // Ship strategy with initial balances
        XYCSwap.Strategy memory st = XYCSwap.Strategy({
            maker: maker,
            token0: address(token0),
            token1: address(token1),
            feeBps: 30,
            salt: bytes32(0)
        });

        address[] memory toks = new address[](2);
        toks[0] = address(token0);
        toks[1] = address(token1);
        uint256[] memory amts = new uint256[](2);
        amts[0] = 500 ether;
        amts[1] = 500 ether;

        vm.prank(maker);
        Aqua(address(AQUA)).ship(address(app), abi.encode(st), toks, amts);

        // Execute a swap: token0 -> token1, amountIn = 10 ether
        uint256 balBefore = token1.balanceOf(address(this));
        uint256 out = app.swapExactIn(st, true, 10 ether, 0, address(this), abi.encode(true));
        assertGt(out, 0);
        assertEq(token1.balanceOf(address(this)), balBefore + out);
    }

    // Taker callback: deposit tokenIn to maker via Aqua.push
    function xycSwapCallback(
        address tokenIn,
        address /* tokenOut */,
        uint256 amountIn,
        uint256 /* amountOut */,
        address maker_,
        address app_,
        bytes32 strategyHash,
        bytes calldata /* takerData */
    ) external override {
        // Ensure we hold enough tokenIn (test contract already minted/holds)
        // Approvals done in setUp; just push to Aqua
        AQUA.push(maker_, app_, strategyHash, tokenIn, amountIn);
    }
}
