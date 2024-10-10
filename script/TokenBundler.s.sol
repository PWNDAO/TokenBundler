// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import "../src/TokenBundler.sol";


/*
Deploy TokenBundler contracts by executing commands:

source .env

forge script script/TokenBundler.s.sol:Deploy \
--rpc-url $ETHEREUM_URL \
--private-key $DEPLOY_PRIVATE_KEY_MAINNET \
--with-gas-price $(cast --to-wei 10 gwei) \
--verify --etherscan-api-key $ETHERSCAN_API_KEY \
--broadcast
 */
contract Deploy is Script {

    function run() external {
        vm.startBroadcast();

        string memory tokenUri = ""; // Set token metadata uri
        address owner = address(0x0); // Set token bundle owner (don't have to be the same as deployer)

        TokenBundler bundler = new TokenBundler(tokenUri);
        bundler.transferOwnership(owner);

        console2.log("TokenBundler deployed at address: %s", address(bundler));

        vm.stopBroadcast();
    }

}
