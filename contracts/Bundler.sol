//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pwnfinance/multitoken/contracts/MultiToken.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Bundler is ERC1155 {
    using MultiToken for MultiToken.Asset;

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * Global incremental bundle id variable
     */
    uint256 private id;

    /**
     * Global incremental token nonce variable
     */
    uint256 private nonce;

    /**
     * Maximum number of assets a bundle can have
     */
    uint256 public maxSize;

    /**
     * Mapping of bundle id to token nonce list
     */
    mapping (uint256 => uint256[]) public bundles;

    /**
     * Mapping of token nonce to asset struct
     */
    mapping (uint256 => MultiToken.Asset) public tokens;

    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    event BundleCreated(uint256 indexed id, address indexed creator);
    event BundleUnwrapped(uint256 indexed id);

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & FUNCTIONS                               *|
    |*----------------------------------------------------------*/

    /**
     * Bundler constructor
     * @param _metaUri Uri to be used for finding a bundle metadata
     * @param _maxSize Maximum size bundle a bundler can create
     */
    constructor(string memory _metaUri, uint256 _maxSize) ERC1155(_metaUri) {
        maxSize = _maxSize;
    }

    /**
     * create
     * @dev Cannot create empty bundle or exceed maximum bundle size
     * @dev Mint bundle token and transfers assets to Bundler contract
     * @dev Emits `BundleCreated` event
     * @param _assets List of assets to include in a bundle
     * @return Bundle id
     */
    function create(MultiToken.Asset[] memory _assets) external returns (uint256) {
        require(_assets.length > 0, "Need to bundle at least one asset");
        require(_assets.length <= maxSize, "Number of assets exceed max bundle size");

        uint256 bundleId = ++id;

        _mint(msg.sender, bundleId, 1, "");

        emit BundleCreated(bundleId, msg.sender);

        for (uint i; i < _assets.length; i++) {
            addToBundle(bundleId, _assets[i]);
        }

        return bundleId;
    }

    /**
     * unwrap
     * @dev Sender has to be a bundle owner
     * @dev Burns bundle token and transfers assets to sender
     * @dev Emits `BundleUnwrapped` event
     * @param _bundleId Bundle id to unwrap
     */
    function unwrap(uint256 _bundleId) external {
        require(balanceOf(msg.sender, _bundleId) == 1, "Sender is not bundle owner");

        uint256[] memory tokenList = bundles[_bundleId];

        for (uint i; i < tokenList.length; i++) {
            tokens[tokenList[i]].transferAsset(msg.sender);
            delete tokens[tokenList[i]];
        }

        delete bundles[_bundleId];

        _burn(msg.sender, _bundleId, 1);

        emit BundleUnwrapped(_bundleId);
    }

    /**
     * addToBundle
     * @dev Utility function to add asset to a bundle
     * @dev Transfers asset to Bundler contract, assign nonce to asset and push the token nonce into a bundle token list
     * @param _bundleId Bundle id of a bundle to add asset to
     * @param _asset Asset that should be added to a bundle
     */
    function addToBundle(uint256 _bundleId, MultiToken.Asset memory _asset) private {
        nonce++;
        tokens[nonce] = _asset;
        bundles[_bundleId].push(nonce);

        _asset.transferAssetFrom(msg.sender, address(this));
    }

}
