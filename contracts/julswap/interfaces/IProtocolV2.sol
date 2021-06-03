pragma solidity >=0.6.2;


interface IProtocolV2{

    function calculatePercent(uint256 _eth, uint256 _percent) external pure returns (uint256 interestAmt);

    function addBNB() external payable returns (
            uint256 amountToken,
            uint256 amountBNB,
            uint256 liquidity
    );

    function readUsersDetails(address _user) external view returns (
            uint256 td,
            uint256 trd,
            uint256 trwi
    );

    function removeBNB(uint256 _amountBNB, uint256 amountOutMin) external payable returns(
        uint256 amountToken, 
        uint256 amountBNB
    );

 
    function getLiquidityBalance() external view returns (uint256 liquidity);

    /// @return The balance of the contract
    function protocolBalance() external view returns (uint256);
}