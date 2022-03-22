const chai = require("chai");
const { ethers } = require("hardhat");
const { smock } = require("@defi-wonderland/smock");

const expect = chai.expect;
chai.use(smock.matchers);


describe("TokenBundler contract", function() {

	let Bundler;
    let bundler;
    let bundlerIface;
    let ERC20, ERC721, ERC1155;
    let fDAI, fNFT, fGAME;

    let owner, other;

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
        ERC20 = await ethers.getContractFactory("Basic20");
        ERC721 = await ethers.getContractFactory("Basic721");
        ERC1155 = await ethers.getContractFactory("Basic1155");

        [owner, other] = await ethers.getSigners();
        bundlerIface = new ethers.utils.Interface([
            "event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)",
            "event BundleCreated(uint256 indexed id, address indexed creator)",
            "event BundleUnwrapped(uint256 indexed id)",
        ]);
    });

    beforeEach(async function() {
        bundler = await Bundler.deploy("https://test.uri/", 3);

        fDAI = await ERC20.deploy("Fake DAI", "fDAI");
        fNFT = await ERC721.deploy("Fake NFT", "fNFT");
        fGAME = await ERC1155.deploy("uri://");

        await fDAI.mint(owner.address, 1320);
        await fNFT.mint(owner.address, 312399);
        await fGAME.mint(owner.address, 861829, 840, "0x");

        await fDAI.approve(bundler.address, 1320);
        await fNFT.approve(bundler.address, 312399);
        await fGAME.setApprovalForAll(bundler.address, true);

        fullAssets = [
            {
                token: fDAI,
                category: CATEGORY.ERC20,
                amount: 1320,
                id: 0,
            },
            {
                token: fNFT,
                category: CATEGORY.ERC721,
                amount: 1,
                id: 312399,
            },
            {
                token: fGAME,
                category: CATEGORY.ERC1155,
                amount: 840,
                id: 861829,
            },
        ];

        assets = fullAssets.map(asset => {
            return [asset.token.address, asset.category, asset.amount, asset.id];
        });
    });


    it("Should create bundle", async function() {
        expect(await fDAI.balanceOf(bundler.address)).to.equal(0);
        expect(await fNFT.ownerOf(312399)).to.equal(owner.address);
        expect(await fGAME.balanceOf(bundler.address, 861829)).to.equal(0);

        await expect(
        	bundler.create(assets)
        ).to.not.be.reverted;

        expect(await fDAI.balanceOf(bundler.address)).to.equal(1320);
        expect(await fNFT.ownerOf(312399)).to.equal(bundler.address);
        expect(await fGAME.balanceOf(bundler.address, 861829)).to.equal(840);
    });

    it("Should unwrap bundle to bundle owner", async function() {
        await bundler.create(assets);

        await bundler.safeTransferFrom(owner.address, other.address, 1, 1, "0x");

        await expect(
            bundler.connect(other).unwrap(1)
        ).to.not.be.reverted;

        expect(await fDAI.balanceOf(bundler.address)).to.equal(0);
        expect(await fDAI.balanceOf(other.address)).to.equal(1320);
        expect(await fNFT.ownerOf(312399)).to.equal(other.address);
        expect(await fGAME.balanceOf(bundler.address, 861829)).to.equal(0);
        expect(await fGAME.balanceOf(other.address, 861829)).to.equal(840);
    });

});
