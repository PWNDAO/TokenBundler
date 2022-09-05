// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import "../src/TokenBundler.sol";


contract TokenBundlerTest is Test {

    bytes32 constant internal OWNER_SLOT = bytes32(uint256(0));
    bytes32 constant internal BALANCES_SLOT = bytes32(uint256(1));
    bytes32 constant internal ID_SLOT = bytes32(uint256(4));
    bytes32 constant internal NONCE_SLOT = bytes32(uint256(5));
    bytes32 constant internal BUNDLES_SLOT = bytes32(uint256(6));
    bytes32 constant internal BUNDLED_TOKENS_SLOT = bytes32(uint256(7));

}

/*----------------------------------------------------------*|
|*  # CONSTRUCTOR                                           *|
|*----------------------------------------------------------*/

contract TokenBundler_Constructor_Test is TokenBundlerTest {

    function test_shouldSetMetaUri() external {
        string memory metadataUri = "https://some.test.meta.uri/";

        TokenBundler bundler = new TokenBundler(metadataUri);

        assertEq(metadataUri, bundler.uri(1));
    }

    function test_shouldSetOwner() external {
        address owner = address(0xa11ce);

        vm.prank(owner);
        TokenBundler bundler = new TokenBundler("metadataUri");

        bytes32 ownerValue = vm.load(address(bundler), OWNER_SLOT);
        assertEq(ownerValue, bytes32(uint256(uint160(owner))));
    }

}


/*----------------------------------------------------------*|
|*  # CREATE                                                *|
|*----------------------------------------------------------*/

