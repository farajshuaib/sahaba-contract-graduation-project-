
interface NFT {
    tokenId: number;
    mintedBy: string; // address
    currentOwner: string; // address
    previousOwner: string; // address
    price: number;
    numberOfTransfers: number;
}

interface Marketplace {
    address: string;
    deployed: () => void;
    collectionName: string;
    collectionNameSymbol: string;
    createAndListToken: (tokenURI:string, price : number, collection_id: number) => number; // tokenID
    buyToken: (tokenId: number) => void;
    changeTokenPrice: (tokenId: number, newPrice:number) => void; // you must be the owner of the token
    getServiceFeesPrice: () => number;
    setServiceFeesPrice: (newPrice: number) => number;
    getTokenOwner: (tokenId: number) => string;
    getTokenURI: (tokenId: number) => string;
    getTotalNumberOfTokensOwnedByAnAddress: (owner: string) => number;
    getTokenExists: (tokenId: number) => boolean;
    burn: (tokenId: number) => void;
}