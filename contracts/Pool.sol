pragma solidity ^0.5.0;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract TestArbitrage {
  address constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address constant LoanPair = 0x3041CbD36888bECc7bbCBc0045E3B1f144466f5f;//USDC-USDT: LoanToken-RepayToken
  address constant SwapPair = 0x6591c4BcD6D7A1eb4E537DA8B78676C1576Ba244; // BOND-USDC: 0-1:SwapToken-LoanToken
  address constant LoanToken0 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant RepayToken1 = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address constant SwapToken0 = 0x0391D2021f89DC339F60Fff84546EA23E337750f;
  address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;


  event PrintArg(uint256 amount);
  event PrintIdx(uint256 index);

  constructor() public {
      safeApprove(LoanToken0,router,uint(-1));
      safeApprove(RepayToken1,router,uint(-1));
      safeApprove(SwapToken0,router,uint(-1));
  }
  
  function deposit() public payable {
      IWETH(WETH).deposit.value(msg.value)();
  }

  function go(uint256 loanAmount) external {
    //   uint256 loanAmount = 45000 * 1000000000000000000;
    IPair(LoanPair).swap(
      uint(loanAmount),
      uint(0),
      address(this),
      bytes('not empty')
    );
  }

  function uniswapV2Call(
    address sender,
    uint LoanToken0Amount,
    uint RepayToken1Amount,
    bytes calldata data
  ) external {
      address[] memory path = new address[](2);
      path[0] = LoanToken0;
      path[1] = SwapToken0;
      
      uint[] memory amounts1 = IRouter(router).swapExactTokensForTokens(uint(311717017.04323*1000000),uint(0), path, address(this), block.timestamp+1800);
      uint SwapToken0Amount = amounts1[1];



      uint[] memory amounts1 = IRouter(router).addLiquidity(SwapToken0, LoanToken0, uint(20000 * 1000000000000000000), uint(0), uint(0), uint(0),IPair(SwapPair), block.timestamp+1800);
      uint SwapTokenAmount = amounts1[1];
            
      address[] memory WETHUSDT = new address[](2);
      WETHUSDT[0] = WETH;
      WETHUSDT[1] = USDT;

      uint[] memory ETHAmount = IRouter(router).getAmountsIn(_USDTAmount, WETHUSDT);
      emit PrintArg(ETHAmount[0]);

    //   safeTransferFrom(WETH,address(this),WETHUSDTPair, ETHAmount[0]);

      IERC20(WETH).transfer(WETHUSDTPair, ETHAmount[0]);

      uint256 WETHBalance = IERC20(WETH).balanceOf(address(this));
      emit PrintArg(WETHBalance);
  }

  function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

//   function safeTransferFrom(address token, address from, address to, uint value) internal {
//         // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
//         (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
//     }
}