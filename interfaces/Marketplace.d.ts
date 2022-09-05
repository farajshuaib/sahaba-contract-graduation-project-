interface NFT {
    tokenId: number;
    mintedBy: string; // address
    currentOwner: string; // address
    previousOwner: string; // address
    price: number;
    numberOfTransfers: number;
    forSale: boolean;
}

interface Marketplace {
    address: string;
    deployed: () => void;
    collectionName: string;
    collectionNameSymbol: string;
    createAndListToken: (tokenURI:string, price : number) => number; // tokenID
    buyToken: (tokenId: number) => void;
    changeTokenPrice: (tokenId: number, newPrice:number) => void; // you must be the owner of the token
    toggleForSale: (tokenId: number) => void; // you must be the owner of the token
    getListingPrice: () => number;
    setListingPrice: (newPrice: number) => number;
    getTokenOwner: (tokenId: number) => string;
    getTokenURI: (tokenId: number) => string;
    getTotalNumberOfTokensOwnedByAnAddress: (owner: string) => number;
    getTokenExists: (tokenId: number) => boolean
}