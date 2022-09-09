// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@erc721a/contracts/extensions/ERC721ABurnable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error TokenDoesNotExist();
error MaxSupplyReached();
error WrongAmountSent();
error MaxAmountPerTxReached();
error NoEthBalance();
error MintPaused();
error WithdrawTransfer();

/// @title Cow Club

contract CC is ERC721AQueryable, ERC721ABurnable, Ownable {
  using Strings for uint256;

  string public baseURI;

  bool public paused = true;

  uint256 public maxSupply = 10000;
  uint256 public price = .05 ether;
  uint256 public maxAmountPerTx = 10;

  /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  /// @param _name The name of the token.
  /// @param _symbol The Symbol of the token.
  /// @param _baseURI The baseURI for the token that will be used for metadata.
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseURI
  ) ERC721A(_name, _symbol) {
    baseURI = _baseURI;
  }

  /*///////////////////////////////////////////////////////////////
                               MINT FUNCTION
    //////////////////////////////////////////////////////////////*/

  /// @notice Mint NFT function.
  /// @param amount Amount of token that the sender wants to mint.
  function mintNft(uint256 amount) external payable {
    if (paused) revert MintPaused();
    if (amount > maxAmountPerTx) revert MaxAmountPerTxReached();

    uint256 currTotalSupply = totalSupply();

    if (currTotalSupply + amount > maxSupply) revert MaxSupplyReached();
    if (msg.value < price * amount) revert WrongAmountSent();

    _mint(msg.sender, amount);
  }

  /*///////////////////////////////////////////////////////////////
                               MINT CONTROLS
    //////////////////////////////////////////////////////////////*/

  function setPaused() external onlyOwner {
    paused = !paused;
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setMaxAmountPerTx(uint256 _maxAmountPerTx) external onlyOwner {
    maxAmountPerTx = _maxAmountPerTx;
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

  /// @notice Withdraw all ETH from the contract

  function withdrawPayments(address payable payee) external onlyOwner {
    uint256 balance = address(this).balance;
    (bool transferTx, ) = payee.call{ value: balance }("");
    if (!transferTx) {
      revert WithdrawTransfer();
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A, IERC721A)
    returns (string memory)
  {
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
        : "";
  }

  /*///////////////////////////////////////////////////////////////
                            REQUIRED OVERRIDES
    //////////////////////////////////////////////////////////////*/

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}
