// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Script.sol";
import "../src/TokenBundler.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";


/*
Deploy TokenBundler contracts by executing commands:

source .env

forge script script/TokenBundler.s.sol:Deploy \
--rpc-url $GOERLI_URL \
--private-key $DEPLOY_PRIVATE_KEY_TESTNET \
--broadcast
 */
contract Deploy is Script {
    using Strings for uint256;
    using Strings for address;


    function run() external {
        vm.startBroadcast();

        TokenBundler bundler = new TokenBundler("");
        bundler.setUri(
            string(abi.encodePacked(
                "https://api.pwn.xyz/bundle/", block.chainid.toString(), "/", address(bundler).toHexString(), "/{id}/metadata"
            ))
        );

        vm.stopBroadcast();
    }

}
