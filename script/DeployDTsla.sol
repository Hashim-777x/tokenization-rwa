//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {dTSLA} from "../src/dTSLA.sol";
import {console2} from "forge-std/console2.sol";

contract DeployDTsla {
    // Contract implementation
    string constant alpacaMintSource = "./functions/sources/alpacaBalance.js";
    string constant alpacaRedeemSource = "";
    uint256 constant subId = 6337;

    function run() public {
       string memory mintSource = vm.readFile(alpacaMintSource);

        vm.startBroadcast();
        dTSLA dtsla = new dTSLA(alpacaMintSource, subId, alpacaRedeemSource);
        vm.stopBroadcast();
    }
}
