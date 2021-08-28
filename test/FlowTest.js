const { expect } = require("chai");
const { ethers } = require("hardhat");

let ERC20, ERC721, ERC1155;
let BUNDLER, BNDLR;
let bundler1, bundler2;
let bundler1a, bundler2a;
let WETH, DAI, NFT, NFTb, GAME, GAMEb;
let WETH1, WETH2, DAI1, DAI2, NFT1, NFT2, NFTb1, NFTb2, GAME1, GAME2, GAMEb1, GAMEb2, BNDLR1, BNDLR2;

beforeEach(async function () {
  // Get the ContractFactory and Signers here.
  ERC20 = await ethers.getContractFactory("Basic20");
  ERC721 = await ethers.getContractFactory("Basic721");
  ERC1155 = await ethers.getContractFactory("Basic1155");

  BUNDLER = await ethers.getContractFactory("Bundler");

  [bundler1, bundler2, ...addrs] = await ethers.getSigners();
  bundler1a = await bundler1.getAddress();
  bundler2a = await bundler2.getAddress();

  WETH = await ERC20.deploy("Fake wETH", "WETH");
  DAI = await ERC20.deploy("Fake Dai", "DAI");
  NFT = await ERC721.deploy("Real NFT", "NFT");
  NFTb = await ERC721.deploy("Fake NFT", "NFT");
  GAME = await ERC1155.deploy("https://pwn.finance/game/")
  GAMEb = await ERC1155.deploy("https://pwn.finance/game/")
  BNDLR = await BUNDLER.deploy("https://bundle.pwn.finance/");

  await WETH.deployed();
  await DAI.deployed();
  await NFT.deployed();
  await NFTb.deployed();
  await GAME.deployed();
  await GAMEb.deployed();
  await BNDLR.deployed();

  await WETH.mint(bundler1a, 1000);
  await WETH.mint(bundler2a, 1000);

  await DAI.mint(bundler1a,1000);
  await DAI.mint(bundler2a,1000);

  await NFT.mint(bundler1a, 1);
  await NFT.mint(bundler1a, 2);
  await NFT.mint(bundler2a, 11);
  await NFT.mint(bundler2a, 12);

  await NFTb.mint(bundler1a, 1);
  await NFTb.mint(bundler1a, 2);
  await NFTb.mint(bundler2a, 11);
  await NFTb.mint(bundler2a, 12);

  await GAME.mint(bundler1a, 1, 1000, 0);
  await GAME.mint(bundler2a, 1, 1000, 0);

  await GAME.mint(bundler1a, 101, 1, 0);
  await GAME.mint(bundler1a, 102, 1, 0);
  await GAME.mint(bundler2a, 1001, 1, 0);
  await GAME.mint(bundler2a, 1002, 1, 0);

  await GAMEb.mint(bundler1a, 101, 1, 0);
  await GAMEb.mint(bundler1a, 102, 1, 0);
  await GAMEb.mint(bundler2a, 1001, 1, 0);
  await GAMEb.mint(bundler2a, 1002, 1, 0);

  WETH1 = WETH.connect(bundler1);
  WETH2 = WETH.connect(bundler2);
  DAI1 = DAI.connect(bundler1);
  DAI2 = DAI.connect(bundler2);
  NFT1 = NFT.connect(bundler1);
  NFT2 = NFT.connect(bundler2);
  NFTb1 = NFTb.connect(bundler1);
  NFTb2 = NFTb.connect(bundler2);
  GAME1 = GAME.connect(bundler1);
  GAME2 = GAME.connect(bundler2);
  GAMEb1 = GAMEb.connect(bundler1);
  GAMEb2 = GAMEb.connect(bundler2);
  BNDLR1 = BNDLR.connect(bundler1);
  BNDLR2 = BNDLR.connect(bundler2);

  DAI1.approve(BNDLR.address, 1000);
  DAI2.approve(BNDLR.address, 1000);
  WETH1.approve(BNDLR.address, 1000);
  WETH2.approve(BNDLR.address, 1000);

  NFT1.approve(BNDLR.address, 1);
  NFT1.approve(BNDLR.address, 2);
  NFTb1.approve(BNDLR.address, 1);
  NFTb1.approve(BNDLR.address, 2);
  GAME1.setApprovalForAll(BNDLR.address, true);
  GAMEb1.setApprovalForAll(BNDLR.address, true);

});

describe("TokenBundle contract", function () {
  it("Be possible to deploy", async function () {
    const Bundler = await ethers.getContractFactory("Bundler");
    const bundler = await Bundler.deploy("https://");
    await bundler.deployed();
    console.log("Bundler deployed at: " + bundler.address)
    !expect(bundler.address).to.equal('');
  });
});

describe("TokenBundle contract", function () {
  it("Should be possible to create bundle", async function () {
    BNDLR1.createBundle([0, DAI.address, 0, 100]);
    expect(await BNDLR.balanceOf(bundler1a, 1)).to.equal(1);
    expect(await DAI.balanceOf(bundler1a)).to.equal(900);
    expect(await DAI.balanceOf(bundler1a)).to.equal(100);

  });
  // it("Should allow being loaded with a ERC20", async function () {});
  // it("Should allow being loaded with 10 ERC20s", async function () {});
  // it("Be possible to deploy", async function () {});
  // it("Be possible to deploy", async function () {});
  // it("Be possible to deploy", async function () {});
});