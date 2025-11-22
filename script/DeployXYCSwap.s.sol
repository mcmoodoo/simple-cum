// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import { IAqua } from "aqua/src/interfaces/IAqua.sol";
import { Aqua } from "aqua/src/Aqua.sol";
import { XYCSwap } from "aqua/examples/apps/XYCSwap.sol";

contract DeployXYCSwap is Script {
    function run() external {
        uint256 deployerPk = vm.envUint("DEPLOYER_PK");

        address aquaAddr = address(0);
        if (vm.envExists("AQUA_ADDR")) {
            aquaAddr = vm.envAddress("AQUA_ADDR");
        }

        vm.startBroadcast(deployerPk);

        IAqua aqua = IAqua(aquaAddr);
        if (aquaAddr == address(0)) {
            aqua = IAqua(address(new Aqua()));
            console2.log("Deployed Aqua:", address(aqua));
        } else {
            console2.log("Using existing Aqua:", aquaAddr);
        }

        XYCSwap app = new XYCSwap(aqua);
        console2.log("Deployed XYCSwap:", address(app));

        vm.stopBroadcast();
    }
}
