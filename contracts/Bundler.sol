//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pwnfinance/multitoken/contracts/MultiToken.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract Bundler is ERC1155Burnable{
    using MultiToken for MultiToken.Asset;

    uint256 id = 1;
    uint256 nonce = 1;

    uint256 maxSize = 10;

    mapping (uint256 => uint256[]) bundles;
    mapping (uint256 => MultiToken.Asset) tokens;

    modifier onlyBundler(uint256 _bundleID) {
        require(balanceOf(msg.sender, _bundleID) == 1);
        _;
    }

    event NewBundleCreated(address indexed creator, uint256 id);
    event AddedToBundle(uint256 indexed id, MultiToken.Asset asset);
    event RemovedFromBundle(uint256 indexed id, MultiToken.Asset asset);
    event BundleBurned(uint256 indexed id);

    constructor(
        string memory _metaUri
    )
        ERC1155(_metaUri)
    {
    }

    function createBundle(MultiToken.Asset[] memory _assets) public {
        require(_assets.length <= 10, "Can't wrap more than 10 distinct assets");
        uint256 bundleID = mint();
        for (uint i; i <= _assets.length; i++) {
            addToBundle(bundleID, _assets[i]);
        }
    }

    function addToBundle(uint256 _bundleID, MultiToken.Asset memory _asset) public onlyBundler(_bundleID) {
        require(bundles[_bundleID].length < maxSize, "The bundle is too large");

        MultiToken.transferAssetFrom(_asset, msg.sender, address(this));
        tokens[nonce] = _asset;
        bundles[_bundleID].push(nonce);
        nonce++;

        emit AddedToBundle(_bundleID, _asset);
    }

    function removeFromBundler(uint256 _bundleID, uint256 _tokenID) public onlyBundler(_bundleID) {
        uint index = findIndex(bundles[_bundleID], _tokenID);
        MultiToken.Asset memory asset = tokens[index];
        MultiToken.transferAssetFrom(asset, msg.sender, address(this));
        delete tokens[index];

        bundles[_bundleID][index] = bundles[_bundleID][bundles[_bundleID].length-1];
        bundles[_bundleID].pop();

        emit RemovedFromBundle(_bundleID, asset);
    }

    function unwrapBundle(uint256 _bundleID) public onlyBundler(_bundleID) {
        uint256[] memory tokenList = bundles[_bundleID];

        for (uint i; i <= tokenList.length; i++) {
            MultiToken.transferAsset(tokens[tokenList[i]], msg.sender);
            delete tokens[tokenList[i]];
        }
        delete bundles[_bundleID];
        burn(_bundleID);
    }



    function mint() internal returns (uint256) {
        id++;
        _mint(msg.sender, id, 1, "");
        emit NewBundleCreated(msg.sender, id);
        return id;
    }

    function burn(uint256 _bundleID) internal {
        burn(msg.sender, _bundleID, 1);
    }

    function findIndex(uint256[] memory _array, uint _searched) internal view returns (uint) {
        for (uint i; i < _array.length; i++) {
            if (_array[i] == _searched) {
                return i;
            }
        }
        revert("The asset is not part of this bundle!");
    }

}
