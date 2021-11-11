//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@pwnfinance/multitoken/contracts/MultiToken.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Bundler is ERC1155 {
    using MultiToken for MultiToken.Asset;

    uint256 private id;
    uint256 private nonce;

    uint256 public maxSize;

    mapping (uint256 => uint256[]) bundles;
    mapping (uint256 => MultiToken.Asset) tokens;

    event BundleCreated(uint256 indexed id, address indexed creator);
    event BundleUnwrapped(uint256 indexed id);

    constructor(string memory _metaUri, uint256 _maxSize) ERC1155(_metaUri) {
        maxSize = _maxSize;
    }

    function create(MultiToken.Asset[] memory _assets) external {
        require(_assets.length <= maxSize, "Number of assets exceed max bundle size");

        uint256 bundleId = ++id;

        _mint(msg.sender, bundleId, 1, "");

        emit BundleCreated(bundleId, msg.sender);

        for (uint i; i <= _assets.length; i++) {
            addToBundle(bundleId, _assets[i]);
        }
    }

    function unwrap(uint256 _bundleID) external {
        require(balanceOf(msg.sender, _bundleID) == 1, "Sender is not bundle owner");

        uint256[] memory tokenList = bundles[_bundleID];

        for (uint i; i <= tokenList.length; i++) {
            MultiToken.transferAsset(tokens[tokenList[i]], msg.sender);
            delete tokens[tokenList[i]];
        }

        delete bundles[_bundleID];

        _burn(msg.sender, _bundleID, 1);

        emit BundleUnwrapped(_bundleID);
    }


    function addToBundle(uint256 _bundleID, MultiToken.Asset memory _asset) private {
        nonce++;
        tokens[nonce] = _asset;
        bundles[_bundleID].push(nonce);

        MultiToken.transferAssetFrom(_asset, msg.sender, address(this));
    }

}
