# Dophinder NFT — Hackathon README (English)

## 1) Overview
- This Move smart contract implements a simple NFT on Sui in module `testnet_nft`.
- NFT struct: `TestnetNFT` with fields `name`, `description`, `url`.
- Public view getters are provided, and entrypoints include minting, transfer, update, and burn.

## 2) Contract Address
- Package ID (from your latest publish):
```
0x5d80d7e26fcc51f402fcee2228ddd713914d6d35e5803f1422a9d83af5be53b4
```
- Module: `testnet_nft`
- Full NFT type:
```
0x5d80d7e26fcc51f402fcee2228ddd713914d6d35e5803f1422a9d83af5be53b4::testnet_nft::TestnetNFT
```

## 3) Functions
Struct:
- `public struct TestnetNFT has key, store { id: UID, name: string::String, description: string::String, url: Url }`

View functions:
- `public fun name(nft: &TestnetNFT): &string::String`
- `public fun description(nft: &TestnetNFT): &string::String`
- `public fun url(nft: &TestnetNFT): &Url`

Entrypoints:
- `public fun mint_to_sender(name: vector<u8>, description: vector<u8>, url: vector<u8>, ctx: &mut TxContext)`
  - Mints a `TestnetNFT` to the sender with user-provided metadata.
- `public fun transfer(nft: TestnetNFT, recipient: address, _: &mut TxContext)`
  - Transfers an owned NFT to a recipient.
- `public fun update_description(nft: &mut TestnetNFT, new_description: vector<u8>, _: &mut TxContext)`
  - Updates the description field.
- `public fun burn(nft: TestnetNFT, _: &mut TxContext)`
  - Permanently deletes the NFT.

Notes:
- `mint_to_sender` expects UTF-8 bytes (`vector<u8>`) for `name`, `description`, and `url`. From the TypeScript SDK, you can pass plain strings using `tx.pure.string(...)` and the SDK will serialize to bytes.

## 4) How to Use (Frontend)
### Install SDK
```bash
pnpm add @mysten/sui @mysten/dapp-kit
```

### Initialize client and constants
```ts
import { SuiClient, getFullnodeUrl } from '@mysten/sui/client';

export const client = new SuiClient({ url: getFullnodeUrl('testnet') });
export const PACKAGE_ID = '0x5d80d7e26fcc51f402fcee2228ddd713914d6d35e5803f1422a9d83af5be53b4';
export const MODULE = 'testnet_nft';
export const NFT_TYPE = `${PACKAGE_ID}::${MODULE}::TestnetNFT`;
```

### Connect wallet (DApp Kit)
```tsx
'use client';
import { SuiClientProvider, WalletProvider as DAppKitWalletProvider, ConnectButton, useCurrentAccount } from '@mysten/dapp-kit';
import { getFullnodeUrl } from '@mysten/sui/client';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <SuiClientProvider networks={{ testnet: { url: getFullnodeUrl('testnet') } }} defaultNetwork="testnet">
      <DAppKitWalletProvider>{children}</DAppKitWalletProvider>
    </SuiClientProvider>
  );
}

export function WalletSection() {
  const account = useCurrentAccount();
  return (
    <div>
      <ConnectButton />
      <div>Address: {account?.address ?? 'Not connected'}</div>
    </div>
  );
}
```

### Mint to sender (with user inputs)
```tsx
import { Transaction } from '@mysten/sui/transactions';
import { useSignAndExecuteTransaction } from '@mysten/dapp-kit';
import { useState } from 'react';

export function MintForm() {
  const { mutateAsync: signAndExecute } = useSignAndExecuteTransaction();
  const [name, setName] = useState('Dophinder');
  const [description, setDescription] = useState('Community Workshop NFT');
  const [imageUrl, setImageUrl] = useState('https://example.com/image.jpg');

  const onMint = async () => {
    const tx = new Transaction();
    tx.moveCall({
      target: `${PACKAGE_ID}::${MODULE}::mint_to_sender`,
      arguments: [tx.pure.string(name), tx.pure.string(description), tx.pure.string(imageUrl)],
    });

    const result = await signAndExecute({ transaction: tx, chain: 'sui:testnet' });
    console.log('Mint result:', result);
  };

  return (
    <form onSubmit={(e) => { e.preventDefault(); onMint(); }}>
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Name" />
      <input value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Description" />
      <input value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} placeholder="Image URL" />
      <button type="submit">Mint TestnetNFT</button>
    </form>
  );
}
```

### Transfer, update description, burn
```tsx
import { Transaction } from '@mysten/sui/transactions';

// Transfer
const transferNft = async (nftId: string, recipient: string) => {
  const tx = new Transaction();
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::transfer`,
    arguments: [tx.object(nftId), tx.pure.address(recipient)],
  });
  await signAndExecute({ transaction: tx, chain: 'sui:testnet' });
};

// Update description
const updateDescription = async (nftId: string, newDesc: string) => {
  const tx = new Transaction();
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::update_description`,
    arguments: [tx.object(nftId), tx.pure.string(newDesc)],
  });
  await signAndExecute({ transaction: tx, chain: 'sui:testnet' });
};

// Burn
const burnNft = async (nftId: string) => {
  const tx = new Transaction();
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::burn`,
    arguments: [tx.object(nftId)],
  });
  await signAndExecute({ transaction: tx, chain: 'sui:testnet' });
};
```

### Query NFTs owned by a wallet
```ts
const nfts = await client.getOwnedObjects({
  owner: '<WALLET_ADDRESS>',
  filter: { StructType: NFT_TYPE },
  options: { showType: true, showContent: true },
});

for (const o of nfts.data) {
  const content = o.data?.content;
  if (content && 'fields' in content) {
    const f = (content as any).fields;
    console.log({ id: o.data?.objectId, name: f.name, description: f.description, url: f.url });
  }
}
```

### CLI examples
```bash
# Mint
sui client call \
  --package 0x5d80d7e26fcc51f402fcee2228ddd713914d6d35e5803f1422a9d83af5be53b4 \
  --module testnet_nft --function mint_to_sender \
  --args "My NFT" "Description here" "https://example.com/image.jpg" \
  --gas-budget 10000000

# Transfer
sui client call \
  --package 0x5d80d7e26fcc51f402fcee2228ddd713914d6d35e5803f1422a9d83af5be53b4 \
  --module testnet_nft --function transfer \
  --args <NFT_OBJECT_ID> <RECIPIENT_ADDRESS> \
  --gas-budget 10000000

# Update description
sui client call \
  --package 0x5d80d7e26fcc51f402fcee2228ddd713914d6d35e5803f1422a9d83af5be53b4 \
  --module testnet_nft --function update_description \
  --args <NFT_OBJECT_ID> "New description" \
  --gas-budget 10000000

# Burn
sui client call \
  --package 0x5d80d7e26fcc51f402fcee2228ddd713914d6d35e5803f1422a9d83af5be53b4 \
  --module testnet_nft --function burn \
  --args <NFT_OBJECT_ID> \
  --gas-budget 10000000
```

## 5) Hackathon Tips
- App ideas:
  - Gallery with mint form (name/description/image URL) and list of owned NFTs
  - Detail page to transfer, update description, and burn
- UI suggestions:
  - Form inputs for user-provided metadata
  - Actions: Mint, Transfer, Update, Burn, Refresh
- Notes:
  - The module path uses your published `PACKAGE_ID` and module name `testnet_nft`.
  - Strings are passed as bytes (`vector<u8>`) under the hood; `tx.pure.string(...)` handles this.
