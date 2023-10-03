pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import "solmate/tokens/WETH.sol";

contract FundUSDC {
  address constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  WETH constant weth = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

  ISwapRouter swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum) external payable returns (uint256 amountIn) {
        weth.deposit{ value: msg.value }();
        TransferHelper.safeApprove(address(weth), address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: address(weth),
                tokenOut: USDC,
                fee: 500,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(address(weth), address(swapRouter), 0);
            TransferHelper.safeTransfer(address(weth), msg.sender, amountInMaximum - amountIn);
        }
    }
}
