// SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <0.9.0;

import "./MarketEvents.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SahabaMarketplace is
    ERC721URIStorage,
    Ownable,
    MarketEvents,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address payable;

    Counters.Counter private _tokenIds;
    Counters.Counter private _collectionIds;

    // this contract's token collection name
    string public collectionName;
    // this contract's token symbol
    string public collectionNameSymbol;
    //people have to pay to puy their NFT on this marketplace
    uint256 private _service_fees =  25000000000000000; // 0.025 ether; // since 1 Ether is 10**18 Wei. 0.025 Ether is 0.025 * 10**18 Wei

    constructor() ERC721("Sahaba_NFT_Marketplace", "SAHABA") {
        collectionName = name();
        collectionNameSymbol = symbol();
    }

    struct MarketItem {
        uint256 tokenId;
        address mintedBy;
        address currentOwner;
        address previousOwner;
        uint256 price;
        uint256 collectionId;
        uint256 numberOfTransfers;
        bool isForSale;
    }

    struct Collections {
        uint256 tokenId;
        address createdBy;
        string name;
        address[] collaborators;
    }

    // a way to access values of the MarketItem struct above by passing an integer ID
    mapping(uint256 => MarketItem) private idMarketItem;

    mapping(uint256 => Collections) private idCollection;
    // check if token URI exists
    mapping(string => bool) public tokenURIExists;

    // check if collection name exists
    mapping(string => bool) public collectionNameExists;

    modifier itemOwnerSchema(uint256 tokenId) {
        // require caller of the function is not an empty address
        require(msg.sender != address(0), "address is missing");
        // get the token's owner
        bool tokenExists = _exists(tokenId);
        require(tokenExists, "token does not exist");

        address tokenOwner = ownerOf(tokenId);
        // check that token's owner should be equal to the caller of the function
        require(
            tokenOwner == msg.sender,
            "you're not allowed to maintain this token"
        );

        _;
    }

    modifier createAndListTokenSchema(uint256 price, string memory tokenURI) {
        // check if thic fucntion caller is not an zero address account
        require(msg.sender != address(0), "address not found !!");
        // check if the token URI already exists or not
        require(!tokenURIExists[tokenURI], "tokenURI is already minted");
        // check if the token URI already exists or not
        require(price > 0, "Price must be above zero");

        _;
    }

    modifier shoubBeCollaborator(uint256 _collectionId) {
        require(_collectionId > 0, "Collection ID must be above zero");

        Collections storage collection = idCollection[_collectionId];

        address[] memory collaborators = collection.collaborators;

        bool isCollaborator = false;

        for (uint256 i = 0; i < collaborators.length; i++) {
            if (collaborators[i] == msg.sender) {
                isCollaborator = true;
            }
        }

        require(
            isCollaborator || collection.createdBy == msg.sender,
            "You're not allowed to mint NFTs for this collection"
        );

        _;
    }

    modifier buyTokenSchema(uint256 tokenId) {
        // check if the function caller is not an zero account address
        require(msg.sender != address(0), "address not found");
        // check if the token exists or not
        bool tokenExists = _exists(tokenId);
        require(tokenExists, "token does not exist");
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
        _;
    }

    // create collection
    function createCollection(
        string memory _name,
        address[] memory _collaborator
    ) public nonReentrant returns (uint256) {
        require(
            !collectionNameExists[_name],
            "Collection name already exists, please choose another name"
        );
        //set a new collection id for the token to be minted
        _collectionIds.increment();
        uint256 newCollectionId = _collectionIds.current();

        idCollection[newCollectionId] = Collections(
            newCollectionId,
            payable(msg.sender),
            _name,
            _collaborator
        );

        emit CollectionCreated(
            newCollectionId,
            payable(msg.sender),
            _name,
            _collaborator
        );

        return newCollectionId;
    }

    // adding collaborators to a collection
    function addCollaborators(uint256 _collectionId, address _collaborator)
        public
        nonReentrant
        shoubBeCollaborator(_collectionId)
    {
        Collections storage collection = idCollection[_collectionId];

        collection.collaborators.push(_collaborator);

        idCollection[_collectionId] = collection;

        emit CollaboratorAdded(_collectionId, _collaborator);
    }

    // remove collaborators from a collection
    function removeCollaborators(uint256 _collectionId, address _collaborator)
        public
        nonReentrant
    {
        Collections storage collection = idCollection[_collectionId];
        require(
            collection.createdBy == msg.sender,
            "You are not the creator of this collection"
        );

        for (uint256 i; i < collection.collaborators.length; i++) {
            if (collection.collaborators[i] == _collaborator) {
                collection.collaborators[i] = collection.collaborators[
                    collection.collaborators.length - 1
                ];
                collection.collaborators.pop();
                break;
            }
        }

        idCollection[_collectionId] = collection;

        emit CollaboratorRemoved(_collectionId, _collaborator);
    }

    function calcItemPrice(uint256 price, uint256 feeAmount)
        public
        pure
        returns (uint256)
    {
        require(price > 0, "Price must be above zero");
        uint256 _price = price.sub(feeAmount);
        return _price;
    }

    function calcItemPlatformFee(uint256 price)
        public
        view
        returns (uint256)
    {
        require(price > 0, "Price must be above zero");
        uint256 feeAmount = price.mul(_service_fees).div(1e18);
        return feeAmount;
    }

    /// @notice function to create market item
    function createAndListToken(
        string memory tokenURI,
        uint256 price,
        uint256 _collectionId
    )
        public
        payable
        nonReentrant
        createAndListTokenSchema(price, tokenURI)
        shoubBeCollaborator(_collectionId)
        returns (uint256)
    {
        //set a new token id for the token to be minted
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId); // mint the token
        _setTokenURI(newItemId, tokenURI); //generate the URI

        MarketItem memory newItem = MarketItem(
            newItemId, // tokenId
            payable(msg.sender), // created by
            payable(msg.sender), // current owner
            payable(address(0)), // prev owner
            price, // price
            _collectionId, // collection id
            0, // number of transfer
            false // is fo sale
        );

        idMarketItem[newItemId] = newItem;

        //return token ID
        return newItemId;
    }

    // switch between set for sale and set not for sale
    function toggleForSale(uint256 _tokenId)
        public
        nonReentrant
        itemOwnerSchema(_tokenId)
    {
        address tokenOwner = ownerOf(_tokenId);
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

        emit NFT_Toggleed_Sale_Status(
            marketItem.collectionId,
            _tokenId,
            tokenOwner,
            marketItem.isForSale
        );
    }

    function buyToken(uint256 tokenId)
        public
        payable
        nonReentrant
        buyTokenSchema(tokenId)
    {
        address tokenOwner = ownerOf(tokenId);
        // get that token from all market items mapping and create a memory of it defined as (struct => MarketItem)
        MarketItem memory marketItem = idMarketItem[tokenId];

        uint256 platformFees = calcItemPlatformFee(marketItem.price);
        uint256 sellerAmmount = calcItemPrice(marketItem.price, platformFees);

        // send token's worth of ethers to the owner
        payable(tokenOwner).transfer(sellerAmmount); // send the ETH to the seller
        emit TransferSellerFees(tokenId, tokenOwner, sellerAmmount);
        // send the platform fees to the platform
        payable(owner()).transfer(platformFees);
        emit TransferPlatformFees(tokenId, owner(), platformFees);

        // transfer the token from owner to the caller of the function (buyer)
        _transfer(tokenOwner, msg.sender, tokenId); // _transfer(from, to, token_id)
        emit TransferNftOwnership(tokenId, tokenOwner, msg.sender);
        // update the token's previous owner
        marketItem.previousOwner = marketItem.currentOwner;
        // update the token's current owner
        marketItem.currentOwner = payable(msg.sender);
        // update the how many times this token was transfered
        marketItem.numberOfTransfers += 1;
        // set and update that token in the mapping
        idMarketItem[tokenId] = marketItem;

        emit NFTSold(
            marketItem.collectionId,
            tokenId,
            msg.sender,
            tokenOwner,
            marketItem.price,
            platformFees
        );
    }

    function changeTokenPrice(uint256 tokenId, uint256 _price)
        public
        nonReentrant
        itemOwnerSchema(tokenId)
    {
        MarketItem memory marketItem = idMarketItem[tokenId];

        // update token's price with new price
        marketItem.price = _price;

        // set and update that token in the mapping
        idMarketItem[tokenId] = marketItem;

        emit NFTPriceChanged(tokenId, marketItem.price, _price, msg.sender);
    }

    function getServiceFeesPrice() public view returns (uint256) {
        return _service_fees;
    }

    function setServiceFeesPrice(uint256 price) public nonReentrant onlyOwner {
        emit ServiceFeesPriceChanged(_service_fees, price);
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

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].currentOwner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].currentOwner == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getTotalNumberOfTokensOwnedByAnAddress(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 totalNumberOfTokensOwned = balanceOf(_owner);
        return totalNumberOfTokensOwned;
    }

    function burn(uint256 tokenId)
        public
        nonReentrant
        itemOwnerSchema(tokenId)
    {
        _burn(tokenId);

        emit NFTDeleted(tokenId, msg.sender);
    }
}
