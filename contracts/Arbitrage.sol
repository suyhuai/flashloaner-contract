pragma solidity =0.6.6;

import './libraries/PancakeLibrary.sol';
import './interfaces/IPancakeRouter02.sol';
import './interfaces/IPancakePair.sol';
import './interfaces/IPancakeERC20.sol';
import './interfaces/IPancakeFactory.sol';

contract Arbitrage {
  address public owner;
  address public pancakeFactory;
  IPancakeRouter02 public otherRouter;

  constructor(address _pancakeFactory, address _otherRouter) public {
    owner = msg.sender;
    pancakeFactory = _pancakeFactory;  
    otherRouter = IPancakeRouter02(_otherRouter);
  }
  
  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }
  
  function setRouter(address _otherRouter) public restricted {
    otherRouter = IPancakeRouter02(_otherRouter);
  }

  function startArbitrage(
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

  function pancakeCall(
    address _sender, 
    uint _amount0, 
    uint _amount1, 
    bytes calldata _data
  ) external {
    address[] memory path = new address[](2);
    uint amountToken = _amount0 == 0 ? _amount1 : _amount0;
    
    address token0 = IPancakePair(msg.sender).token0();
    address token1 = IPancakePair(msg.sender).token1();

    require(msg.sender == PancakeLibrary.pairFor(pancakeFactory, token0, token1), 'Unauthorized'); 
    require(_amount0 == 0 || _amount1 == 0);

    path[0] = _amount0 == 0 ? token1 : token0;
    path[1] = _amount0 == 0 ? token0 : token1;

    IPancakeERC20 token = IPancakeERC20(_amount0 == 0 ? token1 : token0);
    
    token.approve(address(otherRouter), amountToken);

    uint amountRequired = PancakeLibrary.getAmountsIn(
      pancakeFactory, 
      amountToken, 
      path
    )[0];
    
    uint deadline = now + 1000;
    
    uint amountReceived = otherRouter.swapExactTokensForTokens(
      amountToken, 
      amountRequired, 
      path, 
      msg.sender, 
      deadline
    )[1];

    IPancakeERC20 otherToken = IPancakeERC20(_amount0 == 0 ? token0 : token1);
    otherToken.transfer(msg.sender, amountRequired);
    otherToken.transfer(tx.origin, amountReceived - amountRequired);
  }
}