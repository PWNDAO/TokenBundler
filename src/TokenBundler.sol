//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "MultiToken/MultiToken.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "./ITokenBundler.sol";

contract TokenBundler is ERC1155, IERC1155Receiver, IERC721Receiver, ITokenBundler {
    using MultiToken for MultiToken.Asset;
    using Strings for uint256;
    using Strings for address;

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
     * @dev Metadata URI has a fixed format: `base_uri/chain_id/bundler_address/{id}/metadata`
     *      Base URI is provided by deployer, the rest is computed at construction time.
     * @param _uriBase Base URI to be used to compound metadata URI. Has to end with `/` otherwise it would compound invalid URI.
     */
    constructor(string memory _uriBase) ERC1155(string(abi.encodePacked(_uriBase, block.chainid.toString(), "/", address(this).toHexString(), "/{id}/metadata"))) {

    }


    /**
     * @dev See {ITokenBundler-create}.
     */
    function create(MultiToken.Asset[] memory _assets) override external returns (uint256 bundleId) {
        uint256 length = _assets.length;
        require(length > 0, "Need to bundle at least one asset");

        bundleId = ++_id;
        for (uint i; i < length;) {
            _tokens[++_nonce] = _assets[i];
            _bundles[bundleId].push(_nonce);

            _assets[i].transferAssetFrom(msg.sender, address(this));

            unchecked { ++i; }
        }

        _mint(msg.sender, bundleId, 1, "");

        emit BundleCreated(bundleId, msg.sender);
    }

    /**
     * @dev See {ITokenBundler-unwrap}.
     */
    function unwrap(uint256 _bundleId) override external {
        require(balanceOf(msg.sender, _bundleId) == 1, "Sender is not bundle owner");

        uint256[] memory tokenList = _bundles[_bundleId];

        uint256 length = tokenList.length;
        for (uint i; i < length;) {
            _tokens[tokenList[i]].transferAsset(msg.sender);
            delete _tokens[tokenList[i]];

            unchecked { ++i; }
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
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) override external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*id*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    ) override external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address /*operator*/,
        address /*from*/,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*values*/,
        bytes calldata /*data*/
    ) override external pure returns (bytes4) {
        return 0xbc197c81;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(ITokenBundler).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}
