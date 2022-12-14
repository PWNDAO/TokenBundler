// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

import "../src/interfaces/IERC5646.sol";
import "../src/TokenBundle.sol";
import "../src/TokenBundleOwnership.sol";


abstract contract TokenBundleOwnershipTest is Test {

    bytes32 internal constant OWNER_SLOT = bytes32(uint256(0)); // Position of `_owner` property
    bytes32 internal constant OWNERS_SLOT = bytes32(uint256(3)); // Position of `_owners` mapping
    bytes32 internal constant METADATA_URI_SLOT = bytes32(uint256(7)); // Position of `_metadataUri` mapping

    // Storage value of string "uri.pwn"
    bytes32 internal constant METADATA_URI_STORAGE_VALUE = 0x7572692e70776e0000000000000000000000000000000000000000000000000e;

    address owner = address(0x4321);
    TokenBundle singleton;
    TokenBundleOwnership ownership;

    event TokenBundleDeployed(address indexed bundle);

    function setUp() external {
        singleton = new TokenBundle();
        singleton.initialize(address(0));
        ownership = new TokenBundleOwnership(address(singleton), address(this), "test:uri");
    }

}


/*----------------------------------------------------------*|
|*  # CONSTRUCTOR                                           *|
|*----------------------------------------------------------*/

contract TokenBundleOwnership_Constructor_Test is TokenBundleOwnershipTest {

    function test_shouldSetCorrectMetadata() external {
        assertEq(ownership.name(), "PWN Token Bundle Ownership");
        assertEq(ownership.symbol(), "BUNDLE");
    }

    function test_shouldFail_whenInvalidSingleton() external {
        vm.expectRevert("Invalid singleton address");
        ownership = new TokenBundleOwnership(address(0x01), address(this), "test:uri");
    }

    function test_shouldSetOwner() external {
        address owner = address(0x123456);

        ownership = new TokenBundleOwnership(address(singleton), owner, "test:uri");

        assertEq(vm.load(address(ownership), OWNER_SLOT), bytes32(uint256(uint160(owner))));
    }

    function test_shouldSetMetadataUri() external {
        ownership = new TokenBundleOwnership(address(singleton), address(this), "uri.pwn");

        assertEq(vm.load(address(ownership), METADATA_URI_SLOT), METADATA_URI_STORAGE_VALUE);
    }

}


/*----------------------------------------------------------*|
|*  # DEPLOY BUNDLE                                         *|
|*----------------------------------------------------------*/

contract TokenBundleOwnership_DeployBundle_Test is TokenBundleOwnershipTest {

    function test_shouldCloneSingleton() external {
        TokenBundle bundle = ownership.deployBundle();

        // Minimal Proxy Contract - https://eips.ethereum.org/EIPS/eip-1167
        bytes memory expectedCode = abi.encodePacked(
            hex"363d3d373d3d3d363d73", address(singleton), hex"5af43d82803e903d91602b57fd5bf3"
        );
        assertEq(keccak256(expectedCode), keccak256(address(bundle).code));
    }

    function test_shouldCallInitializeOnDeployedBundle() external {
        TokenBundle bundle = ownership.deployBundle();

        // Load initialized value (1 byte size) from the first slot with 0 offset
        uint256 bundleInitializedValue = uint256(vm.load(address(bundle), 0)) & 0xff;
        assertEq(bundleInitializedValue, 1);
        assertEq(address(bundle.ownershipContract()), address(ownership));
    }

    function test_shouldMintOwnershipToken() external {
        vm.prank(owner);
        TokenBundle bundle = ownership.deployBundle();

        bytes32 bundleOwnerValue = vm.load(
            address(ownership),
            keccak256(abi.encode(uint256(uint160(address(bundle))), OWNERS_SLOT))
        );

        assertEq(bundleOwnerValue, bytes32(uint256(uint160(owner))));
    }

    function test_shouldEmit_TokenBundleDeployed() external {
        // How to pre-compute contract address without create2?
        uint8 nonce = 100;
        vm.setNonce(address(ownership), nonce);
        address expectedAddress = address(uint160(uint256(
            keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(ownership), bytes1(nonce)))
        )));

        vm.expectEmit(true, true, false, false);
        emit TokenBundleDeployed(expectedAddress);

        ownership.deployBundle();
    }

    function test_shouldReturnDeployedBundleAddress() external {
        uint8 nonce = 100;
        vm.setNonce(address(ownership), nonce);
        address expectedAddress = address(uint160(uint256(
            keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(ownership), bytes1(nonce)))
        )));

        TokenBundle bundle = ownership.deployBundle();

        assertEq(address(bundle), expectedAddress);
    }

}


