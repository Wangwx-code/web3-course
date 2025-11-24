// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Token {
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowance;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private _owner;
    uint8 private _decimals;

    constructor(string memory _name_, string memory _symbol_, uint8 _decimals_) {
        _name = _name_;
        _symbol = _symbol_;
        _owner = msg.sender;
        _decimals = _decimals_;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed account, address indexed spender, uint256 value);

    modifier isOwner() {
        require(_owner == msg.sender);
        _;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balance[account];
    }

    function transfer(address to, uint256 value) external {
        _transfer(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) external {
        _approve(msg.sender, spender, value);
        emit Approval(msg.sender, spender, value);
    }

    function allowance(address account, address spender) external view returns (uint256) {
        return _allowance[account][spender];
    }

    function transferFrom(address from, address to, uint256 value) external {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        emit Transfer(from, to, value);
    }

    function mint(address account, uint256 value) external isOwner {
        _mint(account, value);
        emit Transfer(address(0), account, value);
    }

    function burn(address account, uint256 value) external isOwner {
        _burn(account, value);
        emit Transfer(account, address(0), value);
    }

    function _update(address from, address to, uint256 value) private {
        if (from == address(0) && to == address(0)) {
            revert();
        }
        if (from == address(0)) {
            // 0 => address
            _totalSupply += value;
            unchecked {
                _balance[to] += value;
            }
        } else if (to == address(0)) {
            // address => 0
            if (_balance[from] < value) {
                revert();
            }
            unchecked {
                _balance[from] -= value;
                _totalSupply -= value;
            }
        } else {
            if (_balance[from] < value) {
                revert();
            }
            unchecked {
                _balance[from] -= value;
                _balance[to] += value;
            }
        }
    }

    function _approve(address account, address spender, uint256 value) private {
        require(account != address(0));
        require(spender != address(0));
        _allowance[account][spender] = value;
    }

    function _mint(address account, uint256 value) private {
        _update(address(0), account, value);
    }

    function _burn(address account, uint256 value) private {
        _update(account, address(0), value);
    }

    function _transfer(address from, address to, uint256 value) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _update(from, to, value);
    }

    function _spendAllowance(address account, address spender, uint256 value) private {
        require(_allowance[account][spender] >= value);
        unchecked {
            _approve(account, spender, _allowance[account][spender] - value);
        }
    }
}
