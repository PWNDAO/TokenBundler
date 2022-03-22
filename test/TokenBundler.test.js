const chai = require("chai");
const { ethers } = require("hardhat");
const { smock } = require("@defi-wonderland/smock");

const expect = chai.expect;
chai.use(smock.matchers);


describe("TokenBundler contract", function() {

    let Bundler;
    let bundler;

    let addr1, addr2, addr3, asset1, asset2, asset3;

    let fullAssets;
    let assets;

    const CATEGORY = {
        ERC20: 0,
        ERC721: 1,
        ERC1155: 2,
        unknown: 3,
    };

    before(async function() {
        Bundler = await ethers.getContractFactory("TokenBundler");
        [addr1, addr2, addr3, asset1, asset2, asset3] = await ethers.getSigners();
    });

    beforeEach(async function() {
        bundler = await Bundler.deploy("https://test.uri/", 3);

        fullAssets = [
            {
                token: (await smock.fake("ERC20")),
                category: CATEGORY.ERC20,
                amount: 1320,
                id: 0,
            },
            {
                token: (await smock.fake("ERC721")),
                category: CATEGORY.ERC721,
                amount: 1,
                id: 312399,
            },
            {
                token: (await smock.fake("ERC1155")),
                category: CATEGORY.ERC1155,
                amount: 840,
                id: 861829,
            },
        ];

        assets = fullAssets.map(asset => {
            return [asset.token.address, asset.category, asset.amount, asset.id];
        });
    });


    describe("Constructor", function() {

        it("Should set max size", async function() {
            const maxSize = 37182377;

            bundler = await Bundler.deploy("https://test.uri/", maxSize);

            const setMaxSize = await bundler.maxSize();
            expect(setMaxSize).to.equal(maxSize);
        });

        it("Should set meta uri", async function() {
            const uri = "I am a test URI for Bundler metadata";

            bundler = await Bundler.deploy(uri, 10);

            const setUri = await bundler.uri(1);
            expect(setUri).to.equal(uri);
        });

    });


    describe("Create", function() {

        it("Should fail when passing empty array", async function() {
            await expect(
                bundler.create([])
            ).to.be.revertedWith("Need to bundle at least one asset");
        });

        it("Should fail when passing array bigger than max size", async function() {
            const fakeToken = await smock.fake("ERC20");
            assets.push([fakeToken.address, CATEGORY.ERC20, 123123, 0]);

            await expect(
                bundler.create(assets)
            ).to.be.revertedWith("Number of assets exceed max bundle size");
        });

        it("Should be able to pass one asset", async function() {
            await expect(
                bundler.create([assets[0]])
            ).to.not.be.reverted;
        });

        it("Should be able to pass max number of assets", async function() {
            bundler = await Bundler.deploy("https://test.uri/", 2);

            await expect(
                bundler.create([assets[1], assets[2]])
            ).to.not.be.reverted;
        });

        it("Should not join same assets if passed as separate ones", async function() {
            await expect(
                bundler.create([assets[0], assets[0], assets[0], assets[0]])
            ).to.be.revertedWith("Number of assets exceed max bundle size");
        });

        it("Should increase global id and use it as bundle id", async function() {
            const mockFactory = await smock.mock("TokenBundler");
            const mockBundler = await mockFactory.deploy("", 3);
            await mockBundler.setVariable("_id", 120);

            const bundleId1 = await mockBundler.callStatic.create(assets);
            await mockBundler.create(assets);

            expect(bundleId1.toNumber()).to.equal(121);

            const bundleId2 = await mockBundler.callStatic.create(assets);
            await mockBundler.create(assets);

            expect(bundleId2.toNumber()).to.equal(122);
        });

        it("Should create first bundle with id 1", async function() {
            const bundleId = await bundler.callStatic.create(assets);

            expect(bundleId.toNumber()).to.equal(1);
        });

        it("Should mint bundle token", async function() {
            const bundleId = await bundler.connect(addr2).callStatic.create(assets);
            await bundler.connect(addr2).create(assets);

            const balance = await bundler.balanceOf(addr2.address, bundleId);
            expect(balance).to.equal(1);
        });

        it("Should emit `TransferSingle` event", async function() {
            const bundleId = await bundler.connect(addr3).callStatic.create(assets);
            await expect(
                bundler.connect(addr3).create(assets)
            ).to.emit(bundler, "TransferSingle").withArgs(
                addr3.address, ethers.constants.AddressZero, addr3.address, bundleId, 1
            );
        });

        it("Should emit `BundleCreated` event", async function() {
            const bundleId = await bundler.connect(addr3).callStatic.create(assets);
            await expect(
                bundler.connect(addr3).create(assets)
            ).to.emit(bundler, "BundleCreated").withArgs(
                bundleId, addr3.address
            );
        });

        // Wait for Smock to implement reading private contract variables
        // https://github.com/defi-wonderland/smock/issues/14
        xit("Should increase global nonce");

        it("Should store asset under nonce", async function() {
            const mockFactory = await smock.mock("TokenBundler");
            const mockBundler = await mockFactory.deploy("", 3);
            const nonce = 120;
            await mockBundler.setVariable("_nonce", nonce);

            const bundleId = await mockBundler.callStatic.create(assets);
            await mockBundler.create(assets);

            for (i = 0; i < assets.length; i++) {
                const asset = await mockBundler.token(nonce + i + 1);
                expect(asset.assetAddress).to.equal(assets[i][0]);
                expect(asset.category).to.equal(assets[i][1]);
                expect(asset.amount).to.equal(assets[i][2]);
                expect(asset.id).to.equal(assets[i][3]);
            }
        });

        it("Should push asset nonce to bundle asset array", async function() {
            const mockFactory = await smock.mock("TokenBundler");
            const mockBundler = await mockFactory.deploy("", 3);
            const nonce = 120;
            await mockBundler.setVariable("_nonce", nonce);

            const bundleId = await mockBundler.callStatic.create(assets);
            await mockBundler.create(assets);

            const bundle = await mockBundler.bundle(bundleId);
            for (i = 0; i < assets.length; i++) {
                expect(bundle[i]).to.equal(nonce + i + 1);
            }
        });

        it("Should transfer assets to Bundler contract", async function() {
            await bundler.connect(addr3).create(assets);

            expect(fullAssets[0].token.transferFrom).to.have.been.calledOnceWith(addr3.address, bundler.address, fullAssets[0].amount);
            expect(fullAssets[1].token.transferFrom).to.have.been.calledOnceWith(addr3.address, bundler.address, fullAssets[1].id);
            expect(fullAssets[2].token.safeTransferFrom).to.have.been.calledOnceWith(addr3.address, bundler.address, fullAssets[2].id, fullAssets[2].amount, "0x");
        });

        it("Should fail when any asset transfer fails", async function() {
            fullAssets[0].token.transferFrom.reverts();

            await expect(
                bundler.create(assets)
            ).to.be.reverted;
        });

    });


    describe("Unwrap", function() {

        let bundleId;

        beforeEach(async function() {
            bundleId = await bundler.callStatic.create(assets);
            await bundler.create(assets);
        });


        it("Should fail when sender is not bundle owner", async function() {
            await expect(
                bundler.connect(addr2).unwrap(bundleId)
            ).to.be.revertedWith("Sender is not bundle owner");
        });

        it("Should transfer bundle assets to sender", async function() {
            await bundler.unwrap(bundleId);

            expect(fullAssets[0].token.transfer.atCall(0)).to.have.been.calledWith(addr1.address, fullAssets[0].amount);
            expect(fullAssets[1].token.transferFrom.atCall(2)).to.have.been.calledWith(bundler.address, addr1.address, fullAssets[1].id);
            expect(fullAssets[2].token.safeTransferFrom.atCall(2)).to.have.been.calledWith(bundler.address, addr1.address, fullAssets[2].id, fullAssets[2].amount, "0x");
        });

        it("Should fail when any asset transfer fails", async function() {
            fullAssets[0].token.transfer.reverts();

            await expect(
                bundler.unwrap(bundleId)
            ).to.be.reverted;
        });

        it("Should delete all assets", async function() {
            const mockFactory = await smock.mock("TokenBundler");
            const mockBundler = await mockFactory.deploy("", 3);
            const nonce = 120;
            await mockBundler.setVariable("_nonce", nonce);

            const bundleId = await mockBundler.callStatic.create(assets);
            await mockBundler.create(assets);

            await mockBundler.unwrap(bundleId);

            for (i = 0; i < assets.length; i++) {
                const asset = await mockBundler.token(nonce + i + 1);
                expect(asset.assetAddress).to.equal(ethers.constants.AddressZero);
                expect(asset.category).to.equal(0);
                expect(asset.amount).to.equal(0);
                expect(asset.id).to.equal(0);
            }
        });

        it("Should delete bundle asset array", async function() {
            const mockFactory = await smock.mock("TokenBundler");
            const mockBundler = await mockFactory.deploy("", 3);
            const nonce = 120;
            await mockBundler.setVariable("_nonce", nonce);

            const bundleId = await mockBundler.callStatic.create(assets);
            await mockBundler.create(assets);

            await mockBundler.unwrap(bundleId);

            const bundle = await mockBundler.bundle(bundleId);
            expect(bundle).to.have.length(0);
        });

        it("Should burn bundle token", async function() {
            await bundler.unwrap(bundleId);

            const balance = await bundler.balanceOf(addr1.address, bundleId);
            expect(balance).to.equal(0);
        });

        it("Should emit `TransferSingle` event", async function() {
            await expect(
                bundler.unwrap(bundleId)
            ).to.emit(bundler, "TransferSingle").withArgs(
                addr1.address, addr1.address, ethers.constants.AddressZero, bundleId, 1
            );
        });

        it("Should emit `BundleUnwrapped` event", async function() {
            await expect(
                bundler.unwrap(bundleId)
            ).to.emit(bundler, "BundleUnwrapped").withArgs(
                bundleId
            );
        });

    });


    describe("Supports interface", function() {

        function fSelector(signature) {
            const bytes = ethers.utils.toUtf8Bytes(signature)
            const hash = ethers.utils.keccak256(bytes);
            const selector = ethers.utils.hexDataSlice(hash, 0, 4);
            return ethers.BigNumber.from(selector);
        }


        it("Should support ERC165 interface", async function() {
            const interfaceId = fSelector("supportsInterface(bytes4)");

            const supportsERC165 = await bundler.supportsInterface(interfaceId);

            expect(supportsERC165).to.equal(true);
        });

        it("Should support ERC1155 interface", async function() {
            const interfaceId = fSelector("balanceOf(address,uint256)")
                .xor(fSelector("balanceOfBatch(address[],uint256[])"))
                .xor(fSelector("setApprovalForAll(address,bool)"))
                .xor(fSelector("isApprovedForAll(address,address)"))
                .xor(fSelector("safeTransferFrom(address,address,uint256,uint256,bytes)"))
                .xor(fSelector("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)"));

            const supportsERC1155 = await bundler.supportsInterface(interfaceId);

            expect(supportsERC1155).to.equal(true);
        });

        it("Should support ERC1155Receiver interface", async function() {
            const interfaceId = fSelector("onERC1155Received(address,address,uint256,uint256,bytes)")
                .xor(fSelector("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));

            const supportsERC1155Receiver = await bundler.supportsInterface(interfaceId);

            expect(supportsERC1155Receiver).to.equal(true);
        });

        it("Should support Token Bundler interface", async function() {
            const interfaceId = fSelector("create((address,uint8,uint256,uint256)[])")
                .xor(fSelector("unwrap(uint256)"))
                .xor(fSelector("token(uint256)"))
                .xor(fSelector("bundle(uint256)"))
                .xor(fSelector("maxSize()"));

            const supportsTokenBundler = await bundler.supportsInterface(interfaceId);

            expect(supportsTokenBundler).to.equal(true);
        });

    });

});
