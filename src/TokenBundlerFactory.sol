//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";

import "./TokenBundler.sol";


contract TokenBundlerFactory {

    TokenBundler public immutable singleton;
    address public immutable ownershipContract;

    constructor(address _ownershipContract) {
        ownershipContract = _ownershipContract;
        singleton = new TokenBundler();
        singleton.initialize(address(this), ownershipContract);
    }


    function deployBundler() external returns (address instance) {
        instance = Clones.clone(address(singleton));
        TokenBundler(instance).initialize(msg.sender, ownershipContract);
    }

}
