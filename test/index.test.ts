import { BigNumber } from "ethers";
import { formatEther, parseEther, parseUnits } from "ethers/lib/utils";

const { ethers } = require("hardhat");

describe("sahaba NFT Marketplace contract functions", async function () {
  // general variable ...
  let Market: any,
    market: any,
    tokenId: string,
    serviceFeesPrice: number,
    token: any;

  const Price = parseEther("5");

  beforeEach(async () => {
    Market = await ethers.getContractFactory("SahabaMarketplace");
    market = await Market.deploy();
    await market.deployed(); //deploy the NFTMarket contract

    const marketAddress = market.address;
    console.log("marketAddress", marketAddress);

    const collectionNameSymbol = await market.collectionNameSymbol;
    console.log("collectionNameSymbol", collectionNameSymbol());

    const collectionName = await market.collectionName;
    console.log("collectionName", collectionName());
  });

  it("should get listing  price", async function () {
    serviceFeesPrice = (await market.getServiceFeesPrice()).toString();
    console.log("Service Fees price", formatEther(serviceFeesPrice).toString());
  });

  it("should create nft and list it then get it ", async function () {
    const tx = await market.createAndListToken(
      "https://laravel.com/img/logomark.min.svg",
      parseEther(Price.toString())
    );

    const res = await tx.wait();

    const token_id = BigNumber.from(res.events[0].args.tokenId).toString();

    console.log("token id", token_id);
    tokenId = token_id;

    token = await market.getTokenById(token_id);
    console.log("token", token);
  });



  it("should buy token...", async function () {
    //create test tokens
    const tokenPrice = parseUnits(token.price).toString()
    console.log("tokenPrice", tokenPrice);
    
    const amount = parseEther(
      (parseFloat(serviceFeesPrice.toString()) + parseFloat(token.price.toString())).toString()
    );
    const res = await market.buyToken(tokenId, {
      value: parseEther(token.price).toString(),
      gasLimit: 1 * 10 ** 6,
    });
    console.log("token id", res.value.toString());
  });
});
