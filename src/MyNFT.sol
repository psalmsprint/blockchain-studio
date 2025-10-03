// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC721TokenReceiver} from "forge-std/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error Genesis721__InvalidAddress();
error Genesis721__SenderCantBeOperator();
error Genesis721__TokenIdExisted();
error Genesis721__IsPaused();
error Genesis721__IsUnPaused();
error Genesis721__TransferFailed();
error Genesis721__UnAuthorised();
error Genesis721__ContractIsPaused();
error Genesis721__NoBalance();
error Genesis721__MintedOut();
error Genesis721__NoneExistedTokenId();
error Genesis721__InvalidTokenId();

contract Genesis721 {
    using Strings for uint256;

    bool s_pause;

    string baseUri = "ipfs://bafybeihqrz6j6rqravxrnql4g7a5mwnwr3o5mwof744mx6hmztvxm3sff4/";

    address private immutable i_owner;
    uint256 private immutable i_maxSupply;

    uint256 private s_nextTokenId = 1;
    uint256 private s_totalMinted;
    uint256 private s_burned;

    mapping(address => uint256) private s_balance;
    mapping(uint256 => address) private s_owner;
    mapping(uint256 => address) private s_approvals;
    mapping(address => mapping(address => bool)) s_operatorApproval;

    event Transfer(address indexed sender, address indexed receiver, uint256 tokenId);
    event Approval(address indexed sender, address indexed approved, uint256 tokenId);
    event ApprovalForAll(address indexed sender, address indexed operator, bool approved);

    constructor(uint256 maxSupply) {
        i_owner = msg.sender;
        i_maxSupply = maxSupply;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        if (msg.sender != s_owner[tokenId]) {
            revert Genesis721__UnAuthorised();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Genesis721__UnAuthorised();
        }
        _;
    }

    modifier whenNotPaused() {
        if (s_pause) {
            revert Genesis721__ContractIsPaused();
        }
        _;
    }

    function pause() public onlyOwner {
        if (s_pause == true) {
            revert Genesis721__IsPaused();
        }

        s_pause = true;
    }

    function unPause() public onlyOwner {
        if (s_pause != true) {
            revert Genesis721__IsUnPaused();
        }

        s_pause = false;
    }

    function name() public pure returns (string memory) {
        return "Genesis721";
    }

    function symbol() public pure returns (string memory) {
        return "GEN";
    }

    function totalSupply() public view returns (uint256) {
        uint256 supply = s_totalMinted - s_burned;
        return supply;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (s_owner[tokenId] == address(0)) {
            revert Genesis721__InvalidTokenId();
        }

        return string(abi.encodePacked(baseUri, tokenId.toString(), ".json"));
    }

    function balanceOf(address owner) external view returns (uint256) {
        if (owner == address(0)) {
            revert Genesis721__InvalidAddress();
        }
        return s_balance[owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        if (s_owner[tokenId] == address(0)) {
            revert Genesis721__InvalidTokenId();
        }

        return s_owner[tokenId];
    }

    function mint(address to) external onlyOwner whenNotPaused {
        uint256 tokenId = s_nextTokenId;

        if (s_totalMinted >= i_maxSupply) {
            revert Genesis721__MintedOut();
        }

        if (to == address(0)) {
            revert Genesis721__InvalidAddress();
        }

        if (s_owner[tokenId] != address(0)) {
            revert Genesis721__TokenIdExisted();
        }

        s_nextTokenId++;
        s_balance[to] += 1;
        s_totalMinted += 1;
        s_owner[tokenId] = to;
        s_approvals[tokenId] = address(0);

        emit Transfer(address(0), to, tokenId);
    }

    function safeMint(address to, bytes memory data) external onlyOwner whenNotPaused {
        uint256 tokenId = s_nextTokenId;

        if (s_totalMinted >= i_maxSupply) {
            revert Genesis721__MintedOut();
        }

        if (to == address(0)) {
            revert Genesis721__InvalidAddress();
        }

        if (s_owner[tokenId] != address(0)) {
            revert Genesis721__TokenIdExisted();
        }

        s_nextTokenId++;
        s_totalMinted += 1;
        s_balance[to] += 1;
        s_owner[tokenId] = to;
        s_approvals[tokenId] = address(0);

        if (to.code.length > 0) {
            try IERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), tokenId, data) returns (bytes4 retval)
            {
                require(retval == 0x150b7a02, "Mint Failed");
            } catch {
                revert Genesis721__TransferFailed();
            }
        }

        emit Transfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) external whenNotPaused {
        address owner = s_owner[tokenId];

        if (msg.sender != owner && s_approvals[tokenId] != msg.sender && !s_operatorApproval[owner][msg.sender]) {
            revert Genesis721__UnAuthorised();
        }

        s_balance[owner] -= 1;
        s_burned += 1;
        s_approvals[tokenId] = address(0);
        s_owner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        whenNotPaused
    {
        if (to == address(0)) {
            revert Genesis721__InvalidAddress();
        }

        if (
            s_owner[tokenId] != msg.sender && msg.sender != s_approvals[tokenId]
                && !s_operatorApproval[from][msg.sender]
        ) {
            revert Genesis721__UnAuthorised();
        }

        s_balance[from] -= 1;
        s_balance[to] += 1;
        s_owner[tokenId] = to;

        s_approvals[tokenId] = address(0);

        if (to.code.length > 0) {
            try IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                require(retval == 0x150b7a02, "Invalid Receiver");
            } catch {
                revert Genesis721__TransferFailed();
            }
        }

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    function transferFrom(address from, address to, uint256 tokenId) external payable whenNotPaused {
        if (s_balance[from] == 0) {
            revert Genesis721__NoBalance();
        }

        if (to == address(0)) {
            revert Genesis721__InvalidAddress();
        }

        if (
            s_owner[tokenId] != msg.sender && msg.sender != s_approvals[tokenId]
                && !s_operatorApproval[from][msg.sender]
        ) {
            revert Genesis721__UnAuthorised();
        }

        s_balance[from] -= 1;
        s_balance[to] += 1;
        s_owner[tokenId] = to;

        s_approvals[tokenId] = address(0);

        emit Transfer(from, to, tokenId);
    }

    function approve(address approved, uint256 tokenId) external payable onlyTokenOwner(tokenId) whenNotPaused {
        s_approvals[tokenId] = approved;

        emit Approval(msg.sender, approved, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external whenNotPaused {
        if (msg.sender == operator) {
            revert Genesis721__SenderCantBeOperator();
        }

        s_operatorApproval[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) external view whenNotPaused returns (address) {
        if (s_owner[tokenId] == address(0)) {
            revert Genesis721__NoneExistedTokenId();
        }

        return s_approvals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) external view whenNotPaused returns (bool) {
        return s_operatorApproval[owner][operator];
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        if (interfaceID == 0x80ac58cd) {
            return true;
        } else if (interfaceID == 0x5b5e139f) {
            return true;
        } else if (interfaceID == 0x01ffc9a7) {
            return true;
        } else {
            return false;
        }
    }
    ////////////////////////
    /// Getter Function ///
    //////////////////////

    function getContractOwner() external view returns (address) {
        return i_owner;
    }

    function getMaxSupply() external view returns (uint256) {
        return i_maxSupply;
    }

    function getTotalMinted() external view returns (uint256) {
        return s_totalMinted;
    }

    function getNextTokenId() external view returns (uint256) {
        return s_nextTokenId;
    }

    function getBurned() external view returns (uint256) {
        return s_burned;
    }

    function getApproval(uint256 tokenId) external view returns (address) {
        return s_approvals[tokenId];
    }

    function paused() external view returns (bool) {
        return s_pause;
    }
}
