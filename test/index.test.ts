import { BigNumber, Contract } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { SahabaMarketplace } from "../typechain-types";
import { step } from "mocha-steps";

describe("Sahaba NFT Marketplace smart contract interface", async function () {
  // general variable ...
  let market: SahabaMarketplace, tokenId: string, collection_id: string;

  const Price = parseEther("1");

  step("create and deploy the contract", async () => {
    const Market = await ethers.getContractFactory("SahabaMarketplace");
    market = await Market.deploy();
    await market.deployed(); //deploy the NFTMarket contract
  });

  step("should calc platform fee and NFT seller amount", async () => {
    const calcItemPlatformFee = await market.calcItemPlatformFee(Price);
    const fee = BigNumber.from(calcItemPlatformFee).toString();
    const calcItemPrice = await market.calcItemPrice(Price, fee);
    const sellerAmount = BigNumber.from(calcItemPrice).toString();
    assert.isNotNull(sellerAmount);
  });

  step("should get market address", () => {
    const marketAddress = market.address;
    assert.isNotNull(marketAddress);
  });

  step("should get market ERC721 collection name", () => {
    const collectionName = market.collectionName();
    assert.isNotNull(collectionName);
  });

  step("should get market ERC721 collection symbol", () => {
    const collectionNameSymbol = market.collectionNameSymbol();
    assert.isNotNull(collectionNameSymbol);
  });

  step("should get Service Fees", async function () {
    const serviceFeesPrice = (await market.getServiceFeesPrice()).toString();
    assert.isNotNull(serviceFeesPrice);
  });

  step("should update Service Fees", async function () {
    const serviceFeesPrice = await market.setServiceFeesPrice(
      parseEther("0.1")
    );
    assert.isNotNull(serviceFeesPrice);
  });

  step("should create Collection", async function () {
    const [addr1] = await ethers.getSigners();
    const address = await addr1.getAddress();

    const tx = await market.createCollection("testCollection", [address]);
    const res = await tx.wait();
    if (!res.events || res.events.length == 0) {
      assert.fail("No events emitted");
    }

    collection_id = BigNumber.from(res.events[0].args?.collectionId).toString();

    assert.isNotNull(collection_id);
  });

  step("should add Collection collaborators", async function () {
    const [_, addr1, addr2] = await ethers.getSigners();
    const address1 = await addr1.getAddress();

    if (!collection_id) assert.fail("No collection_id found");

    if (!address1) assert.fail("No address found to add as collaborator");

    const collaborator1 = await market.addCollaborators(
      collection_id,
      address1
    );

    assert.isNotNull(collaborator1);
  });

  step("should create nft and list it", async function () {
    const tx = await market.createAndListToken(
      "https://laravel.com/img/logomark.min.svg",
      Price,
      collection_id
    );

    const res = await tx.wait();

    if (!res.events || res.events?.length === 0) {
      assert.fail("No events emitted");
    }

    tokenId = BigNumber.from(res.events[0].args?.tokenId).toString();

    assert.isNotNull(tokenId);
  });

  step("should get token owner", async function () {
    const tokenOwner = await market.ownerOf(tokenId);
    assert.isNotNull(tokenOwner);
  });

  step("should get token URI", async function () {
    const tokenUri = await market.tokenURI(tokenId);
    assert.isNotNull(tokenUri);
  });

  step("should get token exists", async function () {
    const TokenExists = await market.getTokenExists(tokenId);

    assert.isNotNull(TokenExists);
  });

  step("should set NFT for sale", async function () {
    await market.toggleForSale(tokenId);
  });

  step("should set NFT for not sale", async function () {
    await market.toggleForSale(tokenId);
  });

  it("should change token price", async function () {
    await market.changeTokenPrice(tokenId, parseEther("0.5"));
  });

  step("should set NFT for sale again", async function () {
    await market.toggleForSale(tokenId);
  });

  step("should get collection details", async function () {
    await market.getCollection(collection_id);
  });

  step("should get collection collaborators", async function () {
    await market.getCollectionCollaborators(collection_id);
  });

  step("should remove collaborator", async function () {
    const [_, addr1] = await ethers.getSigners();
    const address1 = await addr1.getAddress();

    if (!collection_id) assert.fail("No collection_id found");

    if (!address1) assert.fail("No address found to add as collaborator");

    await market.removeCollaborators(collection_id, address1);
  });

  step("should buy token...", async function () {
    const [_, addr1] = await ethers.getSigners();

    if (!tokenId) assert.fail("No tokenId found to buy token");

    const accountBalance = addr1.getBalance();

    if (!accountBalance || (await accountBalance).isZero())
      assert.fail("No account balance found");

    const tx = await market.connect(addr1).buyToken(tokenId, {
      value: parseEther("0.5"),
    });

    if (!tx) assert.fail("No transaction found");

    const res = await tx.wait();

    if (!res || !res?.events || res?.events?.length === 0) {
      assert.fail("No events emitted");
    }

    assert.isNotNull(res.events[4].args?.buyer);
    assert.isNotNull(res.events[4].args?.seller);
    assert.isNotNull(BigNumber.from(res.events[0].args?.nftId).toString());
    assert.isNotNull(BigNumber.from(res.events[0].args?.amount).toString());
    assert.isNotNull(
      BigNumber.from(res.events[4].args?.sellerAmount).toString()
    );
    assert.isNotNull(BigNumber.from(res.events[4].args?.feeAmount).toString());
    assert.isNotNull(res.events[1].args?.platform_owner);
  });

  step("should get total number of tokens owned by address", async function () {
    const [_, addr1] = await ethers.getSigners();
    const address = await addr1.getAddress();

    if (!address) assert.fail("No address found to add as collaborator");

    const res = await market.getTotalNumberOfTokensOwnedByAnAddress(address);
    const tokens = BigNumber.from(res).toString();
    assert.isNotNull(tokens);
  });

  step("fetch my tokens", async function () {
    const [_, addr1] = await ethers.getSigners();
    const address = await addr1.getAddress();

    if (!address) assert.fail("No address found to add as collaborator");

    const res = await market.connect(addr1).fetchMyNFTs();
    assert.isNotNull(res);
  });

  it("should burn token", async function () {
    const [_, addr1] = await ethers.getSigners();
    const address = await addr1.getAddress();

    if (!address) assert.fail("No address found to add as collaborator");

    await market.connect(addr1).burn(tokenId);
  });
});
