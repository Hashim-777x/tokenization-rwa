//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {dTSLA} from "../src/dTSLA.sol";

contract DeployDTsla {
    // Contract implementation
    string constant alpacaMintSource = "./functions/sources/alpacaBalance.js";
    string constant alpacaRedeemSource = "./functions/sources/alpacaRedeem.js";
}
