//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import "./interfaces/IERC5646.sol";
import "./TokenBundler.sol";


// TODO: Optimize gas
contract TokenBundlerOwnership is ERC721, IERC5646 {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    TokenBundler public immutable singleton;

    event TokenBundlerDeployed(address indexed bundler);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor() ERC721("PWN Bundler Ownership", "TBO") {
        // Deploy bundle bundle singleton for future clone referance
        singleton = new TokenBundler();
        singleton.initialize(address(this));
    }


    /*----------------------------------------------------------*|
    |*  # TOKEN BUNDLE FACTORY                                  *|
    |*----------------------------------------------------------*/

    // Mint new token only for a new bundle.
    // Bundle cannot be destroyed and token cannot be burned.
    function deployBundler() external returns (TokenBundler bundler) {
        bundler = TokenBundler(Clones.clone(address(singleton)));
        bundler.initialize(address(this));

        _mint(msg.sender, uint256(uint160(address(bundler))));

        emit TokenBundlerDeployed(address(bundler));
    }


    /*----------------------------------------------------------*|
    |*  # ERC165                                                *|
    |*----------------------------------------------------------*/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC5646).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    /*----------------------------------------------------------*|
    |*  # ERC5646                                               *|
    |*----------------------------------------------------------*/

    function getStateFingerprint(uint256 tokenId) external view returns (bytes32) {
        require(_exists(tokenId) == true, "Invalid token id");
        return IERC5646(address(uint160(tokenId))).getStateFingerprint(tokenId);
    }

}
