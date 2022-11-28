//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import "MultiToken/MultiToken.sol";

import "./tokens/T20.sol";
import "../src/TokenBundleOwnership.sol";
import "../src/TokenBundle.sol";


contract IntegrationTest is Test {

    T20 t20;
    TokenBundleOwnership ownership;
    address owner = address(0x1001);

    function setUp() external {
        t20 = new T20("PWN", "PWN");

        TokenBundle singleton = new TokenBundle();
        singleton.initialize(address(0));
        ownership = new TokenBundleOwnership(address(singleton));
    }

    function test_gas() external {
        t20.mint(owner, 100e18);

        vm.prank(owner);
        TokenBundle bundle = ownership.deployBundle();

        vm.prank(owner);
        t20.transfer(address(bundle), 100e18);

        vm.prank(owner);
        bundle.lock();

        vm.prank(owner);
        bundle.unlock();

        vm.prank(owner);
        bundle.withdraw(MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18));
    }

}
