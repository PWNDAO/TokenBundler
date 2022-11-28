//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import "./interfaces/IERC5646.sol";
import "./TokenBundle.sol";


// TODO: Optimize gas (use ERC1155D?)
contract TokenBundleOwnership is ERC721, IERC5646 {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    address public immutable singleton;


    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    event TokenBundleDeployed(address indexed bundle);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address _singleton) ERC721("PWN Token Bundle Ownership", "BUNDLE") {
        require(keccak256(_singleton.code) == keccak256(type(TokenBundle).runtimeCode), "Invalid singleton address");
        singleton = _singleton;
    }


    /*----------------------------------------------------------*|
    |*  # TOKEN BUNDLE FACTORY                                  *|
    |*----------------------------------------------------------*/

    // Mint new token only for a new bundle.
    // Bundle cannot be destroyed and token cannot be burned.
    function deployBundle() external returns (TokenBundle) {
        address bundle = Clones.clone(singleton);
        TokenBundle(bundle).initialize(address(this));

        _mint(msg.sender, uint256(uint160(bundle)));

        emit TokenBundleDeployed(bundle);

        return TokenBundle(bundle);
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
        require(tokenId <= type(uint160).max, "Invalid token id");
        require(_exists(tokenId) == true, "Invalid token id");

        return IERC5646(address(uint160(tokenId))).getStateFingerprint(tokenId);
    }

}
