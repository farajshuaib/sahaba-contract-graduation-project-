import { BigNumber } from "ethers";
import { formatEther, parseEther, parseUnits } from "ethers/lib/utils";
import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { SahabaMarketplace } from "../typechain-types";

describe("sahaba NFT Marketplace contract functions", async function () {
  // general variable ...
  let market: SahabaMarketplace, tokenId: string;

  const Price = parseEther("1");

  beforeEach(async () => {
    const Market = await ethers.getContractFactory("SahabaMarketplace");
    market = await Market.deploy();
    await market.deployed(); //deploy the NFTMarket contract
  });

  it("should calc platform fee and NFT seller amount", async () => {
    const calcItemPlatformFee = await market.calcItemPlatformFee(Price);
    const fee = BigNumber.from(calcItemPlatformFee).toString();
    console.log(fee);
    const calcItemPrice = await market.calcItemPrice(Price, fee);
    const sellerAmount = BigNumber.from(calcItemPrice).toString();
    console.log(sellerAmount);
  });

  it("should get market address", () => {
    const marketAddress = market.address;
    assert.isNotNull(marketAddress);
  });

  it("should get market ERC721 collection name", () => {
    const collectionName = market.collectionName();
    assert.isNotNull(collectionName);
  });

  it("should get market ERC721 collection symbol", () => {
    const collectionNameSymbol = market.collectionNameSymbol();
    assert.isNotNull(collectionNameSymbol);
  });

  it("should get Service Fees", async function () {
    const serviceFeesPrice = (await market.getServiceFeesPrice()).toString();
    assert.isNotNull(serviceFeesPrice);
  });

  it("should update Service Fees", async function () {
    const serviceFeesPrice = await market.setServiceFeesPrice(
      parseEther("0.1")
    );
    assert.isNotNull(serviceFeesPrice);
  });

  it("should create Collection", async function () {
    const [deployer] = await ethers.getSigners();

    const address = await deployer.getAddress();

    const collection = await market.createCollection("collectionName", [
      address,
    ]);
    assert.isNotNull(collection);
  });

  it("should create nft and list it", async function () {
    const tx = await market.createAndListToken(
      "https://laravel.com/img/logomark.min.svg",
      parseEther(Price.toString()),
      1
    );

    const res = await tx.wait();

    if (!res.events || res.events?.length === 0) {
      assert.fail("No events emitted");
    }

    tokenId = BigNumber.from(res.events[0].args?.nftId).toString();

    console.log(tokenId);

    assert.isNotNull(tokenId);
  });

  it("should get token owner", async function () {
    const tokenOwner = await market.ownerOf(tokenId);
    assert.isNotNull(tokenOwner);
  });

  it("should get token URI", async function () {
    const tokenUri = await market.tokenURI(tokenId);
    assert.isNotNull(tokenUri);
  });

  it("should get total number of tokens owned by an address", async function () {
    const [deployer] = await ethers.getSigners();

    const address = await deployer.getAddress();

    const author_balance = await market.balanceOf(address);

    assert.isNotNull(author_balance);
  });

  it("should get token exists", async function () {
    const TokenExists = await market.getTokenExists(tokenId);
    assert.isNotNull(TokenExists);
  });

  it("should change token price", async function () {
    await market.changeTokenPrice(tokenId, parseEther("10"));
  });

  it("should buy token...", async function () {
    const [deployer] = await ethers.getSigners();

    const address = await deployer.getAddress();

    const tx = await market.buyToken(tokenId, {
      value: parseEther("10"),
    });

    const res = await tx.wait();

    if (!res.events || res.events?.length === 0) {
      assert.fail("No events emitted");
    }

    const buyer = res.events[0].args?.buyer;
    const seller = res.events[0].args?.seller;
    const nftId = res.events[0].args?.nftId;
    const price = res.events[0].args?.price;

    assert.isNotNull(buyer);
    assert.isNotNull(seller);
    assert.isNotNull(nftId);
    assert.isNotNull(price);
  });

  it("should burn token", async function () {
    await market.burn(tokenId);
  });
});
