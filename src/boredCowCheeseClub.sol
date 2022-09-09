// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@erc721a/contracts/ERC721A.sol";
import { IcowClubToken } from "./interfaces/IcowClubToken.sol";
import { IcowClub } from "./interfaces/IcowClub.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error TokenDoesNotExist();
error MaxSupplyByBurningNFTReached();
error MaxSupplyByBurningToken();
error MaxAmountPerTxReached();
error MintPaused();
error WithdrawTransfer();
error TierTwoLimitLessThanTierOne();
error SenderNotTokenOwner();

/// @title Bored Cow Cheese club

contract BCCC is ERC721A, Ownable {
  using Strings for uint256;

  string public baseURI;

  address immutable burnAddress = address(0xdead);

  bool public paused = true;

  uint256 public maxSupply = 10000;
  uint256 private initialPrice = 250;
  uint256 public maxAmountPerTx = 50;
  uint256 public countMintedByToken = 0;
  uint256 public maxMintedByBurningNFT = 2500;
  uint256 public priceTierOneLimit = 2500;
  uint256 public priceTierTwoLimit = 5000;
  uint256 public maxMintedByBurningToken = 7500;

  address public tokenAddress;
  address public cowClubAddress;

  /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  /// @param _name The name of the token.
  /// @param _symbol The Symbol of the token.
  /// @param _baseURI The baseURI for the token that will be used for metadata.
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseURI,
    address _tokenAddress,
    address _cowClubAddress
  ) ERC721A(_name, _symbol) {
    baseURI = _baseURI;
    tokenAddress = _tokenAddress;
    cowClubAddress = _cowClubAddress;
  }

  function mintPrice() public view returns (uint256) {
    uint256 _countMintedByToken = countMintedByToken;
    uint256 price;

    if (_countMintedByToken < priceTierOneLimit) {
      price = initialPrice;
    } else if (_countMintedByToken < priceTierTwoLimit) {
      price = initialPrice * 2;
    } else {
      price = initialPrice * 3;
    }

    return price;
  }

  /*///////////////////////////////////////////////////////////////
                               MINT FUNCTION
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Mint NFT using ERC20 token.
   * @dev burn CowClub ERC20 token to get BDKC NFTs. The price changes based on how many have minted
   * @param amount Amount of token that the sender wants to mint.
   */
  function mintByToken(uint256 amount) external payable {
    if (paused) revert MintPaused();
    if (amount > maxAmountPerTx) revert MaxAmountPerTxReached();

    uint256 mintCost = amount * mintPrice();

    uint256 currTotalSupply = totalSupply();

    if (currTotalSupply + amount > maxMintedByBurningToken) revert MaxSupplyByBurningToken();

    // burn token spent to mint
    IcowClubToken(tokenAddress).burn(msg.sender, mintCost);

    countMintedByToken += amount;

    _mint(msg.sender, amount);
  }

  /**
   * @notice Mint by burning other NFT
   * @dev burn cowClub NFTs to get BDKC NFTs. Each BDKC NFT costs 2 cowClub NFTs
   * @param tokenIdsToBurn array of tokens the sender is requesting to burn
   */

  function mintByBurnNFT(uint256[] calldata tokenIdsToBurn) external {
    if (paused) revert MintPaused();

    // will always give whole number rounded towards zero
    uint256 tokensToMint = tokenIdsToBurn.length / 3;
    uint256 tokenCountToBurn = tokensToMint * 3;

    if (tokensToMint > maxAmountPerTx) revert MaxAmountPerTxReached();

    uint256 currTotalSupply = totalSupply();
    if (currTotalSupply + tokensToMint > maxMintedByBurningNFT)
      revert MaxSupplyByBurningNFTReached();

    // burn NFTs
    for (uint256 i = 0; i < tokenCountToBurn; i++) {
      uint256 tokenId = tokenIdsToBurn[i];

      if (IcowClub(cowClubAddress).ownerOf(tokenId) != msg.sender) revert SenderNotTokenOwner();

      // burn cowClub tokens. Note: costs 3 cowClub to mint one DADC
      IcowClub(cowClubAddress).burn(tokenId);
    }

    // mint token
    _mint(msg.sender, tokensToMint);
  }

  /*///////////////////////////////////////////////////////////////
                               MINT CONTROLS
    //////////////////////////////////////////////////////////////*/

  function setPaused() external onlyOwner {
    paused = !paused;
  }

  function setMaxMintedByBurningNFT(uint256 _maxMintedByBurningNFT) external onlyOwner {
    maxMintedByBurningNFT = _maxMintedByBurningNFT;
  }

  function setMaxMintedByBurningToken(uint256 _maxMintedByBurningToken) external onlyOwner {
    maxMintedByBurningToken = _maxMintedByBurningToken;
  }

  function setInitialPrice(uint256 _initialPrice) external onlyOwner {
    initialPrice = _initialPrice;
  }

  function setMaxAmountPerTx(uint256 _maxAmountPerTx) external onlyOwner {
    maxAmountPerTx = _maxAmountPerTx;
  }

  function setPriceTierOneLimit(uint256 _priceTierOneLimit) external onlyOwner {
    priceTierOneLimit = _priceTierOneLimit;
  }

  function setPriceTierTwoLimit(uint256 _priceTierTwoLimit) external onlyOwner {
    if (_priceTierTwoLimit < priceTierOneLimit) {
      revert TierTwoLimitLessThanTierOne();
    }

    priceTierTwoLimit = _priceTierTwoLimit;
  }

  /*///////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  /*///////////////////////////////////////////////////////////////
                            TOKEN WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

  /// @notice Withdraw all ETH/native token from the contract

  function withdrawPayments(address payable payee) external onlyOwner {
    uint256 balance = address(this).balance;
    (bool transferTx, ) = payee.call{ value: balance }("");
    if (!transferTx) {
      revert WithdrawTransfer();
    }
  }

  // function withdrawTokens(IERC20 token) public onlyOwner {
  //   uint256 balance = token.balanceOf(address(this));
  //   token.transfer(msg.sender, balance);
  // }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
        : "";
  }
}
