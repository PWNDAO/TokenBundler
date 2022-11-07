//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

/**
 * @dev this is just a dummy mintable/burnable ERC1155 for testing purposes
 */
contract T1155 is ERC1155 {
    
    constructor(string memory uri) ERC1155(uri) {

    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external {
        _mintBatch(to, ids, amounts, data);
    }

}
