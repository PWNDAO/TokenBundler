//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "MultiToken/MultiToken.sol";

import "./IERC5646.sol";


interface ITokenBundler is IERC5646 {

    event BundleLocked(uint256 indexed bundleId, uint256 nonce);
    event BundleUnlocked(uint256 indexed bundleId);

    function lock() external;

    function unlock() external;

    function withdraw(MultiToken.Asset memory asset) external;

}
