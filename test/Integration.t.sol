// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../src/test/T20.sol";
import "../src/test/T721.sol";
import "../src/test/T1155.sol";
import "../src/TokenBundler.sol";


contract IntegrationTest is Test {

	TokenBundler bundler;
	T20 usdc;
	T20 dai;
	T721 nft;
	T1155 game;
	address alice = address(0xa11ce);
	address bob = address(0xb0b);

	function setUp() external {
		bundler = new TokenBundler("uri", 5);

		usdc = new T20("USDC", "USDC");
		dai = new T20("DAI", "DAI");
		nft = new T721("NFT", "NFT");
		game = new T1155("uri");
	}


	function test_createBundleByAlice_transferToBob_unwrapByBob() external {
		usdc.mint(alice, 100e18);
		dai.mint(alice, 300e18);
		nft.mint(alice, 42);
		game.mint(alice, 142, 100, "");

		vm.startPrank(alice);
		usdc.approve(address(bundler), 100e18);
		dai.approve(address(bundler), 300e18);
		nft.approve(address(bundler), 42);
		game.setApprovalForAll(address(bundler), true);
		vm.stopPrank();

		assertEq(usdc.balanceOf(alice), 100e18);
		assertEq(dai.balanceOf(alice), 300e18);
		assertEq(nft.ownerOf(42), alice);
		assertEq(game.balanceOf(alice, 142), 100);

		MultiToken.Asset[] memory assets = new MultiToken.Asset[](5);
		assets[0] = MultiToken.Asset(MultiToken.Category.ERC721, address(nft), 42, 1);
		assets[1] = MultiToken.Asset(MultiToken.Category.ERC20, address(usdc), 0, 100e18);
		assets[2] = MultiToken.Asset(MultiToken.Category.ERC20, address(dai), 0, 100e18);
		assets[3] = MultiToken.Asset(MultiToken.Category.ERC1155, address(game), 142, 100);
		assets[4] = MultiToken.Asset(MultiToken.Category.ERC20, address(dai), 0, 200e18);

		vm.prank(alice);
		uint256 bundleId = bundler.create(assets);

		assertEq(usdc.balanceOf(address(bundler)), 100e18);
		assertEq(dai.balanceOf(address(bundler)), 300e18);
		assertEq(nft.ownerOf(42), address(bundler));
		assertEq(game.balanceOf(address(bundler), 142), 100);

		assertEq(usdc.balanceOf(alice), 0);
		assertEq(dai.balanceOf(alice), 0);
		assertEq(game.balanceOf(alice, 142), 0);

		vm.prank(alice);
		bundler.safeTransferFrom(alice, bob, bundleId, 1, "");

		vm.prank(bob);
		bundler.unwrap(bundleId);

		assertEq(usdc.balanceOf(bob), 100e18);
		assertEq(dai.balanceOf(bob), 300e18);
		assertEq(nft.ownerOf(42), bob);
		assertEq(game.balanceOf(bob, 142), 100);
	}

}
