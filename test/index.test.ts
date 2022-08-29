const { ethers } = require("hardhat");



describe("sahaba NFT Market", function () {
  it("Should create and execute market sales", async function () {
    const Market = await ethers.getContractFactory("Marketplace");
    const market:Marketplace  = await Market.deploy();
    await market.deployed(); //deploy the NFTMarket contract
    const marketAddress = market.address;


    //get the listing price
    let listingPrice = (await market.getListingPrice()).toString();
    let collectionNameSymbol = await market.collectionNameSymbol();
    let collectionName = await market.collectionName();

    //set an auction price
    const auctionPrice = ethers.utils.parseUnits("100", "ether");

    //create 2 test tokens
    await nft.createAndListToken("https://www.mytokenlocation.com", auctionPrice);
    await nft.createAndListToken("https://www.mytokenlocation2.com", auctionPrice);


});