/*----------------------------------------------------------*|
|*  # ERC165                                                *|
|*----------------------------------------------------------*/

contract TokenBundleOwnership_SupportsInterface_Test is TokenBundleOwnershipTest {

    function test_shouldReturnFalse_whenUnsupportedInterface() external {
        assertFalse(ownership.supportsInterface(0x12345678));
    }

    function test_shouldSupport_ERC165() external {
        assertTrue(ownership.supportsInterface(type(IERC165).interfaceId));
    }

    function test_shouldSupport_ERC721() external {
        assertTrue(ownership.supportsInterface(type(IERC721).interfaceId));
    }

    function test_shouldSupport_ERC5646() external {
        assertTrue(ownership.supportsInterface(type(IERC5646).interfaceId));
    }

}


/*----------------------------------------------------------*|
|*  # ERC5646                                               *|
|*----------------------------------------------------------*/

contract TokenBundleOwnership_GetStateFingerprint_Test is TokenBundleOwnershipTest {

    uint256 tokenId = 42;


    function test_shouldFail_whenTokenIdBiggerThanMaxUint160() external {
        vm.expectRevert("Invalid token id");
        ownership.getStateFingerprint(type(uint168).max);
    }

    function test_shouldFail_whenTokenIdDoesNotExist() external {
        vm.expectRevert("Invalid token id");
        ownership.getStateFingerprint(tokenId);
    }

    function test_shouldCallTokenBundle() external {
        bytes32 mockedFingerprint = keccak256("fingerprint mock");
        // Mock owner of token id
        vm.store(
            address(ownership),
            keccak256(abi.encode(tokenId, OWNERS_SLOT)),
            bytes32(uint256(uint160(owner)))
        );
        vm.mockCall(
            address(uint160(tokenId)),
            abi.encodeWithSignature("getStateFingerprint(uint256)", tokenId),
            abi.encode(mockedFingerprint)
        );

        bytes32 fingerprint = ownership.getStateFingerprint(tokenId);

        assertEq(fingerprint, mockedFingerprint);
    }

}


/*----------------------------------------------------------*|
|*  # TOKEN URI                                             *|
|*----------------------------------------------------------*/

contract TokenBundleOwnership_TokenUri_Test is TokenBundleOwnershipTest {

    function test_shouldFail_whenTokenIdIsNotMinted() external {
        vm.expectRevert("ERC721: invalid token ID");
        ownership.tokenURI(42);
    }

    function test_shouldReturnStoredMetadataUri() external {
        // Mock token id 42
        bytes32 ownerSlot = keccak256(abi.encode(42, OWNERS_SLOT));
        vm.store(address(ownership), ownerSlot, bytes32(uint256(uint160(address(0x1)))));
        // Mock stored metadata uri with value "uri.pwn"
        vm.store(address(ownership), METADATA_URI_SLOT, METADATA_URI_STORAGE_VALUE);

        string memory uri = ownership.tokenURI(42);

        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("uri.pwn")));
    }

}


/*----------------------------------------------------------*|
|*  # SET METEDATA URI                                      *|
|*----------------------------------------------------------*/

contract TokenBundleOwnership_SetMetadataUri_Test is TokenBundleOwnershipTest {

    function test_shouldFail_whenCallerIsNotOwner() external {
        address notOwner = address(0x1234567890);

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(notOwner);
        ownership.setMetadataUri("uri.pwn");
    }

    function test_shouldSetMetadataUri() external {
        ownership.setMetadataUri("uri.pwn");

        assertEq(vm.load(address(ownership), METADATA_URI_SLOT), METADATA_URI_STORAGE_VALUE);
    }

}
