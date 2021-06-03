// Note that this is not the production code
pragma solidity 0.5.6;

import "./IERC20.sol";

contract Wallet {
    address internal token = 0x123...<hot_wallet_addr>;
    address internal hotWallet = 0x321...<hot_wallet_addr>;

    constructor() public {
        // send all tokens from this contract to hotwallet
        IERC20(token).transfer(
            hotWallet,
            IERC20(token).balanceOf(address(this))
        );
        // selfdestruct to receive gas refund and reset nonce to 0
        selfdestruct(address(0x0));
    }
}

contract Fabric {
    function createContract(uint256 salt) public {
        // get wallet init_code
        bytes memory bytecode = type(Wallet).creationCode;
        assembly {
            let codeSize := mload(bytecode) // get size of init_bytecode
            let newAddr := create2(
                0, // 0 wei
                add(bytecode, 32), // the bytecode itself starts at the second slot. The first slot contains array length
                codeSize, // size of init_code
                salt // salt from function arguments
            )
        }
    }
}