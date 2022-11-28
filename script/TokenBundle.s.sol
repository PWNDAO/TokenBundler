// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Script.sol";

import "../src/TokenBundle.sol";
import "../src/TokenBundleOwnership.sol";


/*
Deploy new TokenBundle contracts by executing commands:

source .env

forge script script/TokenBundle.s.sol:Deploy \
--sig "deploy(address)" $TOKEN_BUNDLE_OWNERSHIP_CONTRACT \
--rpc-url $ETHEREUM_URL \
--private-key $DEPLOY_PRIVATE_KEY_MAINNET \
--with-gas-price $(cast --to-wei 10 gwei) \
--verify --etherscan-api-key $ETHERSCAN_API_KEY \
--broadcast
 */
contract Deploy is Script {

    function deploy(address ownershipContract) external {
        vm.startBroadcast();

        TokenBundleOwnership ownership = TokenBundleOwnership(ownershipContract);
        TokenBundle bundle = ownership.deployBundle();

        console2.log("TokenBundle deployed at:", address(bundle));
        console2.log("Ownership token minted for:", msg.sender);

        vm.stopBroadcast();
    }

}
