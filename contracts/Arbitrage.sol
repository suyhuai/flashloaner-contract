pragma solidity =0.6.6;

import './libraries/PancakeLibrary.sol';
import './interfaces/IPancakeRouter02.sol';
import './interfaces/IPancakePair.sol';
import './interfaces/IPancakeERC20.sol';
import './interfaces/IPancakeFactory.sol';

contract FlashLoaner {
  address immutable pancakeFactory; // 0x81338c4e7a7f30297aF1dd1dBF02Fc1299b0EA12
  IPancakeRouter02 immutable pancakeRouter; // 0x73D58041eDdD468e016Cfbc13f3BDc4248cCD65D

  constructor(address _pancakeFactory, address _pancakeRouter) public {
    pancakeFactory = _pancakeFactory;  
    pancakeRouter = IPancakeRouter02(_pancakeRouter);
  }

  function arbitrage(
    address token0, 
    address token1, 
    uint amount0,
    uint amount1
  ) external {
    address pairAddress = IPancakeFactory(pancakeFactory).getPair(token0, token1);
    require(pairAddress != address(0), 'This pool does not exist');
    IPancakePair(pairAddress).swap(
      amount0, 
      amount1, 
      address(this), 
      bytes('not empty')
    );
  }

  function pancakeCall(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
      // by pancakeRouter,PancakeLibrary,address and IPancakeERC20
      // eg. 
      // address token0 = IPancakePair(msg.sender).token0();
      // IPancakeERC20 token = IPancakeERC20(_amount0 == 0 ? token1 : token0);
      // require(msg.sender == PancakeLibrary.pairFor(pancakeFactory, token0, token1), "Unauthorized"); 
      // uint amountRequired = PancakeLibrary.getAmountsIn(pancakeFactory, amountToken, path)[0];
      // token.transfer(_sender, amountReceived - amountRequired); // YEAHH PROFIT
  }
}