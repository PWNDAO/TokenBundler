//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @dev this is just a dummy mintable/burnable ERC20 for testing purposes
 */
contract T20 is ERC20 {
    
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {

    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

}
