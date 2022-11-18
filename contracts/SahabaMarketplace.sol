// SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <0.9.0;

import "./MarketEvents.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SahabaMarketplace is
    ERC721URIStorage,
    Ownable,
    MarketEvents,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address payable;
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

    function calcItemPrice(
        uint256 tokenId,
        uint256 price,
        uint256 platformFees
    ) private itemOwnerSchema(tokenId) returns (uint256) {
        require(price > 0, "Price must be above zero");
        // calc the platform fees
        uint256 _price = (price - platformFees) / 1 ether;
        emit SetNftPrice(tokenId, msg.sender, _price);
        return _price;
    }

    function calcItemPlatformFee(uint256 tokenId, uint256 price)
        private
        itemOwnerSchema(tokenId)
        returns (uint256)
    {
        require(price > 0, "Price must be above zero");
        uint256 platformFees = 0;
        if (_service_fees > 0) {
            platformFees = (price * _service_fees) / 1 ether;
            emit SetNftPlatformFee(tokenId, msg.sender, platformFees);
        }
        return platformFees;
    }

    // create collection
    function createCollection(
        string memory _name,
        address[] memory _collaborator
    ) public returns (uint256) {
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

    /// @notice function to create market item
    function createAndListToken(
        string memory tokenURI,
        uint256 price,
        uint256 _collectionId
    )
        public
        payable
        createAndListTokenSchema(price, tokenURI)
        shoubBeCollaborator(_collectionId)
        returns (uint256)
    {
        //set a new token id for the token to be minted
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId); // mint the token
        _setTokenURI(newItemId, tokenURI); //generate the URI
        setApprovalForAll(address(this), true); //grant transaction permission to marketplace
        uint256 platformFees = calcItemPlatformFee(newItemId, price);
        uint256 _price = calcItemPrice(newItemId, price, platformFees);

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
    function toggleForSale(uint256 _tokenId) public itemOwnerSchema(_tokenId) {
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

    function buyToken(uint256 tokenId) public payable buyTokenSchema(tokenId) {
        _buyToken(tokenId, address(0));
    }

    // buy token
    function buyTokenWithERC20(uint256 tokenId, address _payToken)
        public
        payable
        buyTokenSchema(tokenId)
    {
        _buyToken(tokenId, _payToken);
    }

    function _buyToken(uint256 tokenId, address _payToken) internal {
        address tokenOwner = ownerOf(tokenId);
        // get that token from all market items mapping and create a memory of it defined as (struct => MarketItem)
        MarketItem memory marketItem = idMarketItem[tokenId];

        // send token's worth of ethers to the owner
        if (_payToken == address(0)) {
            marketItem.currentOwner.transfer(marketItem.price);
            //pay owner of contract the service fees
            if (marketItem.platformFees > 0) {
                // send the platform fees to the platform
                payable(owner()).transfer(marketItem.platformFees);
                emit TransferPlatformFees(tokenId, marketItem.platformFees);
            }
        } else {
            IERC20(_payToken).transferFrom(
                _msgSender(),
                marketItem.currentOwner,
                marketItem.price
            );
            //pay owner of contract the service fees
            if (marketItem.platformFees > 0) {
                // send the platform fees to the platform in other currency
                IERC20(_payToken).transferFrom(
                    _msgSender(),
                    owner(),
                    marketItem.platformFees
                );
                emit TransferPlatformFees(tokenId, marketItem.platformFees);
            }
        }

        emit TransferNftPriceToOwner(
            tokenId,
            marketItem.currentOwner,
            marketItem.price
        );

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
            marketItem.price
        );
    }

    function changeTokenPrice(uint256 tokenId, uint256 _newPrice)
        public
        itemOwnerSchema(tokenId)
    {
        MarketItem memory marketItem = idMarketItem[tokenId];

        uint256 platformFees = calcItemPlatformFee(
            marketItem.tokenId,
            _newPrice
        );
        uint256 _price = calcItemPrice(
            marketItem.tokenId,
            _newPrice,
            platformFees
        );

        emit NFTPriceChanged(tokenId, marketItem.price, _price, msg.sender);
        // update token's price with new price
        marketItem.platformFees = platformFees;
        marketItem.price = _price;

        // set and update that token in the mapping
        idMarketItem[tokenId] = marketItem;
    }

    function getServiceFeesPrice() public view returns (uint256) {
        return _service_fees;
    }

    function setServiceFeesPrice(uint256 price) public onlyOwner {
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

    function burn(uint256 tokenId) public itemOwnerSchema(tokenId) {
        _burn(tokenId);

        emit NFTDeleted(tokenId, msg.sender);
    }
}
