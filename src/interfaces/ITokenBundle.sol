//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "MultiToken/MultiToken.sol";


/**
 * @title Token Bundle interface
 * @dev Interface defines external functions of a Token Bundle contract.
 */
interface ITokenBundle {

    /**
     * @dev Emitted when bundle is locked.
     * @param bundleId Bundle address used as the bundle id.
     * @param nonce Current nonce of the bundle.
     */
    event BundleLocked(uint256 indexed bundleId, uint256 nonce);

    /**
     * @dev Emitted when bundle is unlocked.
     * @param bundleId Bundle address used as the bundle id.
     */
    event BundleUnlocked(uint256 indexed bundleId);


    /**
     * @notice Is locked flag getter.
     * @return True if bundle is locked.
     */
    function isLocked() external returns (bool);

    /**
     * @notice Nonce value getter.
     * @return Value of the budle nonce.
     */
    function nonce() external returns (uint256);


    /**
     * @notice Locks bundle and disable withdrawals.
     * @dev It's still possible to transfer tokens into the bundle as every bundle has its own address.
     */
    function lock() external;

    /**
     * @notice Unlocks bundle and enable withdrawals.
     */
    function unlock() external;


    /**
     * @notice Withdraw token from the bundle.
     * @param asset MultiToken Asset struct representing asset to withdraw.
     */
    function withdraw(MultiToken.Asset memory asset) external;

    /**
     * @notice Withdraw token batch from the bundle.
     * @param assets MultiToken Asset struct list representing assets to withdraw.
     */
    function withdrawBatch(MultiToken.Asset[] memory assets) external;

}
