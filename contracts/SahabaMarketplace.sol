// SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SahabaMarketplace is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _collectionIds;

    // this contract's token collection name
    string public collectionName;
    // this contract's token symbol
    string public collectionNameSymbol;
    //people have to pay to puy their NFT on this marketplace
    uint256 private _service_fees = 0.025 ether; // since 1 Ether is 10**18 Wei. 0.025 Ether is 0.025 * 10**18 Wei

    constructor() ERC721("Sahaba_NFT_Marketplace", "SAHABA") {
        collectionName = name();
        collectionNameSymbol = symbol();
    }

    struct MarketItem {
        uint256 tokenId;
        address payable mintedBy;
        address payable currentOwner;
        address payable previousOwner;
        uint256 price;
        uint256 platformFees;
        uint256 collectionId;
        uint256 numberOfTransfers;
        bool isForSale;
    }

    struct Collections {
        uint256 tokenId;
        address payable createdBy;
        string name;
        address[] collaborators;
    }

    event CollectionCreated(
        uint256 collectionId,
        address payable createdBy,
        string name,
        address[] collaborators
    );

    // a way to access values of the MarketItem struct above by passing an integer ID
    mapping(uint256 => MarketItem) private idMarketItem;

    mapping(uint256 => Collections) private idCollection;

    // check if token URI exists
    mapping(string => bool) public tokenURIExists;

    // create collection
    function createCollection(
        string memory _name,
        address[] memory _collaborators
    ) public returns (uint256) {
        //set a new collection id for the token to be minted
        _collectionIds.increment();
        uint256 newCollectionId = _collectionIds.current();

        idCollection[newCollectionId] = Collections(
            newCollectionId,
            payable(msg.sender),
            _name,
            _collaborators
        );

        emit CollectionCreated(
            newCollectionId,
            payable(msg.sender),
            _name,
            _collaborators
        );

        return newCollectionId;
    }

    // adding collaborators to a collection
    function addCollaborators(uint256 _collectionId, address _collaborators)
        public
    {
        require(
            idCollection[_collectionId].createdBy == msg.sender,
            "You are not the creator of this collection"
        );

        idCollection[_collectionId].collaborators.push(_collaborators);
    }

    // remove collaborators from a collection
    function removeCollaborators(uint256 _collectionId, address _collaborators)
        public
    {
        require(
            idCollection[_collectionId].createdBy == msg.sender,
            "You are not the creator of this collection"
        );

        for (uint256 i = 0; i < idCollection[_collectionId].collaborators.length; i++) {
            if (idCollection[_collectionId].collaborators[i] == _collaborators) {
                idCollection[_collectionId].collaborators.pop();
            }
        }
    }

    /// @notice function to create market item
    function createAndListToken(
        string memory tokenURI,
        uint256 price,
        uint256 _collectionId
    ) public payable returns (uint256) {
        // check if thic fucntion caller is not an zero address account
        require(msg.sender != address(0), "address not found !!");
        // check if the token URI already exists or not
        require(!tokenURIExists[tokenURI], "tokenURI is already minted");
        // check if the token URI already exists or not
        require(price > 0, "Price must be above zero");

        //set a new token id for the token to be minted
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        // calc the platform fees
        uint256 platformFees = 0;
        if (_service_fees > 0) {
            platformFees = (price * _service_fees) / 1 ether;
        }
        uint256 _price = (price - platformFees) / 1 ether;

        _mint(msg.sender, newItemId); // mint the token
        _setTokenURI(newItemId, tokenURI); //generate the URI
        setApprovalForAll(address(this), true); //grant transaction permission to marketplace

        MarketItem memory newItem = MarketItem(
            newItemId,
            payable(msg.sender),
            payable(msg.sender),
            payable(address(0)),
            _price,
            platformFees,
            _collectionId,
            0, // number of transfer
            false
        );

        idMarketItem[newItemId] = newItem;

        //return token ID
        return newItemId;
    }

    // switch between set for sale and set not for sale
    function toggleForSale(uint256 _tokenId) public {
        // require caller of the function is not an empty address
        require(msg.sender != address(0), "address not found !!");
        // require that token should exist
        require(_exists(_tokenId), "You are not the creator of this token");
        // get the token's owner
        address tokenOwner = ownerOf(_tokenId);
        // check that token's owner should be equal to the caller of the function
        require(
            tokenOwner == msg.sender,
            "you don't own this NFT you can't modify it"
        );
        // get that token from idMarketItem mapping and create a memory of it defined as (struct => MarketItem)
        MarketItem memory marketItem = idMarketItem[_tokenId];
        // if token's forSale is false make it true and vice versa
        if (marketItem.isForSale) {
            marketItem.isForSale = false;
        } else {
            marketItem.isForSale = true;
        }
        // set and update that token in the mapping
        idMarketItem[_tokenId] = marketItem;
    }

    function buyToken(uint256 tokenId) public payable {
        // check if the function caller is not an zero account address
        require(msg.sender != address(0), "address not found");
        // get the token's owner
        address tokenOwner = ownerOf(tokenId);
        // token's owner should not be an zero address account
        require(tokenOwner != address(0), "token owner address is missed !!");
        // the one who wants to buy the token should not be the token's owner
        require(
            tokenOwner != msg.sender,
            "the one who wants to buy the token should not be the token's owner"
        );
        // get that token from all market items mapping and create a memory of it defined as (struct => MarketItem)
        MarketItem memory marketItem = idMarketItem[tokenId];
        // price sent in to buy should be equal to or more than the token's price
        require(
            msg.value >= marketItem.price,
            "you're not sending enough money to buy this NFT"
        );

        // token should be for sale
        require(marketItem.isForSale, "sorry this NFT is not for salse");

        // send token's worth of ethers to the owner
        marketItem.currentOwner.transfer(marketItem.price);
        //pay owner of contract the service fees
        if (marketItem.platformFees > 0) {
            payable(owner()).transfer(marketItem.platformFees);
        }
        // transfer the token from owner to the caller of the function (buyer)
        _transfer(tokenOwner, msg.sender, tokenId); // _transfer(from, to, token_id)
        // update the token's previous owner
        marketItem.previousOwner = marketItem.currentOwner;
        // update the token's current owner
        marketItem.currentOwner = payable(msg.sender);
        // update the how many times this token was transfered
        marketItem.numberOfTransfers += 1;
        // set and update that token in the mapping
        idMarketItem[tokenId] = marketItem;
    }

    function changeTokenPrice(uint256 tokenId, uint256 _newPrice) public {
        // require caller of the function is not an empty address
        require(msg.sender != address(0), "address is missing");
        // get the token's owner
        address tokenOwner = ownerOf(tokenId);
        // check that token's owner should be equal to the caller of the function
        require(
            tokenOwner == msg.sender,
            "you're not allowed to maintain this token"
        );

        MarketItem memory marketItem = idMarketItem[tokenId];
        // update token's price with new price
        marketItem.price = _newPrice;
        // set and update that token in the mapping
        idMarketItem[tokenId] = marketItem;
    }

    function getServiceFeesPrice() public view returns (uint256) {
        return _service_fees;
    }

    function setServiceFeesPrice(uint256 price) public onlyOwner {
        require(
            msg.sender == owner(),
            "you don't have access to modify the platform service fees"
        );
        _service_fees = price;
    }

    function getMarketItem(uint256 tokenId)
        public
        view
        returns (MarketItem memory)
    {
        return idMarketItem[tokenId];
    }

    // check if the token already exists
    function getTokenExists(uint256 tokenId) public view returns (bool) {
        bool tokenExists = _exists(tokenId);
        return tokenExists;
    }

    function getCollection(uint256 _collectionId)
        public
        view
        returns (Collections memory)
    {
        return idCollection[_collectionId];
    }

    function getCollectionCollaborators(uint256 _collectionId)
        public
        view
        returns (address[] memory)
    {
        return idCollection[_collectionId].collaborators;
    }

    function burn(uint256 tokenId) public {
        bool tokenExists = _exists(tokenId);
        require(tokenExists, "token does not exist");

        address tokenOwner = ownerOf(tokenId);

        require(
            tokenOwner == msg.sender,
            "you're not allowed to maintain this token"
        );

        _burn(tokenId);
    }
}
