// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@forge-std/Test.sol";
import { GIGADRIP20 } from "src/GIGADRIP20.sol";
import { cowClubToken } from "src/cowClubToken.sol";
import { BCCC } from "src/boredCowCheeseclub.sol";
import { CC } from "src/cowClub.sol";

contract BCCCTest is Test {
  CC cc;
  BCCC bccc;

  cowClubToken token;

  address user1;
  address user2;
  address user3;

  function setUp() public {
    token = new cowClubToken("MOCK", "MOCK", 18, 10); // token emission is 10 per block

    cc = new CC("Doge Ape Yacht Club", "CC", "https://thistoken.org/");
    bccc = new BCCC(
      "Doge Ape Yacht Club",
      "CC",
      "https://thistoken.org/",
      address(token),
      address(cc)
    );

    cc.setPaused();
    bccc.setPaused();

    user1 = address(0xaa);
    user2 = address(0xbb);
    user3 = address(0xcc);
  }

  function testMintByToken() public {
    deal(address(token), user1, 10000e18);

    vm.startPrank(user1);

    bccc.mintByToken(2);

    assertEq(bccc.balanceOf(address(user1)), 2);

    assertEq(bccc.countMintedByToken(), 2);
  }

  function testMintTooManyPerTxMintByToken() public {
    deal(address(token), user1, 10000e18);
    bccc.setMaxAmountPerTx(1);

    vm.startPrank(user1);

    vm.expectRevert(abi.encodeWithSignature("MaxAmountPerTxReached()"));
    bccc.mintByToken(2);
    vm.stopPrank();
  }

  function testMintByTokenWithoutTokenToBurn() public {
    vm.startPrank(user1);

    vm.expectRevert(stdError.arithmeticError);
    bccc.mintByToken(2);

    assertEq(bccc.balanceOf(address(user1)), 0);
  }

  function testUpdatePriceTierLimits() public {
    bccc.setPriceTierOneLimit(1);
    assertEq(bccc.priceTierOneLimit(), 1);

    bccc.setPriceTierTwoLimit(2);
    assertEq(bccc.priceTierTwoLimit(), 2);
  }

  uint256[] tokensToBurn;

  function testMintByBurnNFT() public {
    vm.deal(address(user1), 3000 ether);
    vm.startPrank(user1);

    cc.mintNft{ value: 1000 ether }(3);

    assertEq(bccc.balanceOf(address(user1)), 0);
    assertEq(cc.balanceOf(address(user1)), 3);

    tokensToBurn.push(uint256(1));
    tokensToBurn.push(uint256(2));
    tokensToBurn.push(uint256(3));

    cc.setApprovalForAll(address(bccc), true);

    bccc.mintByBurnNFT(tokensToBurn);

    assertEq(cc.balanceOf(address(user1)), 0);
    assertEq(bccc.balanceOf(address(user1)), 1);
  }

  function testPausedMintByToken() public {
    bccc.setPaused();

    vm.expectRevert(abi.encodeWithSignature("MintPaused()"));
    bccc.mintByToken(1);
  }

  function testPausedMintByBurnNFT() public {
    bccc.setPaused();

    tokensToBurn.push(uint256(1));

    vm.expectRevert(abi.encodeWithSignature("MintPaused()"));
    bccc.mintByBurnNFT(tokensToBurn);
  }

  function testMintMoreByBurnNFTThanLimit() public {
    bccc.setMaxMintedByBurningNFT(1);
    vm.deal(address(user1), 4000 ether);
    vm.startPrank(user1);

    cc.mintNft{ value: 3000 ether }(6);

    tokensToBurn.push(uint256(1));
    tokensToBurn.push(uint256(2));
    tokensToBurn.push(uint256(3));
    tokensToBurn.push(uint256(4));
    tokensToBurn.push(uint256(5));
    tokensToBurn.push(uint256(6));

    cc.setApprovalForAll(address(bccc), true);

    vm.expectRevert(abi.encodeWithSignature("MaxSupplyByBurningNFTReached()"));
    bccc.mintByBurnNFT(tokensToBurn);
  }

  function testMintTooManyPerTxByBurnNFTThanLimit() public {
    bccc.setMaxAmountPerTx(1);

    vm.deal(address(user1), 4000 ether);
    vm.startPrank(user1);

    cc.mintNft{ value: 3000 ether }(6);
    tokensToBurn.push(uint256(1));
    tokensToBurn.push(uint256(2));
    tokensToBurn.push(uint256(3));
    tokensToBurn.push(uint256(4));
    tokensToBurn.push(uint256(5));
    tokensToBurn.push(uint256(6));

    vm.expectRevert(abi.encodeWithSignature("MaxAmountPerTxReached()"));
    bccc.mintByBurnNFT(tokensToBurn);

    vm.stopPrank();
  }

  function testSenderNotOwnerMintByBurnNFT() public {
    vm.deal(address(user1), 4000 ether);
    vm.startPrank(user1);

    cc.mintNft{ value: 1500 ether }(3);
    tokensToBurn.push(uint256(1));
    tokensToBurn.push(uint256(2));
    tokensToBurn.push(uint256(3));

    vm.stopPrank();

    vm.startPrank(user2);

    vm.expectRevert(abi.encodeWithSignature("SenderNotTokenOwner()"));
    bccc.mintByBurnNFT(tokensToBurn);

    vm.stopPrank();
  }

  function testMintMoreByTokenThanLimit() public {
    deal(address(token), user1, 10000e18);
    bccc.setMaxMintedByBurningToken(1);

    vm.startPrank(user1);
    vm.expectRevert(abi.encodeWithSignature("MaxSupplyByBurningToken()"));
    bccc.mintByToken(2);
  }

  function testMintPriceAdjustment() public {
    bccc.setInitialPrice(5);

    assertEq(bccc.mintPrice(), 5);
  }

  function testMintPriceTierOneLimit() public {
    bccc.setPriceTierOneLimit(1);
    bccc.setInitialPrice(5);

    deal(address(token), user1, 10000e18);

    vm.startPrank(user1);
    bccc.mintByToken(2);

    assertEq(bccc.mintPrice(), 5 * 2);
  }

  function testMintPriceTierTwoLimit() public {
    bccc.setPriceTierOneLimit(1);
    bccc.setPriceTierTwoLimit(2);
    bccc.setInitialPrice(5);

    deal(address(token), user1, 10000e18);

    vm.startPrank(user1);
    bccc.mintByToken(3);

    assertEq(bccc.mintPrice(), 5 * 3);
  }

  function testMintPriceTierTwoLimitRevertIfLessThanTierOne() public {
    bccc.setPriceTierOneLimit(3);
    vm.expectRevert(abi.encodeWithSignature("TierTwoLimitLessThanTierOne()"));
    bccc.setPriceTierTwoLimit(1);
  }

  function testWithdrawalWorksAsOwner() public {
    address payable payee = payable(address(0x1337));
    uint256 priorPayeeBalance = payee.balance;

    vm.deal(address(bccc), 10 ether);

    // Check that the balance of the contract is correct

    assertEq(address(bccc).balance, 10 ether);

    // Withdraw the balance and assert it was transferred
    bccc.withdrawPayments(payee);

    assertEq(payee.balance, priorPayeeBalance + 10 ether);
  }

  function testOwnerCanSetPaused() public {
    bool pauseStatus = bccc.paused();
    bccc.setPaused();

    assertEq(!pauseStatus, bccc.paused());
  }

  function testNonOwnerSetPausedFails() public {
    vm.startPrank(user1);

    vm.expectRevert("Ownable: caller is not the owner");
    bccc.setPaused();
  }

  function testSetMaxAmountPerTx() public {
    bccc.setMaxAmountPerTx(666);

    assertEq(bccc.maxAmountPerTx(), 666);
  }

  function testNonOwnerSetMaxAmountPerTxFails() public {
    vm.startPrank(user1);

    vm.expectRevert("Ownable: caller is not the owner");
    bccc.setMaxAmountPerTx(666);
  }

  function testSetBaseURI() public {
    string memory initialBaseURI = "cat dog meow";

    bccc.setBaseURI("cat dog meow");

    assertEq(bccc.baseURI(), initialBaseURI);
  }

  function testNonOwnerSetBaseURI() public {
    vm.startPrank(user1);
    vm.expectRevert("Ownable: caller is not the owner");
    bccc.setBaseURI("cat dog meow");
  }

  function testReturnCorrectTokenURI() public {
    deal(address(token), user1, 10000e18);

    vm.startPrank(user1);
    bccc.mintByToken(2);

    string memory tokenURI = bccc.tokenURI(1);

    assertEq(tokenURI, "https://thistoken.org/1.json");
  }
}

contract Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 id,
    bytes calldata data
  ) external pure returns (bytes4) {
    return this.onERC721Received.selector;
  }
}
