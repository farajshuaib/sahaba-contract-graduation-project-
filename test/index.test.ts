const { ethers } = require("hardhat");



describe("sahaba NFT Market", async function () {
  it("Should create and execute market sales", async function () {
    const Market = await ethers.getContractFactory("SahabaMarketplace");
    const market:Marketplace  = await Market.deploy();
    await market.deployed(); //deploy the NFTMarket contract
    const marketAddress = market.address;


    //get the listing price
    let listingPrice = (await market.getListingPrice()).toString();
    console.log("listingPrice",listingPrice)
    let collectionNameSymbol = await market.collectionNameSymbol;
    console.log("collectionNameSymbol",collectionNameSymbol)
    let collectionName = await market.collectionName;
    console.log("collectionName",collectionName)

    //set an auction price
    const auctionPrice = ethers.utils.parseUnits("100", "ether");

    //create 2 test tokens
    await market.createAndListToken("https://www.mytokenlocation.com", auctionPrice, 1);
    await market.createAndListToken("https://www.mytokenlocation2.com", auctionPrice, 1);
  })

});