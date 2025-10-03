// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC721TokenReceiver} from "forge-std/interfaces/IERC721.sol";

contract GoodReceiver is IERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
