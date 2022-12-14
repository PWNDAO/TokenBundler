// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import "MultiToken/MultiToken.sol";

import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import "../src/interfaces/IERC5646.sol";
import "../src/interfaces/ITokenBundle.sol";
import "../src/TokenBundle.sol";


abstract contract TokenBundleTest is Test {

    address ownership = address(0x1234);
    address owner = address(0xb0b);
    address token = address(0x70ce);
    TokenBundle bundle;

    event BundleLocked(uint256 indexed bundleId, uint256 nonce);
    event BundleUnlocked(uint256 indexed bundleId);

    constructor() {
        vm.etch(ownership, bytes("data"));
        vm.etch(token, bytes("data"));
    }

    function setUp() virtual public {
        bundle = new TokenBundle();
        bundle.initialize(ownership);


        vm.mockCall(
            ownership,
            abi.encodeWithSignature("ownerOf(uint256)", _bundleId(bundle)),
            abi.encode(owner)
        );
    }


    function _mockIsLocked(bool isLocked) internal {
        bytes32 firstSlotValue = vm.load(address(bundle), 0);
        if (isLocked)
            firstSlotValue |= bytes32(uint256(1)) << 176;
        else
            firstSlotValue &= bytes32(type(uint256).max - 2**176);
        vm.store(address(bundle), 0, firstSlotValue);
    }

    function _mockNonce(uint256 nonce) internal {
        vm.store(address(bundle), bytes32(uint256(1)), bytes32(nonce));
    }

    function _bundleId(TokenBundle _bundle) internal pure returns (uint256) {
        return uint256(uint160(address(_bundle)));
    }

}


/*----------------------------------------------------------*|
|*  # INITIALIZER                                           *|
|*----------------------------------------------------------*/

contract TokenBundle_Initializer_Test is TokenBundleTest {

    function test_shouldStoreOwnershipContractAddress() external {
        address fakeOwnership = address(0x0000);

        bundle = new TokenBundle();
        bundle.initialize(fakeOwnership);

        assertEq(address(bundle.ownershipContract()), fakeOwnership);
    }

    function test_shouldFail_whenCallerSecondTime() external {
        bundle = new TokenBundle();
        bundle.initialize(ownership);

        vm.expectRevert("Initializable: contract is already initialized");
        bundle.initialize(ownership);
    }

    function test_shouldSetInitializedValue() external {
        bundle = new TokenBundle();
        bundle.initialize(ownership);

        // `_initialized` value is first byte in the first slot
        uint256 isInitialized = uint256(vm.load(address(bundle), 0)) & 0x01;
        assertEq(isInitialized, 1);
    }

}


/*----------------------------------------------------------*|
|*  # LOCK                                                  *|
|*----------------------------------------------------------*/

contract TokenBundle_Lock_Test is TokenBundleTest {

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert("Caller is not the bundle owner");
        vm.prank(address(0x01));
        bundle.lock();
    }

    function test_shouldFail_whenBundleIsLocked() external {
        _mockIsLocked(true);

        vm.expectRevert("Bundle is already locked");
        vm.prank(owner);
        bundle.lock();
    }

    function test_shouldSetLockedFlag() external {
        vm.prank(owner);
        bundle.lock();

        uint256 isLocked = uint256(vm.load(address(bundle), 0)) >> 176 & 1;
        assertEq(isLocked, 1);
    }

    function test_shouldIncreaseNonce() external {
        uint256 nonce = 42;
        _mockNonce(nonce);

        vm.prank(owner);
        bundle.lock();

        bytes32 nonceValue = vm.load(address(bundle), bytes32(uint256(1)));
        assertEq(uint256(nonceValue), nonce + 1);
    }

    function test_shouldEmit_BundleLocked() external {
        uint256 nonce = 42;
        _mockNonce(nonce);

        vm.expectEmit(true, false, false, true);
        emit BundleLocked(_bundleId(bundle), nonce + 1);

        vm.prank(owner);
        bundle.lock();
    }

}


/*----------------------------------------------------------*|
|*  # UNLOCK                                                *|
|*----------------------------------------------------------*/

contract TokenBundle_Unlock_Test is TokenBundleTest {

    function setUp() override public {
        super.setUp();

        _mockIsLocked(true);
    }


    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert("Caller is not the bundle owner");
        vm.prank(address(0x01));
        bundle.unlock();
    }

    function test_shouldFail_whenBundleIsNotLocked() external {
        _mockIsLocked(false);

        vm.expectRevert("Bundle is not locked");
        vm.prank(owner);
        bundle.unlock();
    }

    function test_shouldSetLockedFlag() external {
        vm.prank(owner);
        bundle.unlock();

        uint256 isLocked = uint256(vm.load(address(bundle), 0)) >> 176 & 1;
        assertEq(isLocked, 0);
    }

    function test_shouldEmit_BundleUnlocked() external {
        vm.expectEmit(true, false, false, false);
        emit BundleUnlocked(_bundleId(bundle));

        vm.prank(owner);
        bundle.unlock();
    }

}