contract TokenBundler_Create_Test is TokenBundlerTest {

    TokenBundler bundler;
    IERC20 t20;
    IERC721 t721;
    IERC1155 t1155;
    address user = address(0xa11ce);

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event BundleCreated(uint256 indexed id, address indexed creator);

    function setUp() external {
        bundler = new TokenBundler("https://test.uri/");

        t20 = IERC20(address(0xa66e720));
        vm.etch(address(t20), bytes("0x01"));
        vm.mockCall(
            address(t20),
            abi.encodeWithSelector(t20.transferFrom.selector),
            abi.encode(true)
        );

        t721 = IERC721(address(0xa66e7721));
        vm.etch(address(t721), bytes("0x01"));

        t1155 = IERC1155(address(0xa66e71155));
        vm.etch(address(t1155), bytes("0x01"));
    }


    function test_shouldFail_whenPassingEmptyArray() external {
        MultiToken.Asset[] memory emptyAssets;

        vm.expectRevert("Need to bundle at least one asset");
        bundler.create(emptyAssets);
    }

    function test_shouldPass_whenPassingOneAsset() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](1);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);

        vm.prank(user); // Needed so Test contract don't have to implement ERC1155Receiver
        bundler.create(assets);
    }

    function test_shouldNotJoinSameAssets() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](3);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);
        assets[1] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);
        assets[2] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);

        vm.prank(user); // Needed so Test contract don't have to implement ERC1155Receiver
        uint256 bundleId = bundler.create(assets);

        uint256[] memory tokenIds = bundler.bundle(bundleId);
        for (uint256 i = 0; i < assets.length; ++i) {
            MultiToken.Asset memory bundledAsset = bundler.token(tokenIds[i]);

            assertEq(MultiToken.isSameAs(bundledAsset, assets[i]), true);
            assertEq(bundledAsset.amount, assets[i].amount);
        }
    }

    function test_shouldIncreaseGlobalId() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](2);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);
        assets[1] = MultiToken.Asset(MultiToken.Category.ERC721, address(t721), 3212, 1);
        uint256 id = 120;

        vm.store(address(bundler), ID_SLOT, bytes32(id));


        vm.startPrank(user); // Needed so Test contract don't have to implement ERC1155Receiver

        uint256 bundleId = bundler.create(assets);
        assertEq(bundleId, id + 1);

        bundleId = bundler.create(assets);
        assertEq(bundleId, id + 2);

        vm.stopPrank();
    }

    function test_shouldCreateFirstBundleWithIdOne() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](1);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);

        vm.prank(user); // Needed so Test contract don't have to implement ERC1155Receiver
        uint256 bundleId = bundler.create(assets);

        assertEq(bundleId, 1);
    }

    function test_shouldMintBundleToken() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](1);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);

        vm.prank(user); // Needed so Test contract don't have to implement ERC1155Receiver
        uint256 bundleId = bundler.create(assets);

        assertEq(bundler.balanceOf(user, bundleId), 1);
    }

    function test_shouldEmitTransferSingleEvent() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](1);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);

        vm.expectEmit(true, true, true, true);
        emit TransferSingle(user, address(0), user, 1, 1);
        vm.prank(user); // Needed so Test contract don't have to implement ERC1155Receiver
        bundler.create(assets);
    }

    function test_shouldEmitBundleCreatedEvent() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](1);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);

        vm.expectEmit(true, true, false, false);
        emit BundleCreated(1, user);
        vm.prank(user); // Needed so Test contract don't have to implement ERC1155Receiver
        bundler.create(assets);
    }

    function test_shouldIncreaseGlobalNonce() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](2);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);
        assets[1] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);

        uint256 nonce = 312332;
        vm.store(address(bundler), NONCE_SLOT, bytes32(nonce));

        vm.prank(user); // Needed so Test contract don't have to implement ERC1155Receiver
        bundler.create(assets);

        bytes32 newNonce = vm.load(address(bundler), NONCE_SLOT);
        assertEq(uint256(newNonce), nonce + 2);
    }

    function test_shouldStoreAssetUnderNonce() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](2);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);
        assets[1] = MultiToken.Asset(MultiToken.Category.ERC721, address(t721), 3212, 1);

        uint256 nonce = 8376628;
        vm.store(address(bundler), NONCE_SLOT, bytes32(nonce));

        vm.prank(user); // Needed so Test contract don't have to implement ERC1155Receiver
        bundler.create(assets);

        for (uint256 i; i < 2; ++i) {
            bytes32 assetStructSlot = keccak256(
                abi.encode( // Viz https://docs.soliditylang.org/en/v0.8.9/internals/layout_in_storage.html#mappings-and-dynamic-arrays
                    uint256(nonce + i + 1), // Token nonce as a key in the mapping
                    BUNDLED_TOKENS_SLOT // Position of the mapping
                )
            );

            uint256 addrAndCategorySlot = uint256(assetStructSlot) + 0;
            bytes32 addrAndCategoryValue = vm.load(address(bundler), bytes32(addrAndCategorySlot));
            uint256 addrAndCategoryExpectedValue = (uint256(uint160(assets[i].assetAddress)) << 8) | uint8(assets[i].category);
            assertEq(addrAndCategoryValue, bytes32(addrAndCategoryExpectedValue));

            uint256 idSlot = uint256(assetStructSlot) + 1;
            bytes32 idValue = vm.load(address(bundler), bytes32(idSlot));
            assertEq(idValue, bytes32(assets[i].id));

            uint256 amountSlot = uint256(assetStructSlot) + 2;
            bytes32 amountValue = vm.load(address(bundler), bytes32(amountSlot));
            assertEq(amountValue, bytes32(assets[i].amount));
        }
    }

    function test_shouldPushAssetNonceToBundleAssetArray() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](2);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);
        assets[1] = MultiToken.Asset(MultiToken.Category.ERC721, address(t721), 3212, 1);

        uint256 nonce = 8376628;
        vm.store(address(bundler), NONCE_SLOT, bytes32(nonce));

        vm.prank(user); // Needed so Test contract don't have to implement ERC1155Receiver
        uint256 bundleId = bundler.create(assets);

        bytes32 arraySlot = keccak256(
            abi.encode( // Viz https://docs.soliditylang.org/en/v0.8.9/internals/layout_in_storage.html#mappings-and-dynamic-arrays
                bundleId, // Bundle id as a key in the mapping
                BUNDLES_SLOT // Position of the mapping
            )
        );
        // Check array length eq 2
        bytes32 bundleLenghtValue = vm.load(address(bundler), arraySlot);
        assertEq(bundleLenghtValue, bytes32(uint256(2)));

        bytes32 firstElementSlot = keccak256(abi.encode(arraySlot));
        for (uint256 i; i < 2; ++i) {
            uint256 tokenSlot = uint256(firstElementSlot) + i;
            bytes32 tokenValue = vm.load(address(bundler), bytes32(tokenSlot));
            assertEq(tokenValue, bytes32(nonce + i + 1));
        }
    }

    function test_shouldTransferAssetToBundlerContract() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](3);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);
        assets[1] = MultiToken.Asset(MultiToken.Category.ERC721, address(t721), 3212, 1);
        assets[2] = MultiToken.Asset(MultiToken.Category.ERC1155, address(t1155), 32311, 100e18);

        vm.expectCall(
            address(t20),
            abi.encodeWithSelector(t20.transferFrom.selector, user, address(bundler), 100e18)
        );
        vm.expectCall(
            address(t721),
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", user, address(bundler), 3212)
        );
        vm.expectCall(
            address(t1155),
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", user, address(bundler), 32311, 100e18, "")
        );

        vm.prank(user); // Needed so Test contract don't have to implement ERC1155Receiver
        bundler.create(assets);
    }

    function test_shouldFail_whenAnyAssetTransferFails() external {
        MultiToken.Asset[] memory assets = new MultiToken.Asset[](3);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);
        assets[1] = MultiToken.Asset(MultiToken.Category.ERC721, address(t721), 3212, 1);
        assets[2] = MultiToken.Asset(MultiToken.Category.ERC1155, address(t1155), 32311, 100e18);

        vm.etch(address(t721), bytes(""));

        vm.expectRevert();
        vm.prank(user); // Needed so Test contract don't have to implement ERC1155Receiver
        bundler.create(assets);
    }

}


