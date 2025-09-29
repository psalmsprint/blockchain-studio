// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    uint256 anvilKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    struct NetworkConfig {
        uint256 maxSupply;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = anvilConfig();
        }
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({maxSupply: 4, deployerKey: vm.envUint("PRIVATE_KEY")});

        return sepoliaConfig;
    }

    function getMainnetEthConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({maxSupply: 4, deployerKey: vm.envUint("PRIVATE_KEY")});
        return mainnetConfig;
    }

    function anvilConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory anvil = NetworkConfig({maxSupply: 4, deployerKey: anvilKey});

        return anvil;
    }
}
