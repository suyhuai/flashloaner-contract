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
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract TestArbitrage {
  address constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address constant WETHUSDTPair = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
  address constant WETHROOTPair = 0x01f8989c1e556f5c89c7D46786dB98eEAAe82c33;
  address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address constant ROOT = 0xCb5f72d37685C3D5aD0bB5F982443BC8FcdF570E;


event PrintArg(uint256 amount);
  event PrintIdx(uint256 index);

  constructor() public {
      safeApprove(WETH,router,uint(-1));
      safeApprove(USDT,router,uint(-1));
      safeApprove(ROOT,router,uint(-1));
  }
  
  function deposit() public payable {
      IWETH(WETH).deposit.value(msg.value)();
  }

  function go(uint256 loanAmount) external {
    //   uint256 loanAmount = 45000 * 1000000000000000000;
    IPair(WETHUSDTPair).swap(
      uint(0),
      uint(loanAmount),
      address(this),
      bytes('not empty')
    );
  }

  function uniswapV2Call(
    address sender,
    uint _WETHAmount,
    uint _USDTAmount,
    bytes calldata data
  ) external {
      emit PrintIdx(0);
     

      address[] memory WETHROOT = new address[](2);
      WETHROOT[0] = WETH;
      WETHROOT[1] = ROOT;
      
      
          uint[] memory amounts = IRouter(router).swapExactTokensForTokens(uint(40000*1000000000000000000),uint(0), WETHROOT, address(this), block.timestamp+1800);
            uint ROOTAmount = amounts[1];
            
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