/*----------------------------------------------------------*|
|*  # UNWRAP                                                *|
|*----------------------------------------------------------*/

contract TokenBundler_Unwrap_Test is TokenBundlerTest {

    TokenBundler bundler;
    IERC20 t20 = IERC20(address(0xa66e720));
    IERC721 t721 = IERC721(address(0xa66e7721));
    IERC1155 t1155 = IERC1155(address(0xa66e71155));
    address user = address(0xa11ce);
    uint256 bundleId;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event BundleUnwrapped(uint256 indexed id);

    function setUp() external {
        bundler = new TokenBundler("https://test.uri/");

        vm.etch(address(t20), bytes("0x01"));
        vm.etch(address(t721), bytes("0x01"));
        vm.etch(address(t1155), bytes("0x01"));

        vm.mockCall(
            address(t20),
            abi.encodeWithSelector(t20.transferFrom.selector),
            abi.encode(true)
        );
        vm.mockCall(
            address(t20),
            abi.encodeWithSelector(t20.transfer.selector),
            abi.encode(true)
        );

        MultiToken.Asset[] memory assets = new MultiToken.Asset[](3);
        assets[0] = MultiToken.Asset(MultiToken.Category.ERC20, address(t20), 0, 100e18);
        assets[1] = MultiToken.Asset(MultiToken.Category.ERC721, address(t721), 3212, 1);
        assets[2] = MultiToken.Asset(MultiToken.Category.ERC1155, address(t1155), 32311, 100e18);

        vm.prank(user); // Needed so Test contract don't have to implement ERC1155Receiver
        bundleId = bundler.create(assets);
    }

    function test_shouldFail_whenSenderIsNotBundleOwner() external {
        vm.expectRevert("Sender is not bundle owner");

        vm.prank(address(0xb0b));
        bundler.unwrap(bundleId);
    }

    function test_shouldTransferBundledAssetsToSender() external {
        vm.expectCall(
            address(t20),
            abi.encodeWithSelector(t20.transfer.selector, user, 100e18)
        );
        vm.expectCall(
            address(t721),
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(bundler), user, 3212)
        );
        vm.expectCall(
            address(t1155),
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", address(bundler), user, 32311, 100e18, "")
        );

        vm.prank(user);
        bundler.unwrap(bundleId);
    }

    function test_shouldFail_whenAnyAssetTransferFails() external {
        vm.etch(address(t721), bytes(""));

        vm.expectRevert();
        vm.prank(user);
        bundler.unwrap(bundleId);
    }

    function test_shouldDeleteStoredAssets() external {
        vm.prank(user);
        bundler.unwrap(bundleId);

        for (uint256 i; i < 3; ++i) {
            bytes32 assetStructSlot = keccak256(
                abi.encode( // Viz https://docs.soliditylang.org/en/v0.8.9/internals/layout_in_storage.html#mappings-and-dynamic-arrays
                    uint256(i + 1), // Token nonce as a key in the mapping
                    BUNDLED_TOKENS_SLOT // Position of the mapping
                )
            );

            uint256 addrAndCategorySlot = uint256(assetStructSlot) + 0;
            bytes32 addrAndCategoryValue = vm.load(address(bundler), bytes32(addrAndCategorySlot));
            assertEq(addrAndCategoryValue, bytes32(0));

            uint256 idSlot = uint256(assetStructSlot) + 1;
            bytes32 idValue = vm.load(address(bundler), bytes32(idSlot));
            assertEq(idValue, bytes32(0));

            uint256 amountSlot = uint256(assetStructSlot) + 2;
            bytes32 amountValue = vm.load(address(bundler), bytes32(amountSlot));
            assertEq(amountValue, bytes32(0));
        }
    }

    function test_shouldDeleteBundleAssetArray() external {
        vm.prank(user);
        bundler.unwrap(bundleId);

        bytes32 arraySlot = keccak256(
            abi.encode( // Viz https://docs.soliditylang.org/en/v0.8.9/internals/layout_in_storage.html#mappings-and-dynamic-arrays
                bundleId, // Bundle id as a key in the mapping
                BUNDLES_SLOT // Position of the mapping
            )
        );
        // Check array length eq 0
        bytes32 bundleLenghtValue = vm.load(address(bundler), arraySlot);
        assertEq(bundleLenghtValue, bytes32(0));

        bytes32 firstElementSlot = keccak256(abi.encode(arraySlot));
        for (uint256 i; i < 3; ++i) {
            uint256 tokenSlot = uint256(firstElementSlot) + i;
            bytes32 tokenValue = vm.load(address(bundler), bytes32(tokenSlot));

            assertEq(tokenValue, bytes32(0));
        }
    }

    function test_shouldBurnBundleToken() external {
        vm.prank(user);
        bundler.unwrap(bundleId);

        bytes32 tokenBalancesSlot = keccak256(
            abi.encode( // Viz https://docs.soliditylang.org/en/v0.8.9/internals/layout_in_storage.html#mappings-and-dynamic-arrays
                bundleId, // Bundle id as a key in the mapping
                BALANCES_SLOT // Position of balances mapping
            )
        );
        bytes32 userBalanceSlot = keccak256(
            abi.encode(
                user, // Owner address
                tokenBalancesSlot // Position of balances of bundle id mapping
            )
        );

        assertEq(vm.load(address(bundler), userBalanceSlot), bytes32(0));
    }

    function test_shouldEmitTransferSingleEvent() external {
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(user, user, address(0), bundleId, 1);

        vm.prank(user);
        bundler.unwrap(bundleId);
    }

    function test_shouldEmitBundleUnwrappedEvent() external {
        vm.expectEmit(true, false, false, false);
        emit BundleUnwrapped(bundleId);

        vm.prank(user);
        bundler.unwrap(bundleId);
    }

}


