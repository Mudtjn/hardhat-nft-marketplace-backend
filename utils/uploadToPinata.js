require('dotenv').config()
const pinataSDK = require('@pinata/sdk')
const path = require('path')
const fs = require('fs')
const { ConsoleErrorListener } = require('antlr4/error/ErrorListener')
const pinata = pinataSDK(
    process.env.PINATA_API_KEY,
    process.env.PINATA_API_SECRET_KEY
)

// pinata.testAuthentication().then((result) => {
//     //handle successful authentication here
//     console.log(result);
// }).catch((err) => {
//     //handle error here
//     console.log(err);
// });

async function storeImages(imagesFilePath) {
    const fullImagesPath = path.resolve(imagesFilePath)
    const files = fs.readdirSync(fullImagesPath)
    let responses = []
    for(fileIndex in files){
        const readableStreamForFiles
            = fs.createReadStream(`${fullImagesPath}/${files[fileIndex]}`)
        
        try {
            const response = await pinata.pinFileToIPFS(readableStreamForFiles)
            responses.push(response)
        } catch (err) {
            console.log("ERROR WHILE CONNECTING TO PINATA")
            console.log(err)
        }
    }
    return {responses, files}
}

async function storeTokenUriMetadata(metadata) {
    try {
        const response = await pinata.pinJSONToIPFS(metadata)
        return response
    } catch (e) {
        console.log("Error while uploading JSON")
        console.log(e)
    }
    return null
}

module.exports = {
    storeImages,
    storeTokenUriMetadata
}
