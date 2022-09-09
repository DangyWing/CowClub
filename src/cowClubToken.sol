// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./GIGADRIP20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract cowClubToken is GIGADRIP20, Ownable {
  error NotOwnerOrStakingContract();
  using SafeMath for uint256;

  address public staking;

  uint256 private _totalSupply;

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint128 _emissionRatePerBlock
  ) GIGADRIP20(_name, _symbol, _decimals, _emissionRatePerBlock) {}

  function startDripping(address addr, uint256 multiplier) external virtual {
    if (msg.sender != staking && msg.sender != owner()) revert NotOwnerOrStakingContract();
    _startDripping(addr, multiplier);
  }

  function stopDripping(address addr, uint256 multiplier) external virtual {
    if (msg.sender != staking && msg.sender != owner()) revert NotOwnerOrStakingContract();
    _stopDripping(addr, multiplier);
  }

  function setStakingAddress(address _stakingAddress) public onlyOwner {
    staking = _stakingAddress;
  }

  function burn(address from, uint256 value) external virtual {
    _burn(from, value);
  }
}