/*----------------------------------------------------------*|
|*  # SUPPORTS INTERFACE                                    *|
|*----------------------------------------------------------*/

contract TokenBundler_SupportsInterface_Test is TokenBundlerTest {

    TokenBundler bundler;

    function setUp() external {
        bundler = new TokenBundler("https://test.uri/");
    }


    function test_shouldSupportERC165() external {
        assertEq(
            bundler.supportsInterface(type(IERC165).interfaceId),
            true
        );
    }

    function test_shouldSupportERC1155() external {
        assertEq(
            bundler.supportsInterface(type(IERC1155).interfaceId),
            true
        );
    }

    function test_shouldSupportERC1155Receiver() external {
        assertEq(
            bundler.supportsInterface(type(IERC1155Receiver).interfaceId),
            true
        );
    }

    function test_shouldSupportERC721Receiver() external {
        assertEq(
            bundler.supportsInterface(type(IERC721Receiver).interfaceId),
            true
        );
    }

    function test_shouldSupportTokenBundler() external {
        assertEq(
            bundler.supportsInterface(type(ITokenBundler).interfaceId),
            true
        );
    }

}


/*----------------------------------------------------------*|
|*  # SET URI                                               *|
|*----------------------------------------------------------*/

contract TokenBundler_SetUri_Test is TokenBundlerTest {

    TokenBundler bundler;

    function setUp() external {
        bundler = new TokenBundler("https://test.uri/");
    }


    function test_shouldSetNewUri() external {
        string memory newUri = "new uri";

        bundler.setUri(newUri);

        assertEq(bundler.uri(1), newUri);
    }

}


/*----------------------------------------------------------*|
|*  # TRANSFER HOOKS                                        *|
|*----------------------------------------------------------*/

contract TokenBundler_TransferHooks_Test is TokenBundlerTest {

    TokenBundler bundler;

    function setUp() external {
        bundler = new TokenBundler("https://test.uri/");
    }


    function test_shouldFail_whenOnERC721Received_whenOperatorIsNotBundle() external {
        vm.expectRevert("Unsupported transfer function");
        bundler.onERC721Received(address(0x01), address(0x02), 42, "data");
    }

    function test_shouldReturnCorrectValue_whenOnERC721Received() external {
        bytes4 value = bundler.onERC721Received(address(bundler), address(0x02), 42, "data");

        assertTrue(value == 0x150b7a02);
    }

    function test_shouldFail_whenOnERC1155Received_whenOperatorIsNotBundle() external {
        vm.expectRevert("Unsupported transfer function");
        bundler.onERC1155Received(address(0x01), address(0x02), 42, 100, "data");
    }

    function test_shouldReturnCorrectValue_whenOnERC1155Received() external {
        bytes4 value = bundler.onERC1155Received(address(bundler), address(0x02), 42, 100, "data");

        assertTrue(value == 0xf23a6e61);
    }

    function test_shouldFail_whenOnERC1155BatchReceived() external {
        uint256[] memory ids;
        uint256[] memory amounts;

        vm.expectRevert("Unsupported transfer function");
        bundler.onERC1155BatchReceived(address(0x01), address(0x02), ids, amounts, "data");
    }

}
