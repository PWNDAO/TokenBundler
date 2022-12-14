//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/proxy/Clones.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import "./interfaces/IERC5646.sol";
import "./TokenBundle.sol";


/**
 * @title Token Bundle Ownership
 * @notice Token representing ownership of a Token Bundle.
 * @dev Works as a Token Bundle factory. Contract owner can only update token metadata uri.
 */
contract TokenBundleOwnership is Ownable, ERC721, IERC5646 {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * @dev Address of the singleton Token Bundle. Is used as a origin for cloning.
     */
    address public immutable singleton;

    /**
     * @dev Token Bundle Ownership metadata URI with `{id}` placeholder.
     */
    string private _metadataUri;

    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @dev Emitted when new bundle is deployed.
     */
    event TokenBundleDeployed(address indexed bundle);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address _singleton, address _owner, string memory metadataUri) Ownable() ERC721("PWN Token Bundle Ownership", "BUNDLE") {
        require(keccak256(_singleton.code) == keccak256(type(TokenBundle).runtimeCode), "Invalid singleton address");
        singleton = _singleton;
        _transferOwnership(_owner);
        _metadataUri = metadataUri;
    }


    /*----------------------------------------------------------*|
    |*  # TOKEN BUNDLE FACTORY                                  *|
    |*----------------------------------------------------------*/

    /**
     * @notice Deploy new Token Bundle and mint ownership token for a caller.
     * @dev New ownership token is minted only for a new Token Bundle. Bundle cannot be destroyed and token cannot be burned.
     * @return Newly deployed Token Bundle address.
     */
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

    /**
     * @dev See {IERC5646-getStateFingerprint}.
     */
    function getStateFingerprint(uint256 tokenId) external view returns (bytes32) {
        require(tokenId <= type(uint160).max, "Invalid token id");
        require(_exists(tokenId) == true, "Invalid token id");

        return IERC5646(address(uint160(tokenId))).getStateFingerprint(tokenId);
    }


    /*----------------------------------------------------------*|
    |*  # TOKEN METADATA                                        *|
    |*----------------------------------------------------------*/

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        _requireMinted(tokenId);
        return _metadataUri;
    }

    /**
     * @notice Set new Token Bundle Ownership token metadata URI.
     * @dev Only contract owner can call this function.
     * @param metadataUri New metadata URI.
     */
    function setMetadataUri(string memory metadataUri) external onlyOwner {
        _metadataUri = metadataUri;
    }
}
