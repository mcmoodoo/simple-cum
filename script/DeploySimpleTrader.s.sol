// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import { IAqua } from "aqua/src/interfaces/IAqua.sol";
import { Aqua } from "aqua/src/Aqua.sol";
import { SimpleTrader } from "src/SimpleTrader.sol";

contract DeploySimpleTrader is Script {
    function run() external {
        uint256 deployerPk = vm.envUint("DEPLOYER_PK");

        address aquaAddr = vm.envOr("AQUA_ADDR", address(0));

        vm.startBroadcast(deployerPk);

        IAqua aqua;
        if (aquaAddr == address(0)) {
            aqua = IAqua(address(new Aqua()));
            console2.log("Deployed Aqua:", address(aqua));
        } else {
            aqua = IAqua(aquaAddr);
            console2.log("Using existing Aqua:", aquaAddr);
        }

        SimpleTrader trader = new SimpleTrader(aqua);
        console2.log("Deployed SimpleTrader:", address(trader));

        vm.stopBroadcast();
    }
}
