// contract url: https://mumbai.polygonscan.com/address/0x5063295d735F1F8A01a114c59e00837d63e6cdc9#code
// contract address : 0x5063295d735F1F8A01a114c59e00837d63e6cdc9

interface NFT {
    tokenId: number;
    mintedBy: string; // address
    currentOwner: string; // address
    previousOwner: string; // address
    price: number;
    collection_id: number;
    numberOfTransfers: number;
}

interface Marketplace {
    address: string;
    deployed: () => void;
    collectionName: string;
    collectionNameSymbol: string;
    createAndListToken: (tokenURI:string, price : number) => number; // tokenID
    buyToken: (tokenId: number) => void;
    changeTokenPrice: (tokenId: number, newPrice:number) => void; // you must be the owner of the token
    getListingPrice: () => number;
    setListingPrice: (newPrice: number) => number;
    getTokenOwner: (tokenId: number) => string;
    getTokenURI: (tokenId: number) => string;
    getTotalNumberOfTokensOwnedByAnAddress: (owner: string) => number;
    getTokenExists: (tokenId: number) => boolean
}