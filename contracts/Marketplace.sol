// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Marketplace is ERC721URIStorage {
    //auto-increment field for each token
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _collectionIds;

    // this contract's token collection name
    string public collectionName;
    // this contract's token symbol
    string public collectionNameSymbol;
    //owner of the smart contract
    address payable owner;
    //people have to pay to puy their NFT on this marketplace
    uint256 private listingPrice = 0.025 ether;

    constructor() ERC721("sahabaNFT", "NFT") {
        collectionName = name();
        collectionNameSymbol = symbol();
        owner = payable(msg.sender);
    }

    struct MarketCollection {
        uint256 collectionId;
        string name;
        address payable created_by;
    }

    struct MarketItem {
        uint256 tokenId;
        address payable mintedBy;
        address payable currentOwner;
        address payable previousOwner;
        uint256 price;
        uint256 collection_id;
        uint256 numberOfTransfers;
    }

    // a way to access values of the MarketItem struct above by passing an integer ID
    mapping(uint256 => MarketItem) private idMarketItem;
    mapping(uint256 => MarketCollection) private idMarketCollection;
    // check if token URI exists
    mapping(string => bool) public tokenURIExists;


    /// @notice function to create market item
    function createCollection(string memory name) public returns (uint) {
        // check if thic fucntion caller is not an zero address account
        require(msg.sender != address(0), "address not found !!");

        _collectionIds.increment();
        uint256 newCollectionId = _collectionIds.current();

        MarketCollection memory newCollection = MarketCollection(
            newCollectionId,
            name,
            payable(msg.sender)
        );

        idMarketCollection[newCollectionId] = newCollection;

        //return token ID
        return newCollectionId;
    }


    /// @notice function to create market item
    function createAndListToken(string memory tokenURI, uint256 price, uint collection_id)
        public
        payable
        returns (uint)
    {
        // check if thic fucntion caller is not an zero address account
        require(msg.sender != address(0), "address not found !!");
        require(_exists(collection_id), "collection id  not found !!");
        require(_exists(price), "price not found !!");
        // check if the token URI already exists or not
        require(!tokenURIExists[tokenURI], "tokenURI is already minted");
        // check if the token URI already exists or not
        require(price > 0, "Price must be above zero");
        require(
            msg.value == listingPrice,
            "Price must be above of listing price"
        );

        //set a new token id for the token to be minted
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId); // mint the token
        _setTokenURI(newItemId, tokenURI); //generate the URI
        setApprovalForAll(address(this), true); //grant transaction permission to marketplace

        MarketItem memory newItem = MarketItem(
            newItemId,
            payable(msg.sender),
            payable(msg.sender),
            payable(address(0)),
            price,
            collection_id,
            0 // number of transfer
        );

        idMarketItem[newItemId] = newItem;

        //return token ID
        return newItemId;
    }

    /// @notice function to buy a token
    function buyToken(uint256 _tokenId) public payable {
        // check if the function caller is not an zero account address
        require(msg.sender != address(0), "address not found");
        // check if the token id of the token being bought exists or not
        require(_exists(_tokenId), "send a token of the item");
        // get the token's owner
        address tokenOwner = ownerOf(_tokenId);
        // token's owner should not be an zero address account
        require(tokenOwner != address(0), "token owner address is missed !!");
        // the one who wants to buy the token should not be the token's owner
        require(
            tokenOwner != msg.sender,
            "the one who wants to buy the token should not be the token's owner"
        );
        // get that token from all market items mapping and create a memory of it defined as (struct => MarketItem)
        MarketItem memory marketItem = idMarketItem[_tokenId];
        // price sent in to buy should be equal to or more than the token's price
        require(msg.value >= marketItem.price, "price is less than required");
        // send token's worth of ethers to the owner
        marketItem.currentOwner.transfer(msg.value);
        // transfer the token from owner to the caller of the function (buyer)
        _transfer(tokenOwner, msg.sender, _tokenId); // _transfer(from, to, token_id)
        // update the token's previous owner
        marketItem.previousOwner = marketItem.currentOwner;
        // update the token's current owner
        marketItem.currentOwner = payable(msg.sender);
        // update the how many times this token was transfered
        marketItem.numberOfTransfers += 1;
        // set and update that token in the mapping
        idMarketItem[_tokenId] = marketItem;
        //pay owner of contract the listing price
        payable(owner).transfer(listingPrice);
    }

    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice) public {
        // require caller of the function is not an empty address
        require(msg.sender != address(0), "address is missing");
        // require that token should exist
        require(_exists(_tokenId), "please send the token id");
        // get the token's owner
        address tokenOwner = ownerOf(_tokenId);
        // check that token's owner should be equal to the caller of the function
        require(tokenOwner == msg.sender, "you're not allowed to maintain this token");

        MarketItem memory marketItem = idMarketItem[_tokenId];
        // update token's price with new price
        marketItem.price = _newPrice;
        // set and update that token in the mapping
        idMarketItem[_tokenId] = marketItem;
    }


    /// @notice function to get listingprice
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function setListingPrice(uint256 _price) public returns (uint256) {
        require(
            msg.sender == address(this),
            "you don't have access to modify the token price"
        );
        listingPrice = _price;
        return listingPrice;
    }

    // get owner of the token
    function getTokenOwner(uint256 _tokenId) public view returns (address) {
        address _tokenOwner = ownerOf(_tokenId);
        return _tokenOwner;
    }

    // get metadata of the token
    function getTokenURI(uint _tokenId) public view returns (string memory) {
        string memory tokenMetaData = tokenURI(_tokenId);
        return tokenMetaData;
    }

    // get total number of tokens owned by an address
    function getTotalNumberOfTokensOwnedByAnAddress(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 totalNumberOfTokensOwned = balanceOf(_owner);
        return totalNumberOfTokensOwned;
    }

    // check if the token already exists
    function getTokenExists(uint256 _tokenId) public view returns (bool) {
        bool tokenExists = _exists(_tokenId);
        return tokenExists;
    }
}
