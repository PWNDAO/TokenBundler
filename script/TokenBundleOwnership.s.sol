// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Script.sol";

import "../src/TokenBundle.sol";
import "../src/TokenBundleOwnership.sol";


/*
Deploy TokenBundleOwnership contracts by executing commands:

source .env

forge script script/TokenBundleOwnership.s.sol:Deploy \
--rpc-url $ETHEREUM_URL \
--private-key $DEPLOY_PRIVATE_KEY_MAINNET \
--with-gas-price $(cast --to-wei 10 gwei) \
--verify --etherscan-api-key $ETHERSCAN_API_KEY \
--broadcast
 */
contract Deploy is Script {

    function run() external {
        vm.startBroadcast();

        TokenBundle singleton = new TokenBundle();
        singleton.initialize(address(0));
        TokenBundleOwnership ownership = new TokenBundleOwnership(address(singleton));

        console2.log("TokenBundleOwnership deployed at:", address(ownership));

        vm.stopBroadcast();
    }

}
