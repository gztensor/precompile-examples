import { sendTransaction } from "./util/comm";
import { createApi } from "./setup";
import {
  convertTaoToRao,
} from "./util/balance-math";
import { convertH160ToSS58 } from "./util/address";
import { ethers } from "hardhat";
import { Keyring } from "@polkadot/api";

const amount1TAO = convertTaoToRao(1.0);

/////////////////////////////////////////////////////////

async function main() {
  const api = await createApi();

  // Alice
  const keyring = new Keyring({ type: 'sr25519' });
  const alice = keyring.addFromUri("//Alice");

  // Alice funds herself with 1M TAO
  const txSudoSetBalance = api.tx.sudo.sudo(
    api.tx.balances.forceSetBalance(
      alice.address,
      amount1TAO.multipliedBy(1e6).toString()
    )
  );
  await sendTransaction(api, txSudoSetBalance, alice);

  // Alice funds test accounts
  const addresses = await ethers.getSigners();
  for (let i=0; i<addresses.length; i++) {
    const ss58mirror = convertH160ToSS58(addresses[i].address);
    const transfer = api.tx.balances.transferKeepAlive(
      ss58mirror,
      amount1TAO.multipliedBy(1000).toString()
    );
    await sendTransaction(api, transfer, alice);
  }
}

main().catch(console.error).finally(() => process.exit());