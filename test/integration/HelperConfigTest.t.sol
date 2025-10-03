// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    HelperConfig helper;
    uint256 constant ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 constant EXPECTED_MAX_SUPPLY = 4;
    uint256 constant DUMMY_KEY = 0x123;

    function testSepoliaConfigReturnsCorrectValues() public {
        vm.chainId(11155111);
        helper = new HelperConfig();

        (uint256 maxSupply, uint256 deployerKey) = helper.activeNetworkConfig();

        assertEq(maxSupply, EXPECTED_MAX_SUPPLY);
        assertTrue(deployerKey != 0);
    }

    function testMainnetConfigReturnsCorrectValues() public {
        vm.chainId(1);
        helper = new HelperConfig();

        (uint256 maxSupply, uint256 deployerKey) = helper.activeNetworkConfig();

        assertEq(maxSupply, EXPECTED_MAX_SUPPLY);
        assertTrue(deployerKey != 0);
    }

    function testAnvilConfigReturnsCorrectValues() public {
        vm.chainId(31337);
        helper = new HelperConfig();

        (uint256 maxSupply, uint256 deployerKey) = helper.activeNetworkConfig();

        assertEq(maxSupply, EXPECTED_MAX_SUPPLY);
        assertEq(deployerKey, ANVIL_KEY);
    }

    function testUnknownChainDefaultsToAnvilConfig() public {
        vm.chainId(999999);
        helper = new HelperConfig();

        (uint256 maxSupply, uint256 deployerKey) = helper.activeNetworkConfig();

        assertEq(maxSupply, EXPECTED_MAX_SUPPLY);
        assertEq(deployerKey, ANVIL_KEY);
    }

    function testSepoliaConfigFunction() public {
        helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.getSepoliaConfig();

        assertEq(config.maxSupply, EXPECTED_MAX_SUPPLY);
        assertTrue(config.deployerKey != 0);
    }

    function testMainnetConfigFunction() public {
        helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.getMainnetEthConfig();

        assertEq(config.maxSupply, EXPECTED_MAX_SUPPLY);
        assertTrue(config.deployerKey != 0);
    }

    function testAnvilConfigFunction() public {
        helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.anvilConfig();

        assertEq(config.maxSupply, EXPECTED_MAX_SUPPLY);
        assertEq(config.deployerKey, ANVIL_KEY);
    }

    function testActiveNetworkConfigIsSetInConstructor() public {
        helper = new HelperConfig();
        (uint256 maxSupply, uint256 deployerKey) = helper.activeNetworkConfig();

        assertEq(maxSupply, EXPECTED_MAX_SUPPLY);
        assertTrue(deployerKey == ANVIL_KEY || deployerKey != 0);
    }
}
