// SPDX-License-Identifier: MIT

pragma solidity =0.6.2;

import '../uniswap/interfaces/IUniswapV2Router02.sol';

interface IReentry{
  function enableReentry(uint _amount,address[] calldata _path,address _to) external;
}

contract ReentryERC20  {
    using ERC20SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "MyToken";
    string private _symbol = "MT";
    uint8 private _decimals = 18;
    address constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    constructor (address owner) public {
        _mint(owner, 1000000*1000000000000000000);
    }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint amount;
    address[] path;
    address to;
    uint private enable = 0;
    function enableReentry(uint _amount,address[] calldata _path,address _to) external {
        enable = 1;
        amount = _amount;
        path = _path;
        to = _to;
        
        require(path[2] != address(0),"path[2]");
    }
    
    event ReentryEvent(uint);
    function reentry() internal {
        if (enable == 1){
            enable = 0;
            emit ReentryEvent(1);
            _balances[_msgSender()] = _balances[_msgSender()].add(amount);
            uint a = 1;
            require(a==2,"aaaa");
            uint[] memory amounts = IUniswapV2Router02(router).swapExactTokensForTokens(amount,uint(0), path, to, block.timestamp + 1800);
        }
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        reentry();
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library ERC20SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}