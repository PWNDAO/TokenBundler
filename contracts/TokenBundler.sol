//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pwnfinance/multitoken/contracts/MultiToken.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./ITokenBundler.sol";

contract TokenBundler is ERC1155, ITokenBundler {
    using MultiToken for MultiToken.Asset;

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * Global incremental bundle id variable
     */
    uint256 private _id;

    /**
     * Global incremental token nonce variable
     */
    uint256 private _nonce;

    /**
     * Maximum number of assets a bundle can have
     */
    uint256 private _maxSize;

    /**
     * Mapping of bundle id to token nonce list
     */
    mapping (uint256 => uint256[]) private _bundles;

    /**
     * Mapping of token nonce to asset struct
     */
    mapping (uint256 => MultiToken.Asset) private _tokens;

    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    // No custom events nor errors

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & FUNCTIONS                               *|
    |*----------------------------------------------------------*/

    /**
     * Token Bundler constructor
     * @param _metaUri Uri to be used for finding a bundle metadata
     * @param _bundleMaxSize Maximum bundle size Bundler can create
     */
    constructor(string memory _metaUri, uint256 _bundleMaxSize) ERC1155(_metaUri) {
        _maxSize = _bundleMaxSize;
    }

    /**
     * @dev See {ITokenBundler-create}.
     */
    function create(MultiToken.Asset[] memory _assets) override external returns (uint256) {
        require(_assets.length > 0, "Need to bundle at least one asset");
        require(_assets.length <= _maxSize, "Number of assets exceed max bundle size");

        uint256 bundleId = ++_id;

        _mint(msg.sender, bundleId, 1, "");

        emit BundleCreated(bundleId, msg.sender);

        for (uint i; i < _assets.length; i++) {
            _addToBundle(bundleId, _assets[i]);
        }

        return bundleId;
    }

    /**
     * @dev See {ITokenBundler-unwrap}.
     */
    function unwrap(uint256 _bundleId) override external {
        require(balanceOf(msg.sender, _bundleId) == 1, "Sender is not bundle owner");

        uint256[] memory tokenList = _bundles[_bundleId];

        for (uint i; i < tokenList.length; i++) {
            _tokens[tokenList[i]].transferAsset(msg.sender);
            delete _tokens[tokenList[i]];
        }

        delete _bundles[_bundleId];

        _burn(msg.sender, _bundleId, 1);

        emit BundleUnwrapped(_bundleId);
    }

    /**
     * @dev See {ITokenBundler-token}.
     */
    function token(uint256 _tokenId) override external view returns (MultiToken.Asset memory) {
        return _tokens[_tokenId];
    }

    /**
     * @dev See {ITokenBundler-bundle}.
     */
    function bundle(uint256 _bundleId) override external view returns (uint256[] memory) {
        return _bundles[_bundleId];
    }

    /**
     * @dev See {ITokenBundler-maxSize}.
     */
    function maxSize() override external view returns (uint256) {
        return _maxSize;
    }

    /**
     * addToBundle
     * @dev Utility function to add asset to a bundle.
     * @dev Transfers asset to Bundler contract, assign nonce to asset and push the token nonce into a bundle token list.
     * @param _bundleId Bundle id of a bundle to add asset to
     * @param _asset Asset that should be added to a bundle
     */
    function _addToBundle(uint256 _bundleId, MultiToken.Asset memory _asset) private {
        _nonce++;
        _tokens[_nonce] = _asset;
        _bundles[_bundleId].push(_nonce);

        _asset.transferAssetFrom(msg.sender, address(this));
    }

}
