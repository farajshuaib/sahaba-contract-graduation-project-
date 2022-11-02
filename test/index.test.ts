import { BigNumber } from "ethers";
import { formatEther, parseEther, parseUnits } from "ethers/lib/utils";
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("sahaba NFT Marketplace contract functions", async function () {
  // general variable ...
  let Market: any,
    market: any,
    tokenId: string,
    serviceFeesPrice: number,
    address: string,
    token: any;

  const Price = parseEther("0.1");


  beforeAll(async () => {
    Market = await ethers.getContractFactory("SahabaMarketplace");
    market = await Market.deploy();
    address = await market.address;
    await market.deployed(); //deploy the NFTMarket contract

    const marketAddress = market.address;
    console.log("marketAddress", marketAddress);

    const collectionNameSymbol = await market.collectionNameSymbol;
    console.log("collectionNameSymbol", collectionNameSymbol());

    const collectionName = await market.collectionName;
    console.log("collectionName", collectionName());
  });

  it("should get Service Fees", async function () {
    serviceFeesPrice = (await market.getServiceFeesPrice()).toString();
    console.log("Service Fees price", formatEther(serviceFeesPrice).toString());
  });

  it("should update Service Fees", async function () {
    serviceFeesPrice = (
      await market.setServiceFeesPrice(parseEther("0.1"))
    ).toString();
    console.log("Service Fees price", formatEther(serviceFeesPrice).toString());
  });

  it("should create nft and list it", async function () {
    const tx = await market.createAndListToken(
      "https://laravel.com/img/logomark.min.svg",
      parseEther(Price.toString())
    );

    const res = await tx.wait();

    const token_id = BigNumber.from(res.events[0].args.tokenId).toString();

    console.log("token id", token_id);
    tokenId = token_id;
  });

  it("should get token by id", async function () {
    token = await market.getTokenById(tokenId);
    console.log("token", token);
  });

  it("should get token owner", async function () {
    const tokenOwner = await market.getTokenOwner(tokenId);
    console.log("tokenOwner", tokenOwner);
  });

  it("should get token URI", async function () {
    const tokenUri = await market.getTokenURI(tokenId);
    console.log("tokenUri", tokenUri);
  });

  it("should get total number of tokens owned by an address", async function () {
    const author_balance = await market.getTotalNumberOfTokensOwnedByAnAddress(
      address
    );
    console.log("author_balance", author_balance);
  });

  it("should get token exists", async function () {
    const TokenExists = await market.getTokenExists(tokenId);
    console.log("TokenExists", TokenExists);
  });

  it("should change token price", async function () {
    await market.changeTokenPrice(tokenId, parseEther("10"));
  });

  it("should buy token...", async function () {
    const tokenPrice = parseUnits(token.price).toString();
    console.log("tokenPrice", tokenPrice);

    const amount = parseEther(
      (
        parseFloat(serviceFeesPrice.toString()) +
        parseFloat(token.price.toString())
      ).toString()
    );
    const res = await market.buyToken(tokenId, {
      value: parseEther(token.price).toString(),
      gasLimit: 1 * 10 ** 6,
    });
    console.log("token id", res.value.toString());
  });

  it("should burn token", async function () {
    await market.burn(tokenId);
  });
});