/*----------------------------------------------------------*|
|*  # WITHDRAW                                              *|
|*----------------------------------------------------------*/

contract TokenBundle_Withdraw_Test is TokenBundleTest {

    MultiToken.Asset asset;
    uint256 tokenId = 42;

    function setUp() override public {
        super.setUp();

        asset = MultiToken.Asset(MultiToken.Category.ERC721, token, tokenId, 1);
    }


    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert("Caller is not the bundle owner");
        vm.prank(address(0x01));
        bundle.withdraw(asset);
    }

    function test_shouldFail_whenBundleIsLocked() external {
        _mockIsLocked(true);

        vm.expectRevert("Bundle is locked");
        vm.prank(owner);
        bundle.withdraw(asset);
    }

    function test_shouldTransferAssetFromBundleToOwner() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(bundle), address(owner), tokenId)
        );

        vm.prank(owner);
        bundle.withdraw(asset);
    }

}


/*----------------------------------------------------------*|
|*  # WITHDRAW BATCH                                        *|
|*----------------------------------------------------------*/

contract TokenBundle_WithdrawBatch_Test is TokenBundleTest {

    function test_shouldFail_whenCallerIsNotOwner() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](2);

        vm.expectRevert("Caller is not the bundle owner");
        vm.prank(address(0x01));
        bundle.withdrawBatch(assets);
    }

    function test_shouldFail_whenBundleIsLocked() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](2);
        _mockIsLocked(true);

        vm.expectRevert("Bundle is locked");
        vm.prank(owner);
        bundle.withdrawBatch(assets);
    }

    function test_shouldTransferLisetOfAssetsFromBundleToOwner() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](2);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC721, token, 42, 1);
        assets[1] = MultiToken.Asset(MultiToken.Category.ERC721, token, 43, 1);

        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(bundle), address(owner), 42)
        );
        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(bundle), address(owner), 43)
        );

        vm.prank(owner);
        bundle.withdrawBatch(assets);
    }

}


/*----------------------------------------------------------*|
|*  # DEPOSIT BATCH                                         *|
|*----------------------------------------------------------*/

contract TokenBundle_DepositBatch_Test is TokenBundleTest {

    function test_shouldTransferLisetOfAssetsFromCallerToBundle() external {
        address depositor = address(0x420);
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](2);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC721, token, 42, 1);
        assets[1] = MultiToken.Asset(MultiToken.Category.ERC721, token, 43, 1);

        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", depositor, address(bundle), 42)
        );
        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", depositor, address(bundle), 43)
        );

        vm.prank(depositor);
        bundle.depositBatch(assets);
    }

}


/*----------------------------------------------------------*|
|*  # ERC165                                                *|
|*----------------------------------------------------------*/

contract TokenBundle_SupportsInterface_Test is TokenBundleTest {

    function test_shouldReturnFalse_whenUnsupportedInterface() external {
        assertFalse(bundle.supportsInterface(0x12345678));
    }

    function test_shouldSupport_ERC165() external {
        assertTrue(bundle.supportsInterface(type(IERC165).interfaceId));
    }

    function test_shouldSupport_ERC721Receiver() external {
        assertTrue(bundle.supportsInterface(type(IERC721Receiver).interfaceId));
    }

    function test_shouldSupport_ERC1155Receiver() external {
        assertTrue(bundle.supportsInterface(type(IERC1155Receiver).interfaceId));
    }

    function test_shouldSupport_ERC5646() external {
        assertTrue(bundle.supportsInterface(type(IERC5646).interfaceId));
    }

    function test_shouldSupport_ITokenBundle() external {
        assertTrue(bundle.supportsInterface(type(ITokenBundle).interfaceId));
    }

}


/*----------------------------------------------------------*|
|*  # ERC5646                                               *|
|*----------------------------------------------------------*/

contract TokenBundle_GetStateFingerprint_Test is TokenBundleTest {

    function test_shouldFail_whenTokenIdIsNotBundleAddress(uint256 tokenId) external {
        vm.assume(tokenId != _bundleId(bundle));

        vm.expectRevert("Invalid token id");
        bundle.getStateFingerprint(tokenId);
    }

    function test_shouldReturnCorrectFingerprint(bool isLocked, uint256 nonce) external {
        _mockIsLocked(isLocked);
        _mockNonce(nonce);
        assertEq(
            bundle.getStateFingerprint(_bundleId(bundle)),
            keccak256(abi.encode(isLocked, nonce))
        );
    }

}
