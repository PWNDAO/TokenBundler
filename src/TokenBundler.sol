//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "MultiToken/MultiToken.sol";

import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import "./interfaces/ITokenBundler.sol";
import "./TokenReceiver.sol";
import "./TokenBundlerOwnership.sol";


contract TokenBundler is Initializable, TokenReceiver, ITokenBundler {
    using MultiToken for MultiToken.Asset;

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    uint256 public immutable bundleId;

    bool public isLocked;
    uint256 public nonce; // TODO: Try to make it 31 bytes to fit in one word
    TokenBundlerOwnership public ownershipContract;

    modifier onlyOwner() {
        require(ownershipContract.ownerOf(bundleId) == msg.sender, "Caller is not the bundle owner");
        _;
    }

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & FUNCTIONS                               *|
    |*----------------------------------------------------------*/

    constructor() {
        bundleId = uint256(uint160(address(this)));
    }

    function initialize(address owner, address _ownershipContract) external initializer {
        ownershipContract = TokenBundlerOwnership(_ownershipContract);
        ownershipContract.mintOwnership(owner); // User function parameter instead?
    }


    function lock() external onlyOwner {
        require(isLocked == false, "Bundle is already locked");
        isLocked = true;
        nonce += 1;

        emit BundleLocked(bundleId, nonce);
    }

    function unlock() external onlyOwner {
        require(isLocked == true, "Bundle is not locked");
        isLocked = false;

        emit BundleUnlocked(bundleId);
    }

    function withdraw(MultiToken.Asset memory asset) external onlyOwner {
        require(isLocked == false, "Bundle is locked");

        asset.transferAsset(msg.sender); // TODO: Let owner withdraw to any address?
    }

    function withdrawSet(MultiToken.Asset[] memory assets) external onlyOwner {
        require(isLocked == false, "Bundle is locked");

        uint256 length = assets.length;
        for (uint256 i; i < length; ) {
            assets[i].transferAsset(msg.sender); // TODO: Let owner withdraw to any address?
            unchecked { ++i; }
        }
    }


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(ITokenBundler).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    function getStateFingerprint(uint256 tokenId) external view returns (bytes32) {
        require(tokenId == bundleId, "Invalid token id");
        return keccak256(abi.encode(isLocked, nonce));
    }

}
