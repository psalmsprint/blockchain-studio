// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DeployGenesis721} from "../../script/DeployMyNFT.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Genesis721} from "../../src/MyNFT.sol";

contract DeployGenesis721Test is Test {
    DeployGenesis721 deployer;
    HelperConfig helper;
    Genesis721 genesis;

    uint256 deployerKey;
    uint256 maxSupply = 4;

    function setUp() external {
        deployer = new DeployGenesis721();
        helper = new HelperConfig();

        (maxSupply, deployerKey) = helper.activeNetworkConfig();

        genesis = deployer.run();
    }

    function testContractNameIsConsistent() public view {
        assertEq(genesis.name(), "Genesis721");
    }

    function testContractSymbolIsConsistent() public view {
        assertEq(genesis.symbol(), "GEN");
    }

    function testContractMaxSupply() public view {
        assertEq(genesis.getMaxSupply(), maxSupply);
    }

    function testContractOwner() public view {
        address owner = vm.addr(deployerKey);

        assertEq(genesis.getContractOwner(), owner);
    }

    function testContractIsConsistent() public {
        genesis = deployer.run();

        assert(address(genesis) != address(0));
    }

    ///////////////
    /// Deploy ///
    /////////////

    function testDeploy() public {
        genesis = deployer.deploy();

        assert(address(genesis) != address(0));
    }
}
