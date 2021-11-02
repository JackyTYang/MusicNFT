// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20/ERC20.sol";


contract MyToken is ERC20 {
    // uint8 public constant decimals = 18;
    // uint256 public constant _totalSupply = 1000 * (10**6);  // 1 billion

    address private owner;

    constructor(uint256 _initialSupply) ERC20("Jacky's Token","JK",_initialSupply){
        _mint(msg.sender, _initialSupply* (10 ** uint256(decimals())));
    }
    function decimals() public pure override returns (uint8) {
        return 2;
    }
}