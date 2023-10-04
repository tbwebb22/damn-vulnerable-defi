// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
// import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import "@uniswap/v3-core/contracts/libraries/TransferHelper.sol";
// import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "../DamnValuableToken.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

interface IUniswapV3Pool {
    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

contract Swapper is IUniswapV3SwapCallback, ERC721Holder {
  address public poolAddress;
  address public wethAddress;
  address public dvtAddress;
  address public playerAddress;

  constructor(address _poolAddress, address _wethAddress, address _dvtAddress, address _playerAddress) {
    poolAddress = _poolAddress;
    wethAddress = _wethAddress;
    dvtAddress = _dvtAddress;
    playerAddress = _playerAddress;
  }

  function swap(int256 _dvtAmount) external {
    DamnValuableToken(dvtAddress).transferFrom(msg.sender, (address(this)), uint256(_dvtAmount));
    IUniswapV3Pool(poolAddress).swap(playerAddress, false, _dvtAmount, 1461446703485210103287273052203988822378723970341, "");
  }

  function uniswapV3SwapCallback(
      int256 amount0Delta,
      int256 amount1Delta,
      bytes calldata data
  ) external {
    // console.log("inside callback");
    // console.log("amount0Delta: ");
    // console.logInt(amount0Delta);
    // console.log("amount1Delta: ");
    // console.logInt(amount1Delta);
    DamnValuableToken(dvtAddress).transfer(poolAddress, uint256(amount1Delta));
  } 
}