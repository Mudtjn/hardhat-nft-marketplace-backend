// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7 ; 

import "@openzeppelin/contracts/token/ERC721/IERC721.sol" ; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 

error NftMarketplace__PriceMustBeAboveZero() ;
error NftMarketplace__NotApprovedForMarketPlace() ; 
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId ) ; 
error NftMarketplace__NotOwner() ; 
error NftMarketplace__NotListed(address nftAddress, uint256 tokenId); 
error NftMarketplace__PriceNotMet(address nftAddress, uint256 tokenId, uint256 price) ; 
error NftMarketplace__NoProceeds();  
error NftMarketplace__TransferFailed(); 

contract NftMarketplace is ReentrancyGuard {

    struct Listing{
        uint256 price ; 
        address seller; 
    }

    event ItemListed(
        address indexed seller,
        address indexed nftAddress, 
        uint256 indexed tokenId, 
        uint256 price
    ); 

    event ItemBought(
        address indexed buyer, 
        address indexed nftAddress, 
        uint256 indexed tokenId, 
        uint256 price        
    ); 

    event ItemCanceled(
        address indexed seller ,
        address indexed nftAddress,
        uint256 indexed tokenId
    ); 

    //nft contract address -> nft token Id -> listing
    mapping(address => mapping(uint256 => Listing)) private s_listings  ;

    //seller address -> amount earned
    mapping(address => uint256 ) private s_proceeds ; 

    ///////////////////////
    ////// Modifiers //////
    ///////////////////////
    modifier  notListed(
        address nftAddress, 
        uint256 tokenId, 
        address owner
    ) 
    {
        Listing memory listing = s_listings[nftAddress][tokenId] ; 
        if(listing.price > 0 ){
            revert NftMarketplace__AlreadyListed(nftAddress, tokenId) ;
        }_; 
    }

    modifier isOwner(
        address nftAddress, 
        uint256 tokenId, 
        address spender
    )
    {
        IERC721 nft = IERC721(nftAddress) ; 
        address owner = nft.ownerOf(tokenId) ;

        if(spender != owner){
            revert NftMarketplace__NotOwner() ; 
        }
        _;
    }

    modifier isListed(
        address nftAddress,
        uint256 tokenId
    )
    {
        Listing memory listing = s_listings[nftAddress][tokenId] ; 
        if(listing.price <= 0){
            revert NftMarketplace__NotListed(nftAddress, tokenId)  ;
        }
        _; 
    }

    ///////////////////////
    //// Main Functions////
    //////////////////////

    function listItem(
        address nftAddress, 
        uint256 tokenId, 
        uint256 price
    ) 
    notListed(nftAddress, tokenId , msg.sender)
    isOwner(nftAddress, tokenId, msg.sender)
    external{
        if(price <= 0){revert NftMarketplace__PriceMustBeAboveZero(); }
        //1 .send nft to contract. contract "hold" the nft -> gas expensive 
        //2. owners can still hold their nft ,  but give approval to marketplace 
        // to sell nft

        //get approval to list
        IERC721 nft = IERC721(nftAddress) ;
        if(nft.getApproved(tokenId) != address(this)){
            revert NftMarketplace__NotApprovedForMarketPlace() ; 
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);

        emit ItemListed(msg.sender, nftAddress, tokenId, price) ;
    } 


    function buyItem(
        address nftAddress,
        uint256 tokenId
    )
    nonReentrant
    isListed(nftAddress, tokenId) 
    external
    payable
    {
        Listing memory listedItem = s_listings[nftAddress][tokenId] ;
        if(msg.value < listedItem.price ){
            revert NftMarketplace__PriceNotMet(nftAddress, tokenId, listedItem.price) ; 
        }
        s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value ; 
        delete (s_listings[nftAddress][tokenId]) ; 
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);      
    }


    function  cancelListing(
        address nftAddress,
        uint256 tokenId        
    )  
    isOwner(nftAddress, tokenId, msg.sender)
    isListed(nftAddress, tokenId)
    external {
        
        delete (s_listings[nftAddress][tokenId]); 
        emit ItemCanceled(msg.sender, nftAddress, tokenId) ; 

    }

    function updateListing(
        address nftAddress, 
        uint256 tokenId,
        uint256 newPrice
    )
    isListed(nftAddress, tokenId)
    isOwner(nftAddress, tokenId, msg.sender)
    external
    {
        s_listings[nftAddress][tokenId].price = newPrice ;  
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice); 
    }

    function withdrawProceeds()
    external{
        uint256 proceeds = s_proceeds[msg.sender] ; 
        if(proceeds<=0){
            revert NftMarketplace__NoProceeds(); 
        }
        s_proceeds[msg.sender] = 0 ; 

        (bool sent , ) = payable(msg.sender).call{value: proceeds}("") ;
        if(!sent){
            revert NftMarketplace__TransferFailed(); 
        }
    }


    ///////////////////////
    ////getter func ///////
    ///////////////////////

    function getListing(
        address nftAddress, 
        uint256 tokenId
    )
    external 
    view 
    returns(Listing memory)
    {
        return s_listings[nftAddress][tokenId] ; 
    }

    function getProceeds(
        address seller
    )
    external
    view 
    returns(uint256){
        return s_proceeds[seller] ; 
    }

}



    // 1. `listItem`: List Nfts on marketplace
    // 2. `buyItem`: Buy the NFts
    // 3. `cancelItem`: Cancel a listing
    // 4. `updateListing`: UpdatePrice
    // 5. `withdrawProceeds`: withdraw payments for my bought nfts
