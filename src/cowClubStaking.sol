// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721A } from "@erc721a/contracts/IERC721A.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IcowClubToken.sol";

error NotTokenOwner();
error NoStakedTokens();
error NoTokensSentToStake();
error StakingNotEnabled();

contract cowClubStaking is Ownable, ReentrancyGuard, IERC721Receiver {
  uint256 public blocksPerHour = 1800;

  bool public stakingEnabled = false;

  // Interfaces for ERC20 and ERC721A
  // IERC20 public immutable rewardsToken;
  IERC721A cowClubNFT;
  IcowClubToken public immutable cowClubToken;

  // Mapping of Token Id to staker.
  mapping(uint256 => address) public tokenToStaker;

  // Constructor function
  constructor(address _cowClubAddress, address _cowClubTokenAddress) {
    cowClubNFT = IERC721A(_cowClubAddress);
    cowClubToken = IcowClubToken(_cowClubTokenAddress);
  }

  /**
   * @dev Stake token in smart contract
   * @dev We need to call the Token contract to start the drip
   * @param _tokenIds array of tokens to stake
   */

  function stake(uint256[] calldata _tokenIds) external nonReentrant {
    if (!stakingEnabled) {
      revert StakingNotEnabled();
    }

    uint256 len = _tokenIds.length;

    if (len == 0) {
      revert NoTokensSentToStake();
    }

    for (uint256 i = 0; i < len; ++i) {
      if (cowClubNFT.ownerOf(_tokenIds[i]) != msg.sender) {
        revert NotTokenOwner();
      }

      cowClubNFT.transferFrom(msg.sender, address(this), _tokenIds[i]);

      tokenToStaker[_tokenIds[i]] = msg.sender;
    }

    cowClubToken.startDripping(msg.sender, len);
  }

  /**
   * @dev Unstake a given set of token Ids
   * @dev We need to call the Token contract to stop the drip
   * @param _tokenIds array of tokens to unstake
   */

  function unstake(uint256[] calldata _tokenIds) external nonReentrant {
    if (getMultiplier(msg.sender) < 1) {
      revert NoStakedTokens();
    }

    uint256 len = _tokenIds.length;

    uint256 validUnstakeCount = 0;

    for (uint256 i; i < len; ++i) {
      if (tokenToStaker[_tokenIds[i]] != msg.sender) {
        revert NotTokenOwner();
      }
      tokenToStaker[_tokenIds[i]] = address(0);

      validUnstakeCount++;

      cowClubNFT.transferFrom(address(this), msg.sender, _tokenIds[i]);
    }

    // cowClubToken.stopDripping(msg.sender, validUnstakeCount);
  }

  /**
   * @dev Flip to allow/disallow staking
   */

  function flipStakingStatus() external onlyOwner {
    stakingEnabled = !stakingEnabled;
  }

  //////////
  // View //
  //////////

  function getMultiplier(address _addr) public view returns (uint256) {
    return cowClubToken.accruerMultiplier(_addr);
  }

  // should never be used inside of transaction because of gas fee
  function getTokensByOwner(address addr) public view returns (uint256[] memory ownerTokens) {
    uint256 supply = cowClubNFT.totalSupply();
    uint256[] memory tmp = new uint256[](supply);

    uint256 index = 0;

    for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
      if (tokenToStaker[tokenId] == addr) {
        tmp[index] = tokenId;
        index += 1;
      }
    }

    uint256[] memory tokens = new uint256[](index);

    for (uint256 i = 0; i < index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}
