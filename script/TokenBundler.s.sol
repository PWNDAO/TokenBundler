// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import "../src/TokenBundler.sol";


/*
forge script script/TokenBundler.s.sol:Deploy \
--rpc-url $RPC_URL \
--private-key $PRIVATE_KEY \
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
