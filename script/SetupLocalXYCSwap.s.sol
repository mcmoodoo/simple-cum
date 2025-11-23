// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import { IAqua } from "aqua/src/interfaces/IAqua.sol";
import { Aqua } from "aqua/src/Aqua.sol";
import { XYCSwap } from "aqua/examples/apps/XYCSwap.sol";

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

contract SetupLocalXYCSwap is Script {
    function run() external {
        uint256 deployerPk = vm.envUint("DEPLOYER_PK");
        uint256 makerPk = vm.envOr("MAKER_PK", deployerPk);
        address maker = vm.addr(makerPk);

        // Optional preexisting addresses
        address aquaAddr = address(0);
        if (vm.envExists("AQUA_ADDR")) aquaAddr = vm.envAddress("AQUA_ADDR");
        address xycSwapAddr = address(0);
        if (vm.envExists("XYCSWAP_ADDR")) xycSwapAddr = vm.envAddress("XYCSWAP_ADDR");

        uint256 amount0 = vm.envOr("AMOUNT0", uint256(500 ether));
        uint256 amount1 = vm.envOr("AMOUNT1", uint256(500 ether));
        uint256 feeBps  = vm.envOr("FEE_BPS", uint256(30));
        uint256 salt    = vm.envOr("SALT", uint256(0));

        // Step 1: Deploy Aqua and XYCSwap if not provided
        vm.startBroadcast(deployerPk);
        IAqua aqua = IAqua(aquaAddr);
        if (aquaAddr == address(0)) {
            aqua = IAqua(address(new Aqua()));
            aquaAddr = address(aqua);
            console2.log("Deployed Aqua:", aquaAddr);
        } else {
            console2.log("Using existing Aqua:", aquaAddr);
        }

        XYCSwap app = XYCSwap(xycSwapAddr);
        if (xycSwapAddr == address(0)) {
            app = new XYCSwap(aqua);
            xycSwapAddr = address(app);
            console2.log("Deployed XYCSwap:", xycSwapAddr);
        } else {
            console2.log("Using existing XYCSwap:", xycSwapAddr);
        }

        // Step 2: Deploy two mock tokens and mint to maker and this script's address
        MiniERC20 token0 = new MiniERC20("TK0", "TK0");
        MiniERC20 token1 = new MiniERC20("TK1", "TK1");
        token0.mint(maker, amount0 * 2);
        token1.mint(maker, amount1 * 2);
        token0.mint(msg.sender, amount0);
        token1.mint(msg.sender, amount1);
        console2.log("Deployed token0:", address(token0));
        console2.log("Deployed token1:", address(token1));
        vm.stopBroadcast();

        // Step 3: Maker approves Aqua and ships strategy
        vm.startBroadcast(makerPk);
        token0.approve(aquaAddr, type(uint256).max);
        token1.approve(aquaAddr, type(uint256).max);

        XYCSwap.Strategy memory st = XYCSwap.Strategy({
            maker: maker,
            token0: address(token0),
            token1: address(token1),
            feeBps: feeBps,
            salt: bytes32(salt)
        });

        address[] memory toks = new address[](2);
        toks[0] = address(token0);
        toks[1] = address(token1);
        uint256[] memory amts = new uint256[](2);
        amts[0] = amount0;
        amts[1] = amount1;

        Aqua(aquaAddr).ship(xycSwapAddr, abi.encode(st), toks, amts);
        bytes32 strategyHash = keccak256(abi.encode(st));
        console2.log("Shipped strategyHash:");
        console2.logBytes32(strategyHash);
        vm.stopBroadcast();

        // Persist essential strategy data for takers
        vm.createDir("deployments", true);
        string memory root = "strategy";
        vm.serializeUint(root, "chainId", block.chainid);
        vm.serializeAddress(root, "aqua", aquaAddr);
        vm.serializeAddress(root, "xycSwap", xycSwapAddr);
        vm.serializeAddress(root, "maker", maker);
        vm.serializeAddress(root, "token0", address(token0));
        vm.serializeAddress(root, "token1", address(token1));
        vm.serializeUint(root, "feeBps", feeBps);
        vm.serializeBytes32(root, "salt", bytes32(salt));
        vm.serializeBytes32(root, "strategyHash", strategyHash);
        // write top-level first
        string memory top = vm.serializeString(root, "note", "XYCSwap strategy parameters");
        vm.writeJson(top, "deployments/strategy.json");
        // then write tokens/amounts subkeys
        string memory arr = "tokens";
        vm.serializeAddress(arr, "0", address(token0));
        string memory tokensJson = vm.serializeAddress(arr, "1", address(token1));
        vm.writeJson(tokensJson, "deployments/strategy.json", ".tokens");
        arr = "amounts";
        vm.serializeUint(arr, "0", amount0);
        string memory amountsJson = vm.serializeUint(arr, "1", amount1);
        vm.writeJson(amountsJson, "deployments/strategy.json", ".amounts");

        console2.log("Setup complete. Wrote deployments/strategy.json");
    }
}
