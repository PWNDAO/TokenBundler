const chai = require("chai");
const { ethers } = require("hardhat");
const { smock } = require("@defi-wonderland/smock");

const expect = chai.expect;
chai.use(smock.matchers);


describe("Bundler", function() {

	let Bundler;
	let bundler;
	let bundlerIface;

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
		Bundler = await ethers.getContractFactory("Bundler");
		[addr1, addr2, addr3, asset1, asset2, asset3] = await ethers.getSigners();
		bundlerIface = new ethers.utils.Interface([
			"event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)",
			"event BundleCreated(uint256 indexed id, address indexed creator)",
    		"event BundleUnwrapped(uint256 indexed id)"
		]);
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
			try {
				await bundler.create([]);
				expect().fail();
			} catch(error) {
				expect(error.message).to.contain("revert");
				expect(error.message).to.contain("Need to bundle at least one asset");
			}
		});

		it("Should fail when passing array bigger than max size", async function() {
			const fakeToken = await smock.fake("ERC20");
			assets.push([fakeToken.address, CATEGORY.ERC20, 123123, 0]);

			try {
				await bundler.create(assets);
				expect().fail();
			} catch(error) {
				expect(error.message).to.contain("revert");
				expect(error.message).to.contain("Number of assets exceed max bundle size");
			}
		});

		it("Should be able to pass one asset", async function() {
			let failed = false;

			try {
				await bundler.create([assets[0]]);
			} catch {
				failed = true;
			}

			expect(failed).to.equal(false);
		});

		it("Should be able to pass max number of assets", async function() {
			bundler = await Bundler.deploy("https://test.uri/", 2);
			let failed = false;

			try {
				await bundler.create([assets[1], assets[2]]);
			} catch {
				failed = true;
			}

			expect(failed).to.equal(false);
		});

		it("Should not join same assets if passed as separate ones", async function() {
			try {
				await bundler.create([assets[0], assets[0], assets[0], assets[0]]);
				expect().fail();
			} catch(error) {
				expect(error.message).to.contain("revert");
				expect(error.message).to.contain("Number of assets exceed max bundle size");
			}
		});

		it("Should increase global id and use it as bundle id", async function() {
			const mockFactory = await smock.mock("Bundler");
			const mockBundler = await mockFactory.deploy("", 3);
			await mockBundler.setVariable("id", 120);

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
			const tx = await bundler.connect(addr3).create(assets);
			const response = await tx.wait();

			expect(response.logs.length).to.equal(2);
			const logDescription = bundlerIface.parseLog(response.logs[0]);
			expect(logDescription.name).to.equal("TransferSingle");
			expect(logDescription.args.operator).to.equal(addr3.address);
			expect(logDescription.args.from).to.equal(ethers.constants.AddressZero);
			expect(logDescription.args.to).to.equal(addr3.address);
			expect(logDescription.args.id).to.equal(bundleId);
			expect(logDescription.args.value).to.equal(1);
		});

		it("Should emit `BundleCreated` event", async function() {
			const bundleId = await bundler.connect(addr3).callStatic.create(assets);
			const tx = await bundler.connect(addr3).create(assets);
			const response = await tx.wait();

			expect(response.logs.length).to.equal(2);
			const logDescription = bundlerIface.parseLog(response.logs[1]);
			expect(logDescription.name).to.equal("BundleCreated");
			expect(logDescription.args.id).to.equal(bundleId);
			expect(logDescription.args.creator).to.equal(addr3.address);
		});

		// Wait for Smock to implement reading private contract variables
		// https://github.com/defi-wonderland/smock/issues/14
		xit("Should increase global nonce");

		it("Should store asset under nonce", async function() {
			const mockFactory = await smock.mock("Bundler");
			const mockBundler = await mockFactory.deploy("", 3);
			const nonce = 120;
			await mockBundler.setVariable("nonce", nonce);

			const bundleId = await mockBundler.callStatic.create(assets);
			await mockBundler.create(assets);

			for (i = 0; i < assets.length; i++) {
				const asset = await mockBundler.tokens(nonce + i + 1);
				expect(asset.assetAddress).to.equal(assets[i][0]);
				expect(asset.category).to.equal(assets[i][1]);
				expect(asset.amount).to.equal(assets[i][2]);
				expect(asset.id).to.equal(assets[i][3]);
			}
		});

		it("Should push asset nonce to bundle asset array", async function() {
			const mockFactory = await smock.mock("Bundler");
			const mockBundler = await mockFactory.deploy("", 3);
			const nonce = 120;
			await mockBundler.setVariable("nonce", nonce);

			const bundleId = await mockBundler.callStatic.create(assets);
			await mockBundler.create(assets);

			for (i = 0; i < assets.length; i++) {
				expect(await mockBundler.bundles(bundleId, i)).to.equal(nonce + i + 1);
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

			try {
				await bundler.create(assets);
				expect().fail();
			} catch(error) {
				expect(error.message).to.contain("revert");
			}
		});

	});


	describe("Unwrap", function() {

		let bundleId;

		beforeEach(async function() {
			bundleId = await bundler.callStatic.create(assets);
			await bundler.create(assets);
		});


		it("Should fail when sender is not bundle owner", async function() {
			try {
				await bundler.connect(addr2).unwrap(bundleId);
				expect().fail();
			} catch(error) {
				expect(error.message).to.contain("revert");
				expect(error.message).to.contain("Sender is not bundle owner");
			}
		});

		it("Should transfer bundle assets to sender", async function() {
			await bundler.unwrap(bundleId);

			expect(fullAssets[0].token.transfer.atCall(0)).to.have.been.calledWith(addr1.address, fullAssets[0].amount);
			expect(fullAssets[1].token.transferFrom.atCall(2)).to.have.been.calledWith(bundler.address, addr1.address, fullAssets[1].id);
			expect(fullAssets[2].token.safeTransferFrom.atCall(2)).to.have.been.calledWith(bundler.address, addr1.address, fullAssets[2].id, fullAssets[2].amount, "0x");
		});

		it("Should fail when any asset transfer fails", async function() {
			fullAssets[0].token.transfer.reverts();

			try {
				await bundler.unwrap(bundleId);
				expect().fail();
			} catch(error) {
				expect(error.message).to.contain("revert");
			}
		});

		it("Should delete all assets", async function() {
			const mockFactory = await smock.mock("Bundler");
			const mockBundler = await mockFactory.deploy("", 3);
			const nonce = 120;
			await mockBundler.setVariable("nonce", nonce);

			const bundleId = await mockBundler.callStatic.create(assets);
			await mockBundler.create(assets);

			await mockBundler.unwrap(bundleId);

			for (i = 0; i < assets.length; i++) {
				const asset = await mockBundler.tokens(nonce + i + 1);
				expect(asset.assetAddress).to.equal(ethers.constants.AddressZero);
				expect(asset.category).to.equal(0);
				expect(asset.amount).to.equal(0);
				expect(asset.id).to.equal(0);
			}
		});

		it("Should delete bundle asset array", async function() {
			const mockFactory = await smock.mock("Bundler");
			const mockBundler = await mockFactory.deploy("", 3);
			const nonce = 120;
			await mockBundler.setVariable("nonce", nonce);

			const bundleId = await mockBundler.callStatic.create(assets);
			await mockBundler.create(assets);

			await mockBundler.unwrap(bundleId);

			let failed = false;

			try {
				await mockBundler.bundles(bundleId, 0);
				expect().fail();
			} catch {
				failed = true;
			}

			expect(failed).to.equal(true);
		});

		it("Should burn bundle token", async function() {
			await bundler.unwrap(bundleId);

			const balance = await bundler.balanceOf(addr1.address, bundleId);
			expect(balance).to.equal(0);
		});

		it("Should emit `TransferSingle` event", async function() {
			const tx = await bundler.unwrap(bundleId);
			const response = await tx.wait();

			expect(response.logs.length).to.equal(2);
			const logDescription = bundlerIface.parseLog(response.logs[0]);
			expect(logDescription.name).to.equal("TransferSingle");
			expect(logDescription.args.operator).to.equal(addr1.address);
			expect(logDescription.args.from).to.equal(addr1.address);
			expect(logDescription.args.to).to.equal(ethers.constants.AddressZero);
			expect(logDescription.args.id).to.equal(bundleId);
			expect(logDescription.args.value).to.equal(1);
		});

		it("Should emit `BundleUnwrapped` event", async function() {
			const tx = await bundler.unwrap(bundleId);
			const response = await tx.wait();

			expect(response.logs.length).to.equal(2);
			const logDescription = bundlerIface.parseLog(response.logs[1]);
			expect(logDescription.name).to.equal("BundleUnwrapped");
			expect(logDescription.args.id).to.equal(bundleId);
		});

	});

});
