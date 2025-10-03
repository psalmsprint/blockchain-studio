// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Genesis721} from "../src/MyNFT.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployGenesis721 is Script {
    function deploy() external returns (Genesis721) {
        uint256 maxSupply = 4;

        Genesis721 genesis = new Genesis721(maxSupply);

        return genesis;
    }

    function run() external returns (Genesis721) {
        HelperConfig helper = new HelperConfig();
        (uint256 maxSupply, uint256 deployerKey) = helper.activeNetworkConfig();

        if (deployerKey == 0x123) {
            deployerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }

        vm.startBroadcast(deployerKey);
        Genesis721 genesis = new Genesis721(maxSupply);
        vm.stopBroadcast();

        return genesis;
    }
}
