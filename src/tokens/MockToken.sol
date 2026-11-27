// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "../interface/IERC20.sol";
import {Access} from "../security/Access.sol";

/// @notice Fixed-decimal ERC-20 with exact transfers for the local Anvil market.
abstract contract MockToken is IERC20 {
    string public name;
    string public symbol;
    uint8 public immutable decimals;
    address public immutable minter;
    uint256 public totalSupply;
    mapping(address account => uint256) public balanceOf;
    mapping(address owner => mapping(address spender => uint256)) public allowance;

    error InsufficientBalance(address account);
    error InsufficientAllowance(address owner, address spender);

    constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, address tokenMinter) {
        Access.requireNonZero(tokenMinter);
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        minter = tokenMinter;
    }

    function mint(address to, uint256 amount) external {
        Access.requireCaller(minter);
        Access.requireNonZero(to);
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        Access.requireNonZero(spender);
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 approved = allowance[from][msg.sender];
        if (approved != type(uint256).max) {
            if (approved < amount) revert InsufficientAllowance(from, msg.sender);
            allowance[from][msg.sender] = approved - amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        Access.requireNonZero(from);
        Access.requireNonZero(to);
        uint256 current = balanceOf[from];
        if (current < amount) revert InsufficientBalance(from);
        balanceOf[from] = current - amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
}
