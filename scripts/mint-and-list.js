const { ethers } = require("hardhat")

async function mintAndList() {
    const nftMarketplace = await ethers.getContract("NftMarketplace")
    const basicNft = await ethers.getContract("BasicNft")

    console.log("Minting Nft....")
    const mintTx = await basicNft.mintNft()
    const mintTxReceipt = await mintTx.wait(1)
    const TOKEN_ID = mintTxReceipt.events[0].args.tokenId

    console.log("Approving Nft...")
    const approveTx = await basicNft.approve(nftMarketplace.address, TOKEN_ID)
    await approveTx.wait(1)
    
    console.log("Listing Nft.....")
    const price = ethers.utils.parseEther("0.1")
    const listingTx = await nftMarketplace.listItem(basicNft.address, TOKEN_ID, price)
    await listingTx.wait(1)
}


mintAndList()
    .then(() => { process.exit(0) })
    .catch((err) => {
        console.log(err)
        process.exit(1)
    })
