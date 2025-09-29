// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Genesis721} from "../src/MyNFT.sol";
import {DeployGenesis721} from "../script/DeployMyNFT.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract TestGenesis721 is Test {
    HelperConfig helper;
    DeployGenesis721 deployer;
    Genesis721 genesis;

    uint256 public maxSupply = 4;
    uint256 public constant STARTING_USER_BALANCE = 3 ether;

    address holders = makeAddr("holders");

    function setUp() external {
        deployer = new DeployGenesis721();
        helper = new HelperConfig();

        (maxSupply,) = helper.activeNetworkConfig();

        genesis = deployer.run();

        vm.deal(holders, STARTING_USER_BALANCE);
    }

    function testGenesisSetCreatorAsContractOwner() public {
        assertEq(genesis.getContractOwner(), msg.sender);
    }
}
