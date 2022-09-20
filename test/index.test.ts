import { formatEther, parseEther } from "ethers/lib/utils";

const { ethers } = require("hardhat");

describe("sahaba NFT Marketplace contract functions", async function () {
  // general variable ...
  let Market: any,
    market: any,
    tokenId: number,
    listingPrice: number,
    collectionId: number;

  const Price = parseEther("100");
  
  beforeEach(async () => {
    Market = await ethers.getContractFactory("SahabaMarketplace");
    market = await Market.deploy();
    await market.deployed(); //deploy the NFTMarket contract

    const marketAddress = market.address;
    console.log("marketAddress", marketAddress);
    const collectionNameSymbol = await market.collectionNameSymbol;
    console.log("collectionNameSymbol", collectionNameSymbol);
    const collectionName = await market.collectionName;
    console.log("collectionName", collectionName);
  });

  it("should get listing  price", async function () {
    //get the listing price
    listingPrice = (await market.getListingPrice()).toString();
    console.log(" listing price", listingPrice);
  });

  it("Should create collection", async function () {
    const res = await market.createCollection("art");
    console.log("collectionId id", res.value);
    collectionId = res.value;
  });

  it("should create nft and list it", async function () {
    //create test tokens
    const res = await market.createAndListToken(
      "https://laravel.com/img/logomark.min.svg",
      Price,
      collectionId
    );
    console.log("token id", res.value.toString());
    tokenId = res.value;
  });

  it("should buy token...", async function () {
    //create test tokens
    const res = await market.buyToken(0);
    console.log("token id", res.value.toString());
  });
});
