// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@forge-std/Test.sol";
import { GIGADRIP20 } from "../src/GIGADRIP20.sol";
import "../src/cowClubToken.sol";
import "../src/cowClubStaking.sol";
import "../src/cowClub.sol";

contract cowClubStakingTest is DSTest {
  CC nft;
  cowClubToken token;
  cowClubStaking staking;

  address user1;
  address user2;
  address user3;
  address owner;

  Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

  function setUp() public {
    nft = new CC("MOCK", "MOCK", "baseURI");

    nft.setPaused();

    owner = address(0xdd);

    vm.startPrank(owner);

    token = new cowClubToken("MOCK", "MOCK", 18, 1); // token emission is 1 per block

    staking = new cowClubStaking(address(nft), address(token));

    token.setStakingAddress(address(staking));

    // enable staking
    staking.flipStakingStatus();

    vm.stopPrank();

    user1 = address(0xaa);
    user2 = address(0xbb);
    user3 = address(0xcc);

    vm.deal(user1, 10000 ether);
    vm.deal(user2, 10000 ether);
    vm.deal(user3, 10000 ether);
  }

  uint256[] tokens;

  function testStake() public {
    vm.startPrank(user1);
    nft.mintNft{ value: 50 ether }(1);
    assertEq(nft.balanceOf(user1), 1);

    nft.approve(address(staking), 1);

    tokens.push(uint256(1));
    staking.stake(tokens);
  }

  function testStakeMany() public {
    vm.startPrank(user1);
    uint256 tokenCount = 10;
    nft.mintNft{ value: 500 ether }(tokenCount);

    nft.setApprovalForAll(address(staking), true);

    for (uint256 i = 1; i < tokenCount; ++i) {
      tokens.push(uint256(i));
    }

    staking.stake(tokens);

    vm.roll(block.number + 123);

    token.balanceOf(user1);
  }

  function testGetMultiplier() public {
    vm.startPrank(user1);
    nft.mintNft{ value: 50 ether }(1);
    assertEq(nft.balanceOf(user1), 1);

    nft.setApprovalForAll(address(staking), true);

    tokens.push(uint256(1));

    staking.stake(tokens);

    staking.getMultiplier(user1);
  }

  function testUnStake() public {
    vm.startPrank(user1);
    nft.mintNft{ value: 50 ether }(1);
    assertEq(nft.balanceOf(user1), 1);

    nft.setApprovalForAll(address(staking), true);

    tokens.push(uint256(1));

    staking.stake(tokens);
    vm.roll(1);
    staking.unstake(tokens);
  }

  function testTokensAccruedAfterFiveBlocks() public {
    vm.startPrank(user1);
    nft.mintNft{ value: 50 ether }(1);
    assertEq(nft.balanceOf(user1), 1);

    nft.approve(address(staking), 1);

    tokens.push(uint256(1));
    staking.stake(tokens);

    vm.roll(block.number + 1);
    assertEq(token.balanceOf(user1), 1);

    vm.roll(block.number + 1);
    assertEq(token.balanceOf(user1), 2);
  }

  uint256[] additionalTokens;

  function testTokensAccruedAfterStakeAndStakeAdditional() public {
    vm.startPrank(user1);
    nft.mintNft{ value: 500 ether }(10);

    nft.setApprovalForAll(address(staking), true);

    tokens.push(uint256(1));
    tokens.push(uint256(2));

    // stake two
    staking.stake(tokens);

    vm.roll(block.number + 1);
    assertEq(token.balanceOf(user1), 2);

    // stake two more

    additionalTokens.push(uint256(3));
    additionalTokens.push(uint256(4));

    staking.stake(additionalTokens);

    vm.roll(block.number + 1);
    assertEq(token.balanceOf(user1), 6);
  }

  function testTokensStopAccruingAfterUnstake() public {
    vm.startPrank(user1);
    nft.mintNft{ value: 100 ether }(2);

    nft.setApprovalForAll(address(staking), true);

    tokens.push(uint256(1));

    staking.stake(tokens);

    vm.roll(block.number + 1);
    // assertEq(token.balanceOf(user1), 1);

    staking.getMultiplier(user1);

    staking.unstake(tokens);

    assertEq(token.balanceOf(user1), 1);
  }

  function testCannotStakeIfNotTokenOwner() public {
    vm.startPrank(user1);
    nft.mintNft{ value: 50 ether }(1);

    nft.approve(address(staking), 1);
    vm.stopPrank();

    vm.startPrank(user2);
    tokens.push(uint256(1));
    vm.expectRevert(abi.encodeWithSignature("NotTokenOwner()"));
    staking.stake(tokens);
  }

  uint256[] user1Tokens;

  function testCannotUnstakeIfNotTokenOwner() public {
    vm.startPrank(user1);
    nft.mintNft{ value: 50 ether }(1);

    nft.approve(address(staking), 1);
    user1Tokens.push(uint256(1));
    staking.stake(user1Tokens);
    vm.stopPrank();

    vm.startPrank(user2);
    nft.mintNft{ value: 50 ether }(1);

    nft.approve(address(staking), 2);
    tokens.push(uint256(2));
    staking.stake(tokens);

    vm.expectRevert(abi.encodeWithSignature("NotTokenOwner()"));
    staking.unstake(user1Tokens);
  }

  function testCannotUnstakeWithNoStakedTokens() public {
    vm.startPrank(user1);
    tokens.push(uint256(1));
    vm.expectRevert(abi.encodeWithSignature("NoStakedTokens()"));
    staking.unstake(user1Tokens);
  }

  function testOwnerCanFlipStakingStatus() public {
    bool currentStakingStatus = staking.stakingEnabled();
    vm.startPrank(owner);

    staking.flipStakingStatus();

    vm.stopPrank();

    assert(!currentStakingStatus == staking.stakingEnabled());
  }

  function testGetTokensByOwner() public {
    vm.startPrank(user1);
    nft.mintNft{ value: 50 ether }(1);
    assertEq(nft.balanceOf(user1), 1);

    nft.approve(address(staking), 1);

    tokens.push(uint256(1));
    staking.stake(tokens);

    uint256 user1Token = staking.getTokensByOwner(user1)[0];

    assertEq(tokens[0], user1Token);
  }

  function testOnERC721Received() public {
    vm.startPrank(user1);
    nft.mintNft{ value: 50 ether }(1);

    staking.onERC721Received(address(this), address(nft), 1, abi.encode(""));

    vm.stopPrank();
  }
}
