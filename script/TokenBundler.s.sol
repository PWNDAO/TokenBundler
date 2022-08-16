// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import "../src/TokenBundler.sol";


contract Deploy is Script {

	function run() external {
		vm.startBroadcast();

        new TokenBundler("https://test.uri/", 40);

        vm.stopBroadcast();
	}

}
