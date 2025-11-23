// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

contract MockERC20 {
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

contract DeployMocks is Script {
    function run() external {
        uint256 deployerPk = vm.envUint("DEPLOYER_PK");
        address mintTo = msg.sender;
        uint256 mintAmount = vm.envOr("MINT_AMOUNT", uint256(0));
        if (vm.envExists("MINT_TO")) mintTo = vm.envAddress("MINT_TO");

        vm.startBroadcast(deployerPk);
        MockERC20 mockUSDC = new MockERC20("mockUSDC", "USDC");
        MockERC20 mockUSDT = new MockERC20("mockUSDT", "USDT");
        MockERC20 mockDAI  = new MockERC20("mockDAI",  "DAI");

        if (mintAmount > 0) {
            mockUSDC.mint(mintTo, mintAmount);
            mockUSDT.mint(mintTo, mintAmount);
            mockDAI.mint(mintTo, mintAmount);
        }

        console2.log("mockUSDC:", address(mockUSDC));
        console2.log("mockUSDT:", address(mockUSDT));
        console2.log("mockDAI:",  address(mockDAI));
        vm.stopBroadcast();
    }
}
