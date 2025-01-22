import { sendTransaction } from "./util/comm";
import { createApi } from "./setup";
import { Keyring } from "@polkadot/api";

/////////////////////////////////////////////////////////

async function main() {
  const api = await createApi();

  // Alice and Bob
  const keyring = new Keyring({ type: 'sr25519' });
  const alice = keyring.addFromUri("//Alice");

  // Alice registers herself as hotkey on subnet 1
  const txRegister = api.tx.subtensorModule.burnedRegister(
    1, alice.address
  );
  await sendTransaction(api, txRegister, alice);

  // Disable whitelist
  const txDisableWhitelist = api.tx.sudo.sudo(
    api.tx.evm.disableWhitelist(true)
  );
  await sendTransaction(api, txDisableWhitelist, alice);

  // Set chain ID
  const txChainId = api.tx.sudo.sudo(
    api.tx.adminUtils.sudoSetEvmChainId(945)
  );
  await sendTransaction(api, txChainId, alice);
}

main().catch(console.error).finally(() => process.exit());
