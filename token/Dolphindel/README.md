# Dolphindel Token — Hackathon README

## 1. Overview
- This Move smart contract implements a fungible token on Sui using the standard `Coin<T>` pattern.
- The contract creates:
  - Immutable Coin Metadata (name, description, decimals)
  - A `TreasuryCap` that authorizes minting new tokens
- Goal: Provide a mintable test token for hackathon demos (wallet UI, faucet, basic transfers, and starter DeFi examples).

## 2. Contract Address
- Package ID:

```
0xdacc8fff1280c1050026fc8c656293ce59831e8c9dbc64bd5dfb4ea37c12c4cb
```

- Module: `DL`
- Full Coin Type:

```
0x2::coin::Coin<0xdacc8fff1280c1050026fc8c656293ce59831e8c9dbc64bd5dfb4ea37c12c4cb::DL::DL>
```

- Decimals: `9` (that means 1 token = 1_000_000_000 units)

> If your deployed package ID differs, replace it accordingly.

### TreasuryCap Object ID (for Minting)
- Known `TreasuryCap<DL>` object (owner must be able to sign with this wallet):

```
0x8ed3019d55564a4ea2321c37f409e8058b46c8af766323e20d3ea0a119728fb0
```

⚠️ Important:
- Only the wallet that OWNS this TreasuryCap can call `mint_token` successfully.
- If you are not the owner, you MUST self-deploy your own package to obtain your own `TreasuryCap<DL>` (recommended), or the TreasuryCap owner would have to transfer it to you (not recommended for security).
- Do not hardcode a foreign TreasuryCap in public apps.

If this changes, query it using the discovery snippet below.

## 3. Functions
This token follows Sui’s standard token initialization pattern.

- `public fun init(witness: DL, ctx: &mut TxContext)`
  - Called once during package publish to initialize the token.
  - Creates `TreasuryCap<DL>` and Coin Metadata, then transfers the `TreasuryCap` to the publisher.
  - Params:
    - `witness: DL` — one-time witness type
    - `ctx: &mut TxContext`
  - Returns: none

- `entry fun mint_token(treasury_cap: &mut TreasuryCap<DL>, ctx: &mut TxContext)`
  - Mints a fixed amount of tokens to the transaction sender.
  - Params:
    - `treasury_cap: &mut TreasuryCap<DL>`
    - `ctx: &mut TxContext`
  - Returns: none (the newly minted `Coin<DL>` is transferred to `ctx.sender()`)

Notes:
- In this template, `mint_token` does not accept amount/recipient. For public faucets, you may extend it to `mint(amount, recipient)` with appropriate safeguards.

## 4. How to Use (Frontend)
### Install SDK
```bash
pnpm add @mysten/sui @mysten/dapp-kit
```

### Initialize Client and Constants
```ts
import { SuiClient, getFullnodeUrl } from '@mysten/sui/client';

export const client = new SuiClient({ url: getFullnodeUrl('testnet') });
export const PACKAGE_ID = '0xdacc8fff1280c1050026fc8c656293ce59831e8c9dbc64bd5dfb4ea37c12c4cb';
export const MODULE = 'DL';
export const COIN_TYPE = `${PACKAGE_ID}::${MODULE}::DL`;
```

### Connect a Wallet (DApp Kit)
Client-side provider:
```tsx
'use client';
import { SuiClientProvider, WalletProvider as DAppKitWalletProvider } from '@mysten/dapp-kit';
import { getFullnodeUrl } from '@mysten/sui/client';

export function DAppKitProvider({ children }: { children: React.ReactNode }) {
  return (
    <SuiClientProvider
      networks={{ testnet: { url: getFullnodeUrl('testnet') } }}
      defaultNetwork="testnet"
    >
      <DAppKitWalletProvider>{children}</DAppKitWalletProvider>
    </SuiClientProvider>
  );
}
```

Connect button and current account:
```tsx
import { ConnectButton, useCurrentAccount } from '@mysten/dapp-kit';

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

### Find TreasuryCap (Discovery) — optional
```ts
// Only the TreasuryCap owner can mint
const { data } = await client.getOwnedObjects({
  owner: '<YOUR_ADDRESS>',
  filter: { StructType: `0x2::coin::TreasuryCap<${COIN_TYPE}>` },
  options: { showType: true, showContent: true },
});

const treasuryCapId = data[0]?.data?.objectId;
```

### Mint using a known TreasuryCap ID
```tsx
import { Transaction } from '@mysten/sui/transactions';
import { useSignAndExecuteTransaction } from '@mysten/dapp-kit';

const KNOWN_TREASURY_CAP = '0x8ed3019d55564a4ea2321c37f409e8058b46c8af766323e20d3ea0a119728fb0';

export function MintButton() {
  const { mutateAsync: signAndExecute } = useSignAndExecuteTransaction();

  const onMint = async () => {
    const tx = new Transaction();
    tx.moveCall({
      target: `${PACKAGE_ID}::${MODULE}::mint_token`,
      arguments: [tx.object(KNOWN_TREASURY_CAP)],
    });

    const result = await signAndExecute({ transaction: tx, chain: 'sui:testnet' });
    console.log('Mint result:', result);
  };

  return <button onClick={onMint}>Mint DL</button>;
}
```

### Read Metadata and Balances
```ts
// Metadata
const meta = await client.getCoinMetadata({ coinType: COIN_TYPE });
console.log('Symbol:', meta?.symbol, 'Decimals:', meta?.decimals);

// Aggregate balance
const balances = await client.getAllBalances({ owner: '<YOUR_ADDRESS>' });
const dl = balances.find((b) => b.coinType === COIN_TYPE);
console.log('DL balance (units):', dl?.totalBalance);

// List coin objects
const coins = await client.getCoins({ owner: '<YOUR_ADDRESS>', coinType: COIN_TYPE });
const totalUnits = coins.data.reduce((sum, c) => sum + Number(c.balance), 0);
console.log('Total DL (units):', totalUnits);

// Display with decimals = 9
const formatUnits = (amount: number | string, decimals = 9) => Number(amount) / 10 ** decimals;
console.log('DL readable:', formatUnits(totalUnits));
```

## 5. Hackathon Tips
Starter app ideas:
- Faucet dApp
  - Button: “Mint DL” (admin-only or via a gated backend)
  - Auto-refresh and show balances; recent transaction digest list
- Mini Wallet
  - Connect wallet, show DL balance and coin objects
  - Transfer form: recipient address + amount (convert using 9 decimals)
- Mini Explorer
  - Show CoinMetadata, per-wallet totals, and simple transaction history including DL
- QR / NFC Demo
  - Generate a QR with recipient + amount; scan to prefill a transfer form

UI suggestions:
- Buttons: Connect Wallet, Mint DL, Refresh Balance, Send
- Forms: Recipient (address), Amount (float — convert internally to units)
- Lists: Coin objects (objectId, balance), recent tx digests

Best practices:
- Protect `TreasuryCap`: keep it in admin wallet or a controlled module; do not expose on the client
- Always convert using decimals (9) when displaying/parsing amounts
- Handle errors gracefully: wallet not connected, missing TreasuryCap, RPC failures
- For other teams/users: self-deploy your own package to obtain your own `TreasuryCap<DL>` so you can mint independently.
