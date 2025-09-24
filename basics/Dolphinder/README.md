# Basics — Dolphinder (Sui Move) README

This package contains simple example modules to learn core Sui Move concepts. It includes:
- `clock`
- `counter`
- `object_basics`
- `random`
- `resolve_args`

Package path:
```
Pre-deployed-smartcontracts/basics/Dolphinder
```

## Contract Address
- Package ID:
```
0x31df01c67a80c80895d9d77eb4c264fc316efa23954fdd353e502b4f2f036989
```

## 1) clock
Purpose: Read and use on-chain time.

Typical functions (pattern):
- `entry fun demo_now(ctx)` or views that read Clock.

CLI (example):
```bash
sui client call \
  --package 0x31df01c67a80c80895d9d77eb4c264fc316efa23954fdd353e502b4f2f036989 \
  --module clock --function demo_now \
  --gas-budget 10000000
```

TypeScript:
```ts
import { Transaction } from '@mysten/sui/transactions';
const PACKAGE_ID = '0x31df01c67a80c80895d9d77eb4c264fc316efa23954fdd353e502b4f2f036989';
const tx = new Transaction();
tx.moveCall({ target: `${PACKAGE_ID}::clock::demo_now` });
```

## 2) counter
Purpose: Mutable object with increment/decrement.

Common entries:
- `create(ctx)` -> returns/transfers a `Counter` object
- `inc(counter: &mut Counter, ctx)`
- `dec(counter: &mut Counter, ctx)`

CLI:
```bash
# create
sui client call --package 0x31df01c67a80c80895d9d77eb4c264fc316efa23954fdd353e502b4f2f036989 --module counter --function create --gas-budget 10000000
# inc
sui client call --package 0x31df01c67a80c80895d9d77eb4c264fc316efa23954fdd353e502b4f2f036989 --module counter --function inc --args <COUNTER_ID> --gas-budget 10000000
# dec
sui client call --package 0x31df01c67a80c80895d9d77eb4c264fc316efa23954fdd353e502b4f2f036989 --module counter --function dec --args <COUNTER_ID> --gas-budget 10000000
```

TypeScript:
```ts
const PACKAGE_ID = '0x31df01c67a80c80895d9d77eb4c264fc316efa23954fdd353e502b4f2f036989';
const createCounterTx = () => {
  const tx = new Transaction();
  tx.moveCall({ target: `${PACKAGE_ID}::counter::create` });
  return tx;
};

const incCounterTx = (counterId: string) => {
  const tx = new Transaction();
  tx.moveCall({ target: `${PACKAGE_ID}::counter::inc`, arguments: [tx.object(counterId)] });
  return tx;
};
```

## 3) object_basics
Purpose: Create/transfer/share simple objects.

Common entries:
- `create(ctx)` -> new Object
- `transfer(obj: Object, recipient: address, ctx)`
- `share(obj: Object, ctx)` (if included)

CLI:
```bash
sui client call --package 0x31df01c67a80c80895d9d77eb4c264fc316efa23954fdd353e502b4f2f036989 --module object_basics --function create --gas-budget 10000000
sui client call --package 0x31df01c67a80c80895d9d77eb4c264fc316efa23954fdd353e502b4f2f036989 --module object_basics --function transfer --args <OBJ_ID> <RECIPIENT> --gas-budget 10000000
```

## 4) random
Purpose: Demonstrate randomness interface.

Common entry:
- `draw(ctx)` emits/uses randomness.

CLI:
```bash
sui client call --package 0x31df01c67a80c80895d9d77eb4c264fc316efa23954fdd353e502b4f2f036989 --module random --function draw --gas-budget 10000000
```

TypeScript:
```ts
const PACKAGE_ID = '0x31df01c67a80c80895d9d77eb4c264fc316efa23954fdd353e502b4f2f036989';
const drawRandomTx = () => {
  const tx = new Transaction();
  tx.moveCall({ target: `${PACKAGE_ID}::random::draw` });
  return tx;
};
```

## 5) resolve_args
Purpose: Show how to pass and resolve arguments in Move.

Common entries:
- `demo_u64(x: u64, ctx)`
- `demo_obj(obj: SomeObj, ctx)`

CLI:
```bash
sui client call --package 0x31df01c67a80c80895d9d77eb4c264fc316efa23954fdd353e502b4f2f036989 --module resolve_args --function demo_u64 --args 42 --gas-budget 10000000
```

## Tips
- Use `sui client publish` to deploy and capture the `PackageID` for this basics package.
- Use `getOwnedObjects` to discover object IDs (for `counter`, `object_basics`).
- In TS, serialize scalars with `tx.pure.u64(...)`, `tx.pure.string(...)`, `tx.pure.address(...)` and objects with `tx.object(<ID>)`.
- If a function name differs in your sources, adapt the examples accordingly (patterns above follow common Sui samples).
