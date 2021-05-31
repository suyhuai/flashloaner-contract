pragma solidity =0.6.2;

import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import './interfaces/IUniswapV2Pair.sol';

import './libraries/UniswapV2LiquidityMathLibrary.sol';

contract TestArbitrage {
  address constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address constant LoanPair = 0x3041CbD36888bECc7bbCBc0045E3B1f144466f5f;//USDC-USDT: LoanToken-RepayToken
  address constant SwapPair = 0x6591c4BcD6D7A1eb4E537DA8B78676C1576Ba244; // BOND-USDC: 0-1:SwapToken-LoanToken
  address constant LoanToken0 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant RepayToken1 = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address constant SwapToken0 = 0x0391D2021f89DC339F60Fff84546EA23E337750f;
  address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  uint deadline = block.timestamp+1800;

  event PrintArg(uint256 amount);
  event PrintIdx(uint256 index);

  constructor() public {
      safeApprove(WETH,router,uint(-1));
      safeApprove(LoanToken0,router,uint(-1));
      safeApprove(RepayToken1,router,uint(-1));
      safeApprove(SwapToken0,router,uint(-1));
  }
  
  function deposit() public payable {
      IWETH(WETH).deposit.value(msg.value)();
  }

  function go(uint256 loanAmount) external {
    //   uint256 loanAmount = 45000 * 1000000000000000000;
    IUniswapV2Pair(LoanPair).swap(
      uint(loanAmount),
      uint(0),
      address(this),
      bytes('not empty')
    );
  }
  
  event Amounts(uint amount0,uint amount1);

  function uniswapV2Call(
    address sender,
    uint LoanToken0Amount,
    uint RepayToken1Amount,
    bytes calldata data
  ) external {
      address[] memory path = new address[](2);
      path[0] = LoanToken0;
      path[1] = SwapToken0;
      
      (uint reserve0, uint reserve1) = UniswapV2Library.getReserves(factory, SwapToken0, LoanToken0);
      emit Amounts(reserve0,reserve1);
      
      // uint[] memory amounts1 = IUniswapV2Router02(router).swapTokensForExactTokens(uint(reserve0/10),uint(-1), path, address(this), deadline);
      // emit Amounts(amounts1[0],amounts1[1]);
    //   uint SwapToken0Amount = amounts1[1];

      // uint[] memory amounts1 = router.swapExactTokensForTokens(LoanToken0Amount,uint(0), path, address(this), deadline);
      // uint SwapToken0Amount = amounts1[0];

      // uint[] memory amounts1 = router.swapExactTokensForTokens(uint(311717017.04323*1000000),uint(0), path, address(this), deadline);
      // uint SwapToken0Amount = amounts1[1];

      uint[] memory RepayAmounts = IUniswapV2Router02(router).getAmountsIn(LoanToken0Amount, path);
      emit Amounts(RepayAmounts[0],RepayAmounts[1]);
      
      path[0] = WETH;
      path[1] = RepayToken1;

    //   safeTransferFrom(WETH,address(this),WETHUSDTPair, ETHAmount[0]);

      IERC20(RepayToken1).transfer(LoanPair, RepayAmounts[1]);
  }

  function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
  }
  
  function testGetReserves() external {
      (uint reserve0, uint reserve1) = UniswapV2Library.getReserves(factory, SwapToken0, LoanToken0); // sort by token in params
      emit Amounts(reserve0,reserve1);
      
    //   address[] memory path = new address[](2);
    //   path[0] = WETH;
    //   path[1] = RepayToken1;
      
    //   uint[] memory amounts1 = IUniswapV2Router02(router).swapTokensForExactTokens(uint(1000000000),uint(-1), path, address(this), deadline);
    //   emit Amounts(amounts1[0],amounts1[1]);
      
    //   uint[] memory amounts2 = IUniswapV2Router02(router).swapExactTokensForTokens(uint(1000000000),uint(0), path, address(this), deadline);
    //   emit Amounts(amounts2[0],amounts2[1]);
  }
  
  function testSwap() external {
      
      address[] memory path = new address[](2);
      path[0] = WETH;
      path[1] = LoanToken0;
      
     uint balance = IERC20(WETH).balanceOf(address(this));
     emit PrintArg(balance);
      
      uint[] memory amounts1 = IUniswapV2Router02(router).swapExactTokensForTokens(balance/10,uint(0), path, address(this), deadline);
      emit Amounts(amounts1[0],amounts1[1]); // sort same to path
      
       uint[] memory amounts2 = IUniswapV2Router02(router).swapTokensForExactTokens(amounts1[1],uint(-1), path, address(this), deadline);
      emit Amounts(amounts2[0],amounts2[1]);
  }
  
  function testLiquidityOpera() external {
      (uint reserve0, uint reserve1) = UniswapV2Library.getReserves(factory, WETH, LoanToken0); // sort by token in params
      emit Amounts(reserve0,reserve1);
      
      address[] memory path = new address[](2);
      path[0] = WETH;
      path[1] = LoanToken0;
      
      uint[] memory amounts1 = IUniswapV2Router02(router).swapTokensForExactTokens(reserve1/10,uint(-1), path, address(this), deadline);
      emit Amounts(amounts1[0],amounts1[1]); // sort same to path
      
    //   uint[] memory amounts1 = IUniswapV2Router02(router).swapExactTokensForTokens(reserve1/10,uint(0), path, address(this), deadline);
    //   emit Amounts(amounts1[0],amounts1[1]); // sort same to path
      
      (reserve0, reserve1) = UniswapV2Library.getReserves(factory, WETH, LoanToken0); // sort by token in params
      emit Amounts(reserve0,reserve1);
      
      
      uint balanceToken = IERC20(LoanToken0).balanceOf(address(this));
      uint balanceWETH = IERC20(WETH).balanceOf(address(this));
     emit Amounts(balanceToken,balanceWETH);
      
    //   (uint256 amount0, uint256 amount1) = UniswapV2LiquidityMathLibrary.getLiquidityValue(factory,WETH,LoanToken0,uint(1));
    //   emit Amounts(amount0,amount1);
      
      (uint amountA, uint amountB, uint liquidity) = IUniswapV2Router02(router).addLiquidity(WETH,LoanToken0,balanceWETH,balanceToken,uint(0),uint(0),
        UniswapV2Library.pairFor(factory,WETH,LoanToken0), deadline);
        emit Amounts(amountA,amountB);
        emit PrintArg(liquidity);
        
        (reserve0, reserve1) = UniswapV2Library.getReserves(factory, WETH, LoanToken0); // sort by token in params
      emit Amounts(reserve0,reserve1);
      
      (uint amountInToSwap, uint amountOutToTransfer) = IUniswapV2Router02(router).removeLiquidity(
            WETH,LoanToken0,liquidity,0,0,address(this),deadline
        );
        emit Amounts(amountInToSwap,amountOutToTransfer);
  }
}