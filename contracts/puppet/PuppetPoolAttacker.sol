// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";
import "./PuppetPool.sol";

contract PuppetPoolAttacker {
  function attack() external {
    // transfer erc-20 from user to this pool

    // approve erc-20 transfer to pool

    // sell all DVT tokens to Uniswap pool to drop the price
  }
}