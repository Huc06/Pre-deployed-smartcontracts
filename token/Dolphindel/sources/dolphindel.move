
/// Module: my_coin
module 0x0::DL;

use sui::coin::{TreasuryCap};
use sui::coin;
use sui::tx_context;
use sui::transfer;
use sui::url::{Self, Url};
use std::option::{Self, Option};

// one time witness
public struct DL has drop {}

fun init (witness: DL, ctx: &mut TxContext) {

    let (treasury_cap, coin_metadata) = coin::create_currency(
        witness,
        9,
        b"DL",
        b"Dolphinder",
        b"Sui Dolphinder: Study Jam",
        option::none(),
        ctx
    );

    transfer::public_freeze_object(coin_metadata);
    transfer::public_transfer(treasury_cap, ctx.sender());

}

entry fun mint_token (treasury_cap: &mut TreasuryCap<DL>, ctx: &mut TxContext) {
    let coin_obj = coin::mint(treasury_cap, 1000000000000000, ctx);
    transfer::public_transfer(coin_obj, ctx.sender());
}


