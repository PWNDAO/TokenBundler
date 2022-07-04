const hardhat = require("hardhat");


const metadataUri = "https://test.uri/";
const maxBundleSize = 3;

async function main() {

    const Bundler = await hardhat.ethers.getContractFactory("TokenBundler");
    const bundler = await Bundler.deploy(metadataUri, maxBundleSize);

    console.log(" ⛏  Deploying TokenBundler...   (tx: " + bundler.deployTransaction.hash + ")");

    await bundler.deployed();

    console.log(" 🎉 TokenBundler contract deployed at " + bundler.address);

}


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
