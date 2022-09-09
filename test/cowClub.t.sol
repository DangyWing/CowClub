// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "@forge-std/Test.sol";
import { console } from "@forge-std/console.sol";
import { CC } from "src/cowClub.sol";

contract CCTest is Test {
  CC cc;

  address deployer;
  address user1;
  address user2;
  address user3;

  function setUp() public {
    user1 = address(0xaa);
    user2 = address(0xbb);
    user3 = address(0xcc);
    deployer = address(0xdd);

    vm.startPrank(deployer);

    cc = new CC("Cow Club", "CC", "https://thistoken.org/");
    cc.setPaused();

    vm.stopPrank();

    vm.deal(user1, 1000 ether);
    vm.deal(user2, 1000 ether);
    vm.deal(user3, 1000 ether);
    vm.deal(deployer, 1000 ether);
  }

  function testMintMoreThanLimit() public {
    vm.startPrank(deployer);
    cc.setMaxSupply(2);
    vm.stopPrank();

    vm.startPrank(user1);
    vm.expectRevert(abi.encodeWithSignature("MaxSupplyReached()"));
    cc.mintNft{ value: 400 ether }(8);
    vm.stopPrank();
  }

  function testMintMoreThanMaxPerTx() public {
    vm.startPrank(deployer);
    cc.setMaxAmountPerTx(1);
    vm.stopPrank();

    vm.startPrank(user1);
    vm.expectRevert(abi.encodeWithSignature("MaxAmountPerTxReached()"));
    cc.mintNft{ value: 400 ether }(8);
    vm.stopPrank();
  }

  function testMintRevertWhenPaused() public {
    vm.startPrank(deployer);
    cc.setPaused();
    vm.stopPrank();

    vm.startPrank(user1);
    vm.expectRevert(abi.encodeWithSignature("MintPaused()"));
    cc.mintNft{ value: 400 ether }(8);
    vm.stopPrank();
  }

  function testMint() public {
    cc.mintNft{ value: cc.price() * 5 }(5);
    assertEq(cc.balanceOf(address(this)), 5);
    assertEq(cc.totalSupply(), 5);
  }

  function testSingleMint() public {
    cc.mintNft{ value: cc.price() * 1 }(1);
    assertEq(cc.totalSupply(), 1);
    assertEq(cc.balanceOf(address(this)), 1);
  }

  function testSetPaused() public {
    vm.startPrank(deployer);
    bool pauseStatus = cc.paused();

    cc.setPaused();
    vm.stopPrank();

    assertEq(cc.paused(), !pauseStatus);
  }

  function testSetPrice() public {
    vm.startPrank(deployer);
    cc.setPrice(2);
    vm.stopPrank();

    assertEq(cc.price(), 2);
  }

  function testSetMaxAmountPerTx() public {
    vm.startPrank(deployer);
    cc.setMaxAmountPerTx(2);
    vm.stopPrank();

    assertEq(cc.maxAmountPerTx(), 2);
  }

  function testSetBaseURI() public {
    vm.startPrank(deployer);
    cc.setBaseURI("www.www.www");
    vm.stopPrank();

    assertEq(cc.baseURI(), "www.www.www");
  }

  function testWithdrawalWorksAsOwner() public {
    address payable payee = payable(address(0x1337));
    uint256 priorPayeeBalance = payee.balance;
    cc.mintNft{ value: cc.price() }(1);
    // Check that the balance of the contract is correct
    assertEq(address(cc).balance, cc.price());
    uint256 nftBalance = address(cc).balance;
    // Withdraw the balance and assert it was transferred
    vm.startPrank(deployer);
    cc.withdrawPayments(payee);
    assertEq(payee.balance, priorPayeeBalance + nftBalance);

    vm.stopPrank();
  }

  function testWithdrawalFailsAsNotOwner() public {
    // Mint an NFT, sending eth to the contract
    Receiver receiver = new Receiver();
    cc.mintNft{ value: cc.price() }(1);
    // Check that the balance of the contract is correct
    assertEq(address(cc).balance, cc.price());
    // Confirm that a non-owner cannot withdraw
    vm.expectRevert("Ownable: caller is not the owner");
    vm.startPrank(address(0xd3ad));
    cc.withdrawPayments(payable(address(0xd3ad)));
    vm.stopPrank();
  }

  function testMintWithoutEtherValue() public {
    vm.expectRevert(abi.encodeWithSignature("WrongAmountSent()"));
    cc.mintNft(1);
  }

  function testVerifyTokenUri() public {
    cc.mintNft{ value: 50 ether }(1);

    assertEq(cc.tokenURI(1), "https://thistoken.org/1.json");
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
