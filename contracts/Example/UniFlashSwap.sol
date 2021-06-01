pragma solidity =0.6.2;

import '../uniswap/interfaces/IUniswapV2Router02.sol';
import '../uniswap/interfaces/IERC20.sol';
import '../uniswap/interfaces/IWETH.sol';
import '../uniswap/interfaces/IUniswapV2Pair.sol';

import '../uniswap/libraries/UniswapV2LiquidityMathLibrary.sol';

contract Job {
  address constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address constant RepayToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC:token0
  address constant LoanToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH:token1
  address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant RelayToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // 中继币种USDT
  address constant OtherToken = 0xAd4f86a25bbc20FfB751f2FAC312A0B4d8F88c64; // ROOM

  uint deadline = block.timestamp+1800;
  uint loanAmount;
  uint liquidity;

  constructor() public {
      safeApprove(WETH,router,uint(-1));
      safeApprove(LoanToken,router,uint(-1));
      safeApprove(RepayToken,router,uint(-1));
      safeApprove(OtherToken,router,uint(-1));
  }
  
  function deposit() public payable {
      IWETH(WETH).deposit.value(msg.value)();
  }

  function go(uint _loanAmount) external {
    IUniswapV2Pair(UniswapV2Library.pairFor(factory, LoanToken, RepayToken)).swap(
      uint(0),
      _loanAmount*1000000000000000000,
      address(this),
      bytes('not empty')
    );
  }

  //gogogogogogogogogogogogogogogogogogogogogogogogo
  event loanAmountEvent(uint amount);
  event finallyLoanAmountEvent(uint amount);
  event finallyTargetPairReverse(uint amount0,uint amount1);
  function uniswapV2Call(
    address _sender,
    uint _zeroAmount,
    uint _loanAmount,
    bytes calldata _data
  ) external {
    loanAmount = _loanAmount;
    emit loanAmountEvent(loanAmount);
    
    // swapOtherToken();
    
    addLiquidity();
    
    addLiquidity();
    // swapLoanToken();
    
    removeLiquidity();
    
    swapLoanToken();
    
    repayToken();
    
    uint balanceLoanToken = IERC20(LoanToken).balanceOf(address(this));
    emit finallyLoanAmountEvent(balanceLoanToken);
    
    (uint reserveLoanToken, uint reserveOtherToken)= UniswapV2Library.getReserves(factory, LoanToken, OtherToken); // 返回结果和传参顺序一致
    emit finallyTargetPairReverse(reserveLoanToken,reserveOtherToken);
  }

  // 兑换目标代币，rate为兑换目标代币的百分比,兑换方向从token0到token1
  event swapOtherTokenReserve(uint amount0,uint amount1);
  event swapOtherTokenSwap(uint amount0,uint amount1);
  function swapOtherToken() internal{
      (uint reserveLoanToken, uint reserveOtherToken)= UniswapV2Library.getReserves(factory, LoanToken, OtherToken); // 返回结果和传参顺序一致
      emit swapOtherTokenReserve(reserveLoanToken,reserveOtherToken);
      
      address[] memory path = new address[](2);
      path[0] = LoanToken;
      path[1] = OtherToken;
      
      uint[] memory amounts = IUniswapV2Router02(router).swapExactTokensForTokens(loanAmount/2,uint(0), path, address(this), deadline);
      emit swapOtherTokenSwap(amounts[0],amounts[1]); 
      
  }


  // 添加流动性，rate为目标token(token1)余额的百分比
  event addLiquidityBalance(uint amount0,uint amount1);
  event addLiquidityRateEvent(uint amount);
  event addLiquiditySwap(uint amount0,uint amount1);
  event addLiquidityLiquidity(uint amount);
  function addLiquidity() internal{
        
        (uint reserveLoanToken, uint reserveOtherToken)= UniswapV2Library.getReserves(factory, LoanToken, OtherToken);
        uint swapInAmount = calculateSwapInAmount(reserveLoanToken,loanAmount/2);
        
        address[] memory path = new address[](2);
        path[0] = LoanToken;
        path[1] = OtherToken;
        uint[] memory amounts = IUniswapV2Router02(router).swapExactTokensForTokens(swapInAmount,uint(0), path, address(this), deadline);

        (uint amount0,uint amount1, uint _liquidity) = IUniswapV2Router02(router).addLiquidity(LoanToken,OtherToken,swapInAmount,amounts[1],uint(0),uint(0),address(this), deadline);
        liquidity += _liquidity;
        emit addLiquidityLiquidity(liquidity);
  }

  // 兑换借款代币
  event swapLoanTokenBalance(uint amount0,uint amount1);
  event swapLoanTokenAmountsIn(uint amount0,uint amount1);
  function swapLoanToken() internal{
      uint balanceOtherToken = IERC20(OtherToken).balanceOf(address(this));
      address[] memory path = new address[](2);
      path[0] = OtherToken;
      path[1] = LoanToken;
      
      uint[] memory amounts = IUniswapV2Router02(router).swapExactTokensForTokens(balanceOtherToken,uint(0), path, address(this), deadline);
      emit swapLoanTokenAmountsIn(amounts[0],amounts[1]); 
  }

  
  // 移除流动性，注意检查添加流动性时的接收者必须是合约本身
  event removeLiquidityRemove(uint amount0,uint amount1);
  function removeLiquidity() internal{
        safeApprove(UniswapV2Library.pairFor(factory, LoanToken, OtherToken),router,liquidity);
      
        (uint amount0, uint amount1) = IUniswapV2Router02(router).removeLiquidity(LoanToken, OtherToken,liquidity,0,0,address(this),deadline);
        emit removeLiquidityRemove(amount0,amount1);
  }

  // 还款
  function repayToken() internal{
    //   address[] memory path = new address[](2);
    //   path[0] = LoanToken;
    //   path[1] = RepayToken;
    //   uint[] memory RepayAmounts = IUniswapV2Router02(router).getAmountsIn(loanAmount, path);
    //   emit Info2(RepayAmounts[0],RepayAmounts[1]);
      
    //   path[0] = LoanToken;
    //   path[1] = RepayToken;
    //   IUniswapV2Router02(router).swapTokensForExactTokens(RepayAmounts[0],uint(-1), path, address(this), deadline);
      
    //   IERC20(RepayToken).transfer(UniswapV2Library.pairFor(factory, LoanToken, RepayToken), RepayAmounts[0]);
      
      forTest();
  }
  
  function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
  function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
  }
  
  function calculateSwapInAmount(uint reserveIn, uint userIn) public pure returns (uint) {
        // return Babylonian.sqrt(reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009))).sub(reserveIn.mul(1997)) / 1994;
        return SafeMath.sub(Babylonian.sqrt(SafeMath.mul(reserveIn,SafeMath.mul(userIn,3988000) + SafeMath.mul(reserveIn,3988009))),SafeMath.mul(reserveIn,1997)) / 1994;
  }
  
  event finallyRepayAmount(uint amount0,uint amount1);
  function forTest()internal{
      address[] memory path1 = new address[](2);
      path1[0] = RepayToken;
      path1[1] = LoanToken;
      uint[] memory Amounts = IUniswapV2Router02(router).getAmountsIn(loanAmount, path1);
      
      
      address[] memory path2 = new address[](3);
      path2[0] = LoanToken;
      path2[1] = RelayToken;
      path2[2] = RepayToken;
      uint[] memory amounts2 = IUniswapV2Router02(router).swapTokensForExactTokens(Amounts[0],uint(-1), path2, address(this), deadline);
      
      emit finallyRepayAmount(amounts2[0],Amounts[0]);
      IERC20(RepayToken).transfer(UniswapV2Library.pairFor(factory, LoanToken, RepayToken), Amounts[0]);
  }
}