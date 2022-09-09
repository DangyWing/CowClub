// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IcowClubToken {
  function mint(uint256 amount) external;

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Add an address to start dripping tokens to.
   * @dev IMPORTANT: Everytime you call this with an addr already getting dripped to, it will INCREASE the multiplier
   * @param addr address to drip to
   * @param multiplier used to increase token drip. ie if 1 NFT drips 10 tokens per block and this address has 3 NFTs,
   * the user would need to get dripped 30 tokens per block - multipler would multiply emissions by 3
   */
  function startDripping(address addr, uint256 multiplier) external;

  /**
   * @dev Add an address to stop dripping tokens to
   * @dev IMPORTANT: Decrease the multiplier to 0 to completely stop the address from getting dripped to
   * @param addr address to stop dripping to
   * @param multiplier used to decrease token drip. ie if addr has a multiplier of 3 already, passing in a value of 1 would decrease
   * the multiplier to 2
   */
  function stopDripping(address addr, uint256 multiplier) external;

  /**
   * @dev returns the token's total emissions per block
   */
  function getEmissionsPerBlock() external view returns (uint256);

  /**
   * @dev returns the address's current balance
   */
  function getAccruerBalance(address addr) external view returns (uint256);

  /**
   * @dev returns the address's current accruer multiplier aka how many tokens they receive per block
   */
  function accruerMultiplier(address addr) external view returns (uint256);

  /**
   * @dev 'burns' a given amount of the token from a given address
   */
  function burn(address from, uint256 value) external;

  /**
   * @dev Returns the amount of tokens owned by an address that a given address can spend
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `to`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address to, uint256 amount) external returns (bool);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `from` to `to` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}
