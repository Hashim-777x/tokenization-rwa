// ./script/DeployDTsla.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {dTSLA} from "../src/dTSLA.sol";
import {console2} from "forge-std/console2.sol";

contract DeployDTsla is Script {
    // Contract implementation
    string constant alpacaMintSource = "./functions/sources/alpacaBalance.js";
    string constant alpacaRedeemSource = "";
    uint64 constant subId = 6337;

    function run() public {
       string memory mintSource = vm.readFile(alpacaMintSource);

        vm.startBroadcast();
        dTSLA dtsla = new dTSLA(mintSource, subId, alpacaRedeemSource);
        vm.stopBroadcast();
        console2.log("dTSLA deployed at:", address(dtsla));
    }
}
