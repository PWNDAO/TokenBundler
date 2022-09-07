// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import "../src/TokenBundler.sol";


/*
Deploy TokenBundler contracts by executing commands:

source .env

forge script script/TokenBundler.s.sol:Deploy \
--rpc-url $GOERLI_URL \
--private-key $DEPLOY_PRIVATE_KEY_TESTNET \
--broadcast
 */
contract Deploy is Script {

	function run() external {
		vm.startBroadcast();

        new TokenBundler("https://test.uri/");

        vm.stopBroadcast();
	}

}
