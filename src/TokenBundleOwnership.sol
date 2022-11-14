//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import "./interfaces/IERC5646.sol";
import "./TokenBundle.sol";


// TODO: Optimize gas
contract TokenBundleOwnership is ERC721, IERC5646 {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    TokenBundle public immutable singleton;

    event TokenBundleDeployed(address indexed bundler);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor() ERC721("PWN Bundle Ownership", "TBO") {
        // Deploy bundle bundle singleton for future clone referance
        singleton = new TokenBundle();
        singleton.initialize(address(this));
    }


    /*----------------------------------------------------------*|
    |*  # TOKEN BUNDLE FACTORY                                  *|
    |*----------------------------------------------------------*/

    // Mint new token only for a new bundle.
    // Bundle cannot be destroyed and token cannot be burned.
    function deployBundle() external returns (TokenBundle bundle) {
        bundle = TokenBundle(Clones.clone(address(singleton)));
        bundle.initialize(address(this));

        _mint(msg.sender, uint256(uint160(address(bundle))));

        emit TokenBundleDeployed(address(bundle));
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
