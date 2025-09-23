// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

error Genesis721__NOtAHolder();
error Genesis721__NoBalance();
error Genesis721__InvalidAddress();
error Genesis721__NotApproved();

contract Genesis721 {

	bool s_paused;
	
	mapping (address => uint256) private s_balance;
	mapping (uint256 => address) private s_owner;
	mapping (address => bool) private s_isHolder;
	mapping (uint256 => address) private s_approvals;
	mapping (address => mapping(address => bool)) s_operatorApproval;
	
	
	
	event Transfer(address indexed sender, address indexed receiver, uint256 tokenId);
	event ApprovalForAll(address indexed sender, address indexed reciever, bool);
	event Approval(address indexed sender, address indexed receiver, uint256 amount);
	
	
	function ownerOf(uint256 tokenId) external view returns (address){
		
		if(s_owner[tokenId] == address(0)){
			revert Genesis721__NOtAHolder();
		}
	
		return s_owner[tokenId]; 
	}
	
	
	function balanceOf(address owner) external view returns (uint256){
		
		if(s_balance[owner] == 0){
			revert Genesis721__NoBalance();
		}
		
		return s_balance[owner];
	}
	
	
	function safeTransferFrom(address from, address to,uint256 tokenId, bytes memory data) public payable {
		
		uint256 tokenCount = 1;
		
		if(s_balance[from] == 0 || s_owner[tokenId] != from){
			revert Genesis721__NoBalance();
		}
		
		if(to == address(0)){
			revert Genesis721__InvalidAddress();
		}
		
		s_balance[from] -= tokenCount;
		s_balance[to] += tokenCount;
		
		s_owner[tokenId] = to;
		
		if(to.code.length > 0){
			try
		
			IERC721Receiver(to).onERC721Received(
				msg.sender,
				from,
				tokenId,
				data
			) returns(bytes4 retval){
				require (retval == 0x150b7a02, "Tranfer Failed");
			} catch {
				revert ("Transfer Failed");
			}
		}
		
		s_isHolder[to] = true;
		
		if(s_balance[from] == 0){
			s_isHolder[from] = false;
		} else{
			s_isHolder[from] = true;
		}
		
		emit Transfer(from, to, tokenId);
	}
	
	
	function safeTransferFrom(address from, address to,uint256 tokenId) external payable {
		
		safeTransferFrom(from, to, tokenId, "");
		
	}
	
	
	function transferFrom(address from, address to, uint256 tokenId) external payable {
		
		uint256 tokenCount = 1;
		
		if (s_balance[from] == 0 || s_owner[tokenId] != from){
			revert Genesis721__NoBalance();
		}
		
		if (to == address(0)){
			revert Genesis721__InvalidAddress();
		}
		
		if(s_approvals[tokenId] != msg.sender && s_approvals[tokenId] != from && !s_operatorApproval[from][msg.sender]){
			revert Genesis721__NotApproved();
		}
		
		s_balance[from] -= tokenCount;
		s_balance[to] += tokenCount;
		s_owner[tokenId] = to;
		s_isHolder[to] = true;
		
		if(s_balance[from] == 0){
			s_isHolder[from] = false;
		}else{
				s_isHolder[from] = true;
		}
		
		emit Transfer(from, to, tokenId);
		
	}
	
	
	function approve(address approved, uint256 tokenId) external payable {
		
		if(s_balance[msg.sender] == 0 || s_owner[tokenId] != msg.sender){
			revert Genesis721__NoBalance();
		}
		
		if(approved == address(0)){
			revert Genesis721__InvalidAddress();
		}
		
		s_approvals[tokenId] = approved;
		
		emit Approval (msg.sender, approved, tokenId);
		
	}
	
	
	function setApprovalForAll(address operator, bool approved) external payable {
		s_operatorApproval[msg.sender][operator] = approved;
		
		emit ApprovalForAll(msg.sender, operator, approved);
	}
	
	
	function getApproved(uint256 tokenId) external view returns (address) {
		
	}
	
	
	function isApprovedForAll(address owner, address operator) external view returns (bool) {
		return s_operatorApproval[owner][operator];
	}
	
	
	function paused() public view {
		
	}
	
	function unPaused() public view {
		
	}
	
	
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
