const { network } = require("hardhat")
const {verify} = require("../utils/verify")
const {developmentChains} = require("../helper-hardhat-config")
require('dotenv').config()

module.exports = 
    async function ({ getNamedAccounts, deployments }) {
        
        const { deploy, log } = deployments
        const { deployer } = await getNamedAccounts() 
        
        const chainId = network.config.chainId
        log('---------------------------------')
        const nftMarketplace = await deploy("NftMarketplace", {
            from: deployer, 
            args: [], 
            log: true, 
            waitConfirmations: network.config.blockConfirmations || 1
        })

        if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
            log('----------------------------')
            log('Verifying...')
            await verify(nftMarketplace.address, [])
            log('Verified...')
        }

    }

module.exports.tags = ["all", "nftmarketplace"]
