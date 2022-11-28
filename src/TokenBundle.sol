//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "MultiToken/MultiToken.sol";

import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import "./interfaces/ITokenBundle.sol";
import "./interfaces/IERC5646.sol";
import "./TokenReceiver.sol";
import "./TokenBundleOwnership.sol";


/**
 * @title Token Bundle
 * @dev Used as a proxy. Bundle can be locked to disable withdrawals. It's useful when used in a defi.
 */
contract TokenBundle is Initializable, TokenReceiver, ITokenBundle, IERC5646 {
    using MultiToken for MultiToken.Asset;

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * @notice Address of the ownership token contract.
     */
    TokenBundleOwnership public ownershipContract;

    /**
     * @notice Flag is true when bundle is locked.
     */
    bool public isLocked;

    /**
     * @notice Nonce value.
     * @dev Used to change state for every lock. It prevents bundle owner to unlock, withdraw tokens and lock bundle again.
     */
    uint256 public nonce;


    /*----------------------------------------------------------*|
    |*  # MODIFIERS                                             *|
    |*----------------------------------------------------------*/

    modifier onlyOwner() {
        require(ownershipContract.ownerOf(_bundleId()) == msg.sender, "Caller is not the bundle owner");
        _;
    }

    modifier onlyUnlocked() {
        require(isLocked == false, "Bundle is locked");
        _;
    }


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & INITIALIZER                             *|
    |*----------------------------------------------------------*/

    constructor() {

    }

    function initialize(address _ownershipContract) external initializer {
        ownershipContract = TokenBundleOwnership(_ownershipContract);
    }


    /*----------------------------------------------------------*|
    |*  # LOCK & UNLOCK                                         *|
    |*----------------------------------------------------------*/

    /**
     * @notice Locks bundle and disable withdrawals.
     * @dev It's still possible to transfer tokens into the bundle as every bundle has its own address.
     */
    function lock() external onlyOwner {
        require(isLocked == false, "Bundle is already locked");
        isLocked = true;
        nonce += 1;

        emit BundleLocked(_bundleId(), nonce);
    }

    /**
     * @notice Unlocks bundle and enable withdrawals.
     */
    function unlock() external onlyOwner {
        require(isLocked == true, "Bundle is not locked");
        isLocked = false;

        emit BundleUnlocked(_bundleId());
    }


    /*----------------------------------------------------------*|
    |*  # WITHDRAWALS                                           *|
    |*----------------------------------------------------------*/

    /**
     * @notice Withdraw token from the bundle.
     * @param asset MultiToken Asset struct representing asset to withdraw.
     */
    function withdraw(MultiToken.Asset memory asset) external onlyOwner onlyUnlocked {
        asset.transferAsset(msg.sender);
    }

    /**
     * @notice Withdraw token batch from the bundle.
     * @param assets MultiToken Asset struct list representing assets to withdraw.
     */
    function withdrawBatch(MultiToken.Asset[] memory assets) external onlyOwner onlyUnlocked {
        uint256 length = assets.length;
        for (uint256 i; i < length; ) {
            assets[i].transferAsset(msg.sender);
            unchecked { ++i; }
        }
    }


    /*----------------------------------------------------------*|
    |*  # ERC165                                                *|
    |*----------------------------------------------------------*/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(ITokenBundle).interfaceId ||
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
        require(tokenId == _bundleId(), "Invalid token id");

        return keccak256(abi.encode(isLocked, nonce));
    }


    /*----------------------------------------------------------*|
    |*  # HELPERS                                               *|
    |*----------------------------------------------------------*/

    function _bundleId() private view returns (uint256) {
        return uint256(uint160(address(this)));
    }

}
