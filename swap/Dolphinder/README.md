# Dolphinder Swap Example — README (English)

## 1) Overview
- This Move module demonstrates an object-for-object swap coordinated by a third party (a custodian/service).
- It uses object wrapping to safely hand temporary ownership of objects to the service without granting the ability to modify them.
- The module is designed as a library/example for learning and tests; it does not expose entry functions directly callable from wallets.

## 2) Contract Address
- Package ID (from your publish):
```
0xf43a7077539c1668d138be3682eb8e0e4bdc7eb229f0bda0f1adba4c4518949e
```
- Module: `example`

## 3) Data Structures and Constants
- Structs:
  - `Object { id: UID, scarcity: u8, style: u8 }`
  - `SwapRequest { id: UID, owner: address, object: Object, fee: Balance<SUI> }`
- Errors:
  - `EFeeTooLow = 0`
  - `EBadSwap = 1`
- Constants:
  - `MIN_FEE: u64 = 1000`

## 4) Functions (library — not entrypoints)
- `public fun new(scarcity: u8, style: u8, ctx: &mut TxContext): Object`
  - Create a new `Object` with given attributes.
- `public fun request_swap(object: Object, fee: Coin<SUI>, service: address, ctx: &mut TxContext)`
  - Assert the fee >= `MIN_FEE`; wrap the object and send a `SwapRequest` to the `service` address.
- `public fun execute_swap(s1: SwapRequest, s2: SwapRequest): Balance<SUI>`
  - Ensure `scarcity` matches and `style` differs, then swap objects between owners, delete wrappers, and return the combined fee as `Balance<SUI>` (service keeps the fee).

> Important: These are not `entry` functions. They are intended to be used from another module (your app’s service) that provides entry wrappers. Wallets/CLI can only call `entry fun`.

## 5) How to Use (recommended pattern)
Create a small service module in your package that wraps the library functions with `entry` functions:

```move
module <YOUR_ADDR_OR_PACKAGE>::swap_service {
    use 0x0::example; // replace with the on-chain address of the example module
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    /// Entry to create an Object
    public entry fun create_object(scarcity: u8, style: u8, ctx: &mut TxContext) {
        let _o = example::new(scarcity, style, ctx);
        // In a real app, you likely transfer to sender or store somewhere
        transfer::public_transfer(_o, tx_context::sender(ctx));
    }

    /// Entry to send a swap request to a service
    public entry fun make_swap_request(
        object: example::Object,
        fee: Coin<SUI>,
        service: address,
        ctx: &mut TxContext,
    ) {
        example::request_swap(object, fee, service, ctx)
    }

    /// Entry to execute a swap (called by the service)
    public entry fun do_execute_swap(s1: example::SwapRequest, s2: example::SwapRequest, ctx: &mut TxContext) {
        let fee_bal = example::execute_swap(s1, s2);
        let fee_coin = coin::from_balance(fee_bal, ctx);
        transfer::public_transfer(fee_coin, tx_context::sender(ctx));
    }
}
```

Then you can call these `entry` wrappers from the frontend or CLI.

## 6) Frontend usage (TypeScript SDK — via wrappers)
Assuming you deployed a `swap_service` with the three entries above.

```ts
import { Transaction } from '@mysten/sui/transactions';

const PACKAGE_ID = '<YOUR_SERVICE_PACKAGE_ID>';
const MODULE = 'swap_service';

// 1) Create an object
const createObjectTx = (scarcity: number, style: number) => {
  const tx = new Transaction();
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::create_object`,
    arguments: [tx.pure.u8(scarcity), tx.pure.u8(style)],
  });
  return tx;
};

// 2) Request swap: pass your Object and a SUI fee coin, plus service address
const requestSwapTx = (objectId: string, feeCoinId: string, serviceAddr: string) => {
  const tx = new Transaction();
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::make_swap_request`,
    arguments: [tx.object(objectId), tx.object(feeCoinId), tx.pure.address(serviceAddr)],
  });
  return tx;
};

// 3) Execute swap: service bundles two SwapRequests it owns
const executeSwapTx = (s1Id: string, s2Id: string) => {
  const tx = new Transaction();
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::do_execute_swap`,
    arguments: [tx.object(s1Id), tx.object(s2Id)],
  });
  return tx;
};
```

## 7) CLI (via wrappers)
```bash
# Create object
sui client call \
  --package <YOUR_SERVICE_PACKAGE_ID> \
  --module swap_service --function create_object \
  --args 1 0 \
  --gas-budget 10000000

# Make swap request (needs your Object ID, a SUI coin as fee, service address)
sui client call \
  --package <YOUR_SERVICE_PACKAGE_ID> \
  --module swap_service --function make_swap_request \
  --args <OBJECT_ID> <FEE_COIN_ID> <SERVICE_ADDRESS> \
  --gas-budget 10000000

# Execute swap (service)
sui client call \
  --package <YOUR_SERVICE_PACKAGE_ID> \
  --module swap_service --function do_execute_swap \
  --args <SWAP_REQUEST_1_ID> <SWAP_REQUEST_2_ID> \
  --gas-budget 10000000
```

## 8) Hackathon Tips
- Roles: Alice and Bob submit swap requests; Custodian holds received `SwapRequest` objects and calls execution.
- UI ideas:
  - Mint “Object” with scarcity/style; list your Objects.
  - Submit a swap request (select one Object + pay fee + custodian address).
  - Custodian dashboard: queue of pending `SwapRequest`, “Match & Execute” button to pair two compatible requests.
- Safety: validate inputs; only custodian should be able to execute swaps; handle fees carefully.
