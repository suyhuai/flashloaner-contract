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
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract TestArbitrage {
  address constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address constant WETHUSDTPair = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
  address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  
  event Balance(uint256 amount);
  event Log(bytes log);

  constructor() public {
      safeApprove(WETH,router,uint(-1));
      safeApprove(USDT,router,uint(-1));
      safeApprove(USDC,router,uint(-1));
  }
  
  function deposit() public payable {
      IWETH(WETH).deposit.value(msg.value)();
  }

  function go(uint loanAmount) external {
      emit Balance(loanAmount);
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
      emit Log("in uniswapV2Call");
      uint256 USDTBalance = IERC20(USDT).balanceOf(address(this));
      emit Balance(USDTBalance);
      emit Balance(_USDTAmount);

      address[] memory USDCUSDT = new address[](2);
      USDCUSDT[0] = USDT;
      USDCUSDT[1] = USDC;

      uint[] memory USDCAmount = IRouter(router).swapExactTokensForTokens(_USDTAmount,uint(0), USDCUSDT, address(this), block.timestamp+1800);
      emit Balance(USDCAmount[1]);

      address[] memory USDCWETH = new address[](2);
      USDCWETH[0] = USDC;
      USDCWETH[1] = WETH;

      uint[] memory WETHAmount = IRouter(router).swapExactTokensForTokens(USDCAmount[1],uint(0), USDCWETH, address(this), block.timestamp+1800);
      emit Balance(WETHAmount[1]);

      address[] memory WETHUSDT = new address[](2);
      WETHUSDT[0] = WETH;
      WETHUSDT[1] = USDT;

      uint[] memory ETHAmount = IRouter(router).getAmountsIn(_USDTAmount, WETHUSDT);
      emit Balance(ETHAmount[0]);

    //   safeTransferFrom(WETH,address(this),WETHUSDTPair, ETHAmount[0]);

      IERC20(WETH).transfer(WETHUSDTPair, ETHAmount[0]);

      uint256 WETHBalance = IERC20(WETH).balanceOf(address(this));
      emit Balance(WETHBalance);
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