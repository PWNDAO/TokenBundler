//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "MultiToken/MultiToken.sol";


interface ITokenBundle {

    event BundleLocked(uint256 indexed bundleId, uint256 nonce);
    event BundleUnlocked(uint256 indexed bundleId);

    function isLocked() external returns (bool);
    function nonce() external returns (uint256);

    function lock() external;
    function unlock() external;

    function withdraw(MultiToken.Asset memory asset) external;
    function withdrawBatch(MultiToken.Asset[] memory assets) external;

}
