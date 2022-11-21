// SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <0.9.0;

contract MarketEvents {
    event CollectionCreated(
        uint256 collectionId,
        address payable createdBy,
        string name,
        address[] collaborators
    );

    event NFTCreated(
        uint256 collectionId,
        uint256 nftId,
        address payable createdBy,
        string image,
        uint256 price
    );

    event TransferPlatformFees(uint256 nftId, address platform_owner, uint256 amount);
    event TransferSellerFees(uint256 nftId, address seller, uint256 amount);

    event NFTDeleted(uint256 nftId, address deletedBy);

    event ServiceFeesPriceChanged(uint256 prevPrice, uint256 newPrice);

    event NFTSold(
        uint256 collectionId,
        uint256 nftId,
        address buyer,
        address seller,
        uint256 sellerAmount,
        uint256 feeAmount
    );

    event CollaboratorAdded(uint256 collectionId, address collaborator);

    event CollaboratorRemoved(uint256 collectionId, address collaborator);

    event NFT_Toggleed_Sale_Status(
        uint256 collectionId,
        uint256 nftId,
        address owner,
        bool isForSale
    );

    event NFTPriceChanged(
        uint256 nftId,
        uint256 prevPrice,
        uint256 newPrice,
        address owner
    );

    event TransferNftPriceToOwner(
        uint256 nftId,
        address currentOwner,
        uint256 price
    );

    event TransferNftOwnership(
        uint256 nftId,
        address currentOwner,
        address newOwner
    );

    event SetNftPlatformFee(uint256 nftId, address owner, uint256 fee);

    event SetNftPrice(uint256 nftId, address owner, uint256 price);

}
