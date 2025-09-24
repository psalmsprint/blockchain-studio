// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

error Genesis721__NotOwnwer();
error Genesis721__InvalidAddress();
error Genesis721__SenderCantBeOperator();
error Genesis721__TokenIdExisted();
error Genesis721__IsPaused();
error Genesis721__IsUnPaused();
error Genesis721__TransferFailed();
error Genesis721__UnAuthorised();
error Genesis721__ContractIsPaused();
error Genesis721__NoBalance();

contract Genesis721 {

	bool s_pause;
	
	address private immutable i_owner;
	
	uint256 private s_totalSupply = 500;
	uint256 private s_nextTokenId = 1;
	
	mapping (address => uint256) private s_balance;
	mapping (uint256 => address) private s_owner;
	mapping (uint256 => address) private s_approvals;
	mapping (address => mapping(address => uint256)) s_operatorApproval;
	
	event Transfer(address indexed sender, address indexed receiver , uint256 tokenId);
	event Approval(address indexed sender, address indexed approved, uint256 tokenId);
	event ApprovalForAll(address indexed sender, address indexed operator, bool approved);
	
	
	modifier onlyOwner(uint256 tokenId) {
		if (msg.sender != s_owner[tokenId]){
			revert Genesis721__UnAuthorised();
		}
		_;
	}
	
	modifier ownerOnly() {
		if (msg.sender != i_owner){
			revert Genesis721__UnAuthorised();
		}
		_;
	}
	
	modifier whenNotPaused() {
		if (!s_pause){
			revert Genesis721__ContractIsPaused();
		}
		_;
	}
	
	
	function pause() public ownerOnly {
		if (s_pause == true){
			revert Genesis721__IsPaused();
		}
		
		s_pause = true;
	}
	
	
	function unPause() public ownerOnly {
		if(s_pause != true){
			revert Genesis721__IsUnPaused();
		}
		
		s_pause = false;
	}
	
	function name() public view returns(string memory){
		return "Genesis721";
	}
	
	
	function symbol() public view returns(string memory){
		return "GEN";
	}
	
	function totalSupply() public view returns(uint256){
		return s_totalSupply;
	}
	
	
	function mint(address to, uint256 tokenId) external ownerOnly whenNotPaused{
		if(to == address(0)){
			revert Genesis721__InvalidAddress();
		}
		
		if(s_owner[tokenId] != address(0)){
			revert Genesis721__TokenIdExisted();
		}
		
		tokenId = s_nextTokenId++;
		s_balance[to] += 1;
		s_totalSupply += 1;
		s_owner[tokenId] = to;
		s_approvals[tokenId] = address(0);
		
		emit Transfer(address(0), to, tokenId);
	}
	
	

    function safeMint(address to, uint256 tokenId, bytes memory data) external ownerOnly whenNotPaused {
		
		if(to == address(0)){
			revert Genesis721__InvalidAddress();
		}
		
		if (s_owner[tokenId] != address(0)){
			revert Genesis721__TokenIdExisted();
		}
		
		tokenId = s_nextTokenId++;
		s_totalSupply += 1;
		s_balance[to] += 1;
		s_owner[tokenId] = to;
		s_approvals[tokenId] = address(0);
		
		if (to.code.length > 0){
			try
				IERC721Receiver(to).onERC721Received(
					address(this),
					address(0),
					tokenId,
					data
				) returns (bytes4 retval){
					require (retval == 0x150b7a02, "Mint Failed"); 
				} catch {
					revert Genesis721__TransferFailed();
				}
		}
		
		emit Transfer(address(0), to, tokenId);
	}
	
	

    function burn(uint256 tokenId) external  whenNotPaused {
		
		address owner = s_owner[tokenId];
		
		
		if(msg.sender != owner &&
		s_approvals[tokenId] != msg.sender &&
		s_operatorApproval[owner][msg.sender] != msg.sender){
			revert Genesis721__UnAuthorised();
		}
		
		s_balance[owner] -= 1;
		s_totalSupply -= 1;
		s_approvals[tokenId] = address(0);
		s_owner[tokenId] = address(0);
		
		emit Transfer(owner, address(0), tokenId);
	}
	

	function balanceOf(address owner) external view returns (uint256) {
		
		return s_balance[owner];
	}

    function ownerOf(uint256 tokenId) external view returns (address){
		
		return s_owner[tokenId];
	}
	


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable whenNotPaused{
	
		if(s_balance[from] == 0){
			revert Genesis721__NoBalance();
		}
		
		if (to == address(0)){
			revert Genesis721__InvalidAddress();
		}
		
		if (s_owner[tokenId] != from && msg.sender != s_approvals[tokenId] && msg.sender != s_operatorApproval[from][msg.sender]){
			revert Genesis721__UnAuthorised();
		}
		
		s_balance[from] -= 1;
		s_balance[to] += 1;
		s_owner[tokenId] = to;
		
		s_approvals[tokenId] = address(0);
	
		if(to.code.length > 0){
			try
				IERC721Receiver(to).onERC721Received(
					msg.sender,
					from,
					tokenId,
					data
				) returns (bytes4 retval) {
					require (retval == 0x150b7a02, "Invalid Receiver");
				}	catch {
						revert Genesis721__TransferFailed();
					}
		}
		
		emit Transfer(from, to, tokenId);
		
	}


    function safeTransferFrom(address from, address to, uint256 tokenId) external payable whenNotPaused{
		safeTransferFrom(from, to, tokenId, "");
	}


    function transferFrom(address from, address to, uint256 tokenId) external payable whenNotPaused{
		
		if (s_balance[from] == 0){
			revert Genesis721__NoBalance();
		}
		
		if (to == address(0)){
			revert Genesis721__InvalidAddress();
		}
		
		if(s_owner[tokenId] != from 
		&& msg.sender != s_approvals[tokenId] &&
		msg.sender != s_operatorApproval[from][msg.sender]){
			revert Genesis721__UnAuthorised();
		}
		
		s_balance[from] -= 1;
		s_balance[to] += 1;
		s_owner[tokenId] = to;
		
		s_approvals[tokenId] = address(0);
		
		emit Transfer(from, to, tokenId);
		
	}
	

    function approve(address approved, uint256 tokenId) external payable onlyOwner whenNotPaused{
		if (s_balance[msg.sender] == 0){
			revert Genesis721__NoBalance();
		}
		
		if(approved == address(0)){
			revert Genesis721__InvalidAddress();
		}
		
		s_approvals[tokenId] = approved;
		
		emit Approval(msg.sender, approved, tokenId);
	}

    function setApprovalForAll(address operator, bool approved) external onlyOwner whenNotPaused {
		
		if(msg.sender == operator){
			revert Genesis721__SenderCantBeOperator();
		}
		
		s_operatorApproval[msg.sender][operator] = approved;
		
		emit ApprovalForAll(msg.sender, operator, approved);
		
	}

    function getApproved(uint256 tokenId) external whenNotPaused view returns (address){
		
		return s_approvals[tokenId];
		
	}


    function isApprovedForAll(address owner, address operator) external whenNotPaused view returns (bool){
		
		return s_operatorApproval[owner][operator];
		
	}
	

}


interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

