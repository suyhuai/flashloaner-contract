pragma solidity ^0.6.2;

interface ICTokenFlashloan {
    function flashLoan(address receiver, uint amount, bytes calldata params) external;
}
