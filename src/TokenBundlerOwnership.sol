//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";


contract TokenBundlerOwnership is ERC721("PWN Bundler Ownership", "TBO") {

    function mintOwnership(address owner) external {
        uint256 tokenId = uint256(uint160(msg.sender));
        _mint(owner, tokenId);
    }

}
