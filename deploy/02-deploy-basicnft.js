const { network } = require("hardhat")
const {verify} = require("../utils/verify")
const {developmentChains} = require("../helper-hardhat-config")
require('dotenv').config()

module.exports =
    async function ({ getNamedAccounts, deployments }) {
        
        const { deploy, log } = deployments
        const { deployer } = await getNamedAccounts()
        const chainId = network.config.chainId

        const _args = []

        const basicNft = await deploy("BasicNft", {
            from: deployer,
            args: _args, 
            log: true,
            waitConfirmations: network.config.blockConfirmations || 1
        })

        if (!developmentChains.includes(network.name) && 
        process.env.ETHERSCAN_API_KEY) {
            log('--------------------------')
            log('Verifying...')
            await verify(basicNft.address, _args)
            log('--------------------------')
        }
    
    }

module.exports.tags = ["all", "basicnft"]
