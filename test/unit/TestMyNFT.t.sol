// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../../src/MyNFT.sol";
import {DeployGenesis721} from "../../script/DeployMyNFT.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import "./BadReceiver.sol";
import "./GoodReceiver.sol";

contract TestGenesis721 is Test {
    HelperConfig helper;
    DeployGenesis721 deployer;
    Genesis721 genesis;
    BadReceiver bad;
    GoodReceiver good;

    string baseURI;

    uint256 public maxSupply = 4;
    uint256 public constant STARTING_USER_BALANCE = 3 ether;
    uint256 public deployerkey;
    address bob = makeAddr("bob");
    address mike = makeAddr("mike");

    /* Events */
    event Transfer(address indexed sender, address indexed receiver, uint256 tokenId);
    event Approval(address indexed sender, address indexed approved, uint256 tokenId);
    event ApprovalForAll(address indexed sender, address indexed operator, bool approved);

    function setUp() external {
        deployer = new DeployGenesis721();
        helper = new HelperConfig();

        (maxSupply, deployerkey) = helper.activeNetworkConfig();

        genesis = deployer.run();

        bad = new BadReceiver();
        good = new GoodReceiver();

        vm.deal(bob, STARTING_USER_BALANCE);
    }

    function testGenesisSetCreatorAsContractOwner() public view {
        assertEq(genesis.getContractOwner(), vm.addr(deployerkey));
    }

    function testGenesisMaxSupply() public view {
        assertEq(genesis.getMaxSupply(), maxSupply);
    }

    function testContractName() public view {
        assertEq(genesis.name(), "Genesis721");
    }

    function testGenesisSymbol() public view {
        assertEq(genesis.symbol(), "GEN");
    }

    function testTotalSupply() public view {
        uint256 supply;
        assertEq(genesis.totalSupply(), supply);
    }

    ///////////////
    // TokenURLI //
    //////////////

    function testRevertIfTokenUIRIsInvalid() public {
        vm.expectRevert(Genesis721__InvalidTokenId.selector);
        genesis.tokenURI(1);
    }

    function testTokenURi() public {
        vm.prank(vm.addr(deployerkey));
        genesis.mint(bob);

        string memory uri = genesis.tokenURI(1);
        string memory expectedUri = "ipfs://bafybeihqrz6j6rqravxrnql4g7a5mwnwr3o5mwof744mx6hmztvxm3sff4/1.json";

        assertEq(uri, expectedUri);
    }

    function testTokenUriRevertWhenTokenIsBunred() public minted {
        vm.prank(bob);
        genesis.burn(1);

        vm.expectRevert(Genesis721__InvalidTokenId.selector);
        genesis.tokenURI(1);
    }

    //////////////////
    /// balance0f ///
    ////////////////

    function testRevertIfInvalidAddr() public {
        vm.expectRevert(Genesis721__InvalidAddress.selector);
        genesis.balanceOf(address(0));
    }

    function testBalanceOfHolder() public {
        vm.prank(vm.addr(deployerkey));
        genesis.mint(bob);

        assertEq(genesis.balanceOf(bob), 1);
    }

    ///////////
    // Owner //
    //////////

    function testRevertIfOwnerIsZeroAddr() public {
        vm.expectRevert(Genesis721__InvalidTokenId.selector);
        genesis.ownerOf(1);
    }

    function testOwnerOf() public {
        vm.prank(vm.addr(deployerkey));
        genesis.mint(bob);

        assertEq(genesis.ownerOf(1), bob);
    }

    /////////////
    /// Mint ///
    ///////////

    function testMintRevertIfNotOwner() public {
        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(bob);
        genesis.mint(mike);
    }

    function testRevertIfMintedAmountIsMoreThanSupply() public {
        address sunday = makeAddr("sunday");
        address odun = makeAddr("odun");
        address jibola = makeAddr("jibola");

        vm.prank(vm.addr(deployerkey));
        genesis.mint(mike);

        vm.prank(vm.addr(deployerkey));
        genesis.mint(bob);

        vm.prank(vm.addr(deployerkey));
        genesis.mint(sunday);

        vm.prank(vm.addr(deployerkey));
        genesis.mint(odun);

        vm.expectRevert(Genesis721__MintedOut.selector);
        vm.prank(vm.addr(deployerkey));
        genesis.mint(jibola);
    }

    function testMinPaasedWhenTotalSupply() public minted {
        address john = makeAddr("john");
        address tonali = makeAddr("tonali");

        vm.startPrank(vm.addr(deployerkey));
        genesis.mint(mike);
        genesis.mint(john);
        genesis.mint(tonali);
        vm.stopPrank();

        assertEq(genesis.balanceOf(bob), 1);
        assertEq(genesis.balanceOf(mike), 1);
        assertEq(genesis.balanceOf(john), 1);
        assertEq(genesis.balanceOf(tonali), 1);

        assertEq(genesis.ownerOf(1), bob);
        assertEq(genesis.ownerOf(2), mike);
        assertEq(genesis.ownerOf(3), john);
        assertEq(genesis.ownerOf(4), tonali);

        assertEq(genesis.getApproved(1), address(0));
        assertEq(genesis.getApproved(2), address(0));
        assertEq(genesis.getApproved(3), address(0));
        assertEq(genesis.getApproved(4), address(0));
    }

    function testRevertIfMintedToZeroAddr() public {
        vm.prank(vm.addr(deployerkey));
        vm.expectRevert(Genesis721__InvalidAddress.selector);

        genesis.mint(address(0));
    }

    function testRevertIfContractIsPaused() public {
        vm.prank(vm.addr(deployerkey));
        genesis.mint(bob);

        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.expectRevert(Genesis721__ContractIsPaused.selector);
        vm.prank(vm.addr(deployerkey));
        genesis.mint(mike);
    }

    function testMintPassedWhenContrcatIsOpen() public minted {
        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.prank(vm.addr(deployerkey));
        genesis.unPause();

        vm.prank(vm.addr(deployerkey));
        genesis.mint(mike);
    }

    function testGenesisUpdateBalanceSetOwnerIncreaseTokenIdAndEmitEvent() public {
        vm.expectEmit();
        emit Transfer(address(0), bob, 1);

        vm.prank(vm.addr(deployerkey));
        genesis.mint(bob);

        vm.prank(vm.addr(deployerkey));
        genesis.mint(mike);

        uint256 expectedNextTokenId = 3;

        assertEq(genesis.getTotalMinted(), 2);
        assertEq(genesis.balanceOf(bob), 1);
        assertEq(genesis.ownerOf(2), mike);
        assertEq(genesis.getNextTokenId(), expectedNextTokenId);
        assertEq(genesis.getApproved(2), address(0));
    }

    ///////////////
    // Safe Mint //
    //////////////

    function testSafeMintRevertIfNotOwnerTyingToMint() public {
        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(mike);
        genesis.safeMint(bob, "");
    }

    function testSafeMintRevertIfContractIsPaused() public {
        vm.prank(vm.addr(deployerkey));
        genesis.safeMint(bob, "");

        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.expectRevert(Genesis721__ContractIsPaused.selector);
        vm.prank(vm.addr(deployerkey));
        genesis.safeMint(mike, "");
    }

    function testSafeMintPassedWhenContrcatIsOpen() public minted {
        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.prank(vm.addr(deployerkey));
        genesis.unPause();

        vm.prank(vm.addr(deployerkey));
        genesis.safeMint(mike, "");
    }

    function testRevertIfMintedMoreThanSupply() public {
        address john = makeAddr("john");
        address pat = makeAddr("pat");
        address lola = makeAddr("lola");

        vm.startPrank(vm.addr(deployerkey));
        genesis.safeMint(bob, "");
        genesis.safeMint(mike, "");
        genesis.safeMint(pat, "");
        genesis.safeMint(john, "");
        vm.stopPrank();

        vm.prank(vm.addr(deployerkey));
        vm.expectRevert(Genesis721__MintedOut.selector);
        genesis.safeMint(lola, "");
    }

    function testSafeMintRevertIfMintedToAddrZero() public {
        vm.expectRevert(Genesis721__InvalidAddress.selector);
        vm.prank(vm.addr(deployerkey));
        genesis.safeMint(address(0), "");
    }

    function testSfeMinRevertIfRecieverDoesNotImplementOnErcReceive() public {
        vm.expectRevert(Genesis721__TransferFailed.selector);
        vm.prank(vm.addr(deployerkey));

        genesis.safeMint(address(bad), "");
    }

    function testSafeMintPassedIfContractImplementOnErcReceived() public {
        vm.prank(vm.addr(deployerkey));
        genesis.safeMint(address(good), "");

        assertEq(genesis.ownerOf(1), address(good));
    }

    function testSafeMintMintUpdateBalanceIncreaseTokenCountsAndEmitEvent() public {
        vm.prank(vm.addr(deployerkey));
        genesis.safeMint(bob, "");

        vm.expectEmit();
        emit Transfer(address(0), mike, 2);

        vm.prank(vm.addr(deployerkey));
        genesis.safeMint(mike, "");

        assertEq(genesis.ownerOf(2), mike);
        assertEq(genesis.getNextTokenId(), 3);
        assertEq(genesis.balanceOf(bob), 1);
        assertEq(genesis.getTotalMinted(), 2);
        assertEq(genesis.getApproved(1), address(0));
    }

    //////////////
    //// Burn ////
    /////////////

    modifier minted() {
        vm.prank(vm.addr(deployerkey));
        genesis.mint(bob);
        _;
    }

    function testBurnRevertIfContractIsPaused() public {
        vm.prank(vm.addr(deployerkey));
        genesis.mint(bob);

        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.expectRevert(Genesis721__ContractIsPaused.selector);
        vm.prank(bob);
        genesis.burn(1);
    }

    function testBurnPassedWhenContrcatIsOpen() public minted {
        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.prank(vm.addr(deployerkey));
        genesis.unPause();

        vm.prank(bob);
        genesis.burn(1);
    }

    function testBurnRevertIfSenderINotOwner() public minted {
        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(mike);
        genesis.burn(1);
    }

    function testRevertIfNotApproved() public minted {
        address james = makeAddr("james");

        vm.prank(bob);
        genesis.approve(james, 1);

        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(mike);
        genesis.burn(1);
    }

    function testRevertIfNotOperator() public minted {
        address james = makeAddr("james");
        vm.prank(bob);
        genesis.setApprovalForAll(mike, true);

        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(james);
        genesis.burn(1);
    }

    function testBurnPassedIfOwner() public minted {
        vm.prank(bob);
        genesis.burn(1);

        assertEq(genesis.balanceOf(bob), 0);
    }

    function testBurnPassedIfApproved() public minted {
        vm.prank(bob);
        genesis.approve(mike, 1);

        vm.prank(mike);
        genesis.burn(1);

        assertEq(genesis.balanceOf(bob), 0);
    }

    function testBurnPassedIfSenderIsAnOpertor() public minted {
        vm.prank(bob);
        genesis.setApprovalForAll(mike, true);

        vm.prank(mike);
        genesis.burn(1);

        assertEq(genesis.balanceOf(bob), 0);
    }

    function testBurnPassedUpdateBlanaceEmitEvent() public minted {
        vm.expectEmit();
        emit Transfer(bob, address(0), 1);

        vm.prank(bob);
        genesis.burn(1);

        assertEq(genesis.balanceOf(bob), 0);
        assertEq(genesis.getBurned(), 1);
        assertEq(genesis.getApproval(1), address(0));

        vm.expectRevert(Genesis721__InvalidTokenId.selector);
        genesis.ownerOf(1);
    }

    //////////////////////
    // SafeTransferFrom //
    /////////////////////

    function testRevetIfReceieverIsAddrZero() public minted {
        vm.expectRevert(Genesis721__InvalidAddress.selector);
        vm.prank(bob);
        genesis.safeTransferFrom(bob, address(0), 1, "");
    }

    function testRevertIfSenderIsNotOwner() public minted {
        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(mike);
        genesis.safeTransferFrom(mike, bob, 1, "");
    }

    function testRevertIfSenderIsnotApprove() public minted {
        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(mike);
        genesis.safeTransferFrom(mike, bob, 1, "");
    }

    function testRevertIfSenderIsNotApprovedOrOperator() public minted {
        address wood = makeAddr("wood");

        vm.prank(bob);
        genesis.setApprovalForAll(wood, true);

        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(mike);
        genesis.safeTransferFrom(bob, wood, 1, "");
    }

    function testSafeTransferFromRevertIfReciecerDoesNotImplementOnErc721Recieved() public minted {
        vm.expectRevert(Genesis721__TransferFailed.selector);
        vm.prank(bob);
        genesis.safeTransferFrom(bob, address(bad), 1, "");
    }

    function testRevetWhenContractIsPaused() public minted {
        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.expectRevert(Genesis721__ContractIsPaused.selector);
        vm.prank(bob);
        genesis.safeTransferFrom(bob, mike, 1, "");
    }

    function testContractUnPaused() public minted {
        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.prank(vm.addr(deployerkey));
        genesis.unPause();

        vm.prank(bob);
        genesis.safeTransferFrom(bob, mike, 1, "");
    }

    function testSafeTransferFromPassedIfReceieverImplementOnERCReceived() public minted {
        vm.prank(bob);
        genesis.safeTransferFrom(bob, address(good), 1, "");

        assertEq(genesis.balanceOf(address(good)), 1);
        assertEq(genesis.balanceOf(bob), 0);
    }

    function testSafeTransferFromPassedUpdateBalanceAndEmitEvents() public minted {
        vm.prank(vm.addr(deployerkey));
        genesis.mint(mike);

        vm.expectEmit();
        emit Transfer(bob, mike, 1);

        vm.prank(bob);
        genesis.safeTransferFrom(bob, mike, 1, "");

        vm.prank(mike);
        genesis.safeTransferFrom(mike, bob, 2);

        assertEq(genesis.balanceOf(mike), 1);
        assertEq(genesis.balanceOf(bob), 1);
        assertEq(genesis.ownerOf(1), mike);
        assertEq(genesis.ownerOf(2), bob);
        assertEq(genesis.getApproval(1), address(0));
        assertEq(genesis.getApproval(2), address(0));
    }

    //////////////////////
    // SafeTransferFrom //
    /////////////////////

    function testSafeTransferFromBasicUpdatesBalanceAndOwner() public minted {
        vm.expectEmit();
        emit Transfer(bob, mike, 1);

        vm.prank(bob);
        genesis.safeTransferFrom(bob, mike, 1);

        assertEq(genesis.balanceOf(bob), 0);
        assertEq(genesis.ownerOf(1), mike);
        assertEq(genesis.getApproval(1), address(0));
        assertEq(genesis.balanceOf(mike), 1);
    }

    ////////////////////
    // Transfer From //
    //////////////////

    function testTransferFromRevertIfContractIsLocked() public minted {
        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.expectRevert(Genesis721__ContractIsPaused.selector);
        vm.prank(bob);
        genesis.transferFrom(bob, mike, 1);
    }

    function testTransferFromPssedWhenContractIsUnpaused() public minted {
        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.prank(vm.addr(deployerkey));
        genesis.unPause();

        vm.prank(bob);
        genesis.transferFrom(bob, mike, 1);
    }

    function testTransferFromRevertIfBalanceIsZero() public {
        address james = makeAddr("james");

        vm.expectRevert(Genesis721__NoBalance.selector);
        vm.prank(james);
        genesis.transferFrom(james, bob, 1);
    }

    function testRevertIfTransferToAddrZero() public minted {
        vm.expectRevert(Genesis721__InvalidAddress.selector);
        vm.prank(bob);
        genesis.transferFrom(bob, address(0), 1);
    }

    function testRevertIfTokenIdIsNotFromOwner() public minted {
        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(mike);
        genesis.transferFrom(bob, mike, 1);
    }

    function testTransferRevertIfSenderIsNotApproved() public minted {
        address james = makeAddr("james");

        vm.prank(bob);
        genesis.approve(james, 1);

        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(mike);
        genesis.transferFrom(bob, mike, 1);
    }

    function testRevertIfSenderIsNotOpperator() public minted {
        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(mike);
        genesis.transferFrom(bob, mike, 1);
    }

    function testTransferFromPassedIfHasBalance() public minted {
        vm.prank(bob);
        genesis.transferFrom(bob, mike, 1);
    }

    function testTranafserFromPaasedIfSenderIsApproved() public minted {
        vm.prank(bob);
        genesis.approve(mike, 1);

        vm.prank(mike);
        genesis.transferFrom(bob, mike, 1);
    }

    function testTransferFromPaasedIfSenderIsOperator() public minted {
        vm.prank(bob);
        genesis.setApprovalForAll(mike, true);

        vm.prank(mike);
        genesis.transferFrom(bob, mike, 1);
    }

    function testTransferFromPassedUpdateBalanceReserApprovalEmitEvent() public minted {
        vm.expectEmit();
        emit Transfer(bob, mike, 1);

        vm.prank(bob);
        genesis.transferFrom(bob, mike, 1);

        assertEq(genesis.balanceOf(bob), 0);
        assertEq(genesis.balanceOf(mike), 1);
        assertEq(genesis.ownerOf(1), mike);
        assertEq(genesis.getApproval(1), address(0));
    }

    //////////////////
    /// Approeve ////
    ////////////////

    function testApproveRevertWhenContractIsPaused() public minted {
        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.expectRevert(Genesis721__ContractIsPaused.selector);
        vm.prank(bob);
        genesis.approve(mike, 1);
    }

    function testApprovePassedWhenContractIsNotPaused() public minted {
        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.prank(vm.addr(deployerkey));
        genesis.unPause();

        vm.prank(bob);
        genesis.approve(mike, 1);
    }

    function testApproveRevertIfCallerISontOwnerOfTokenId() public minted {
        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(mike);
        genesis.approve(bob, 1);
    }

    function testApprovePassedAndEmitEvents() public minted {
        vm.expectEmit();
        emit Approval(bob, mike, 1);

        vm.prank(bob);
        genesis.approve(mike, 1);
    }

    function testApproveRevokesWhenZeroAddress() public minted {
        vm.expectEmit();
        emit Approval(bob, address(0), 1);

        vm.prank(bob);
        genesis.approve(address(0), 1);

        assertEq(genesis.getApproval(1), address(0));
    }

    //////////////////////////
    // Set Approval For All //
    /////////////////////////

    function testRevertIfSendIsOperator() public minted {
        vm.expectRevert(Genesis721__SenderCantBeOperator.selector);
        vm.prank(mike);
        genesis.setApprovalForAll(mike, true);
    }

    function testSetApprrovalForAllFailedWhenContractIsLocked() public minted {
        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.expectRevert(Genesis721__ContractIsPaused.selector);
        vm.prank(bob);
        genesis.setApprovalForAll(mike, true);
    }

    function testSetApprovalForAllPasseedWhenContractIsUnpaused() public minted {
        vm.prank(vm.addr(deployerkey));
        genesis.pause();

        vm.prank(vm.addr(deployerkey));
        genesis.unPause();

        vm.prank(bob);
        genesis.setApprovalForAll(mike, true);
    }

    function testSetApprovalForAllPassedAndEmitEvent() public {
        vm.expectEmit();
        emit ApprovalForAll(bob, mike, true);

        vm.prank(bob);
        genesis.setApprovalForAll(mike, true);
    }

    function testSetApprovalForAllReturnFalseIfOperatorIsNotSet() public minted {
        bool expectedReturn = genesis.isApprovedForAll(bob, mike);

        assert(expectedReturn == false);
    }

    /////////////////////
    /// Get Approved ///
    ///////////////////

    modifier isPaused() {
        vm.prank(vm.addr(deployerkey));
        genesis.pause();
        _;
    }

    function testGetApprovalRevetWhenContractIsPaused() public minted isPaused {
        vm.expectRevert(Genesis721__ContractIsPaused.selector);
        vm.prank(bob);
        genesis.getApproved(1);
    }

    function testGetApprovedPassedWhenContractIsUnlocked() public minted isPaused {
        vm.prank(vm.addr(deployerkey));
        genesis.unPause();

        vm.prank(bob);
        genesis.approve(mike, 1);

        vm.prank(mike);
        genesis.getApproved(1);
    }

    function testGetApprovedRevertIfTokenIdIsNotExisted() public {
        vm.expectRevert(Genesis721__NoneExistedTokenId.selector);
        vm.prank(bob);
        genesis.getApproved(2);
    }

    function testGetApprovedPassedAndReturnApprovedAddr() public minted {
        address james = makeAddr("james");

        vm.prank(bob);
        genesis.approve(mike, 1);

        vm.prank(james);
        genesis.getApproved(1);

        assertEq(genesis.getApproved(1), mike);
    }

    function testGetApprovalReturnAddrZeroWhenTokenHasNoApproval() public minted {
        assertEq(genesis.getApproved(1), address(0));
    }

    /////////////////////
    // IsApprovedForAll//
    ////////////////////

    function testIsApprovedFaliedWhenContractIsPaused() public isPaused {
        vm.expectRevert(Genesis721__ContractIsPaused.selector);
        vm.prank(mike);
        genesis.isApprovedForAll(bob, mike);
    }

    function testIsApproveForAllPassedWHneContractIsUnlocked() public minted isPaused {
        vm.prank(vm.addr(deployerkey));
        genesis.unPause();

        vm.prank(bob);
        genesis.setApprovalForAll(mike, true);

        vm.prank(mike);
        genesis.isApprovedForAll(bob, mike);
    }

    function test_isApprovedForAll_validOperator_returnsTrue() public minted {
        vm.prank(bob);
        genesis.setApprovalForAll(mike, true);

        vm.prank(mike);
        genesis.isApprovedForAll(bob, mike);
    }

    //////////////
    /// Pause ///
    ////////////

    function testContractRevertIfAlreadyPaused() public isPaused {
        vm.expectRevert(Genesis721__IsPaused.selector);
        vm.prank(vm.addr(deployerkey));
        genesis.pause();
    }

    function testRevertWhenPuasedIsNotCalledByOwner() public {
        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(bob);
        genesis.pause();
    }

    function testPauseReturnTrureWhenPused() public isPaused {
        assertEq(genesis.paused(), true);
    }

    ///////////////
    // UnPuased //
    /////////////

    function testRevertWhenContractIsAlreadyUnPaused() public {
        vm.expectRevert(Genesis721__IsUnPaused.selector);
        vm.prank(vm.addr(deployerkey));
        genesis.unPause();
    }

    function testRevertWhenUnpausedIsNotCalledByOwner() public isPaused {
        vm.expectRevert(Genesis721__UnAuthorised.selector);
        vm.prank(mike);
        genesis.unPause();
    }

    function testUnpausedReturnFalseWhenContractIsUnpaused() public view {
        assertEq(genesis.paused(), false);
    }

    ///////////////////////////
    /// Supports Interface ///
    /////////////////////////

    function testSupportsInterfaceReturnsTrueForERC721() public view {
        bytes4 interfaceID = 0x80ac58cd;
        bool expectedReturn = genesis.supportsInterface(interfaceID);
        assertEq(expectedReturn, true);
    }

    function testSupportsInterfaceReturnsTrueForERC721Metadata() public view {
        bytes4 interfaceID = 0x5b5e139f;
        bool isTrue = genesis.supportsInterface(interfaceID);

        assertEq(isTrue, true);
    }

    function testSupportsInterfaceReturnsTrueForERC165() public view {
        bytes4 interfaceID = 0x01ffc9a7;
        bool isTrue = genesis.supportsInterface(interfaceID);

        assert(isTrue == true);
    }

    function testSupportsInterfaceReturnsFalseForUnknownInterface() public view {
        bytes4 interfaceID = "";
        bool isFalse = genesis.supportsInterface(interfaceID);

        assert(isFalse == false);
    }
}
