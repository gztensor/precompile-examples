import { sendTransaction } from "./util/comm";
import { createApi } from "./setup";
const { Keyring } = require('@polkadot/api');

// Replace this with validator coldkeys seed phrases
const registratorColdkeySeed = "//Bob";
const registratorHotkeyPub = "5DAAnrj7VHTznn2AWBemMuyBwZWs6FNFjdyVXUeYum3PTXFy"; // Dave
const developerColdkeySeed = "//Charlie";
const developerHotkeyPub = "5HGjWAeFDfFCWPsjFQdVV2Msvz2XtMktvgocEZcCj68kUMaw"; // Eve
const netuid = 2;

/////////////////////////////////////////////////////////

async function registerNeuron(api: any, coldkeySeed: any, hotkeyPub: any) {
  // Coldkey
  const keyring = new Keyring({ type: 'sr25519' });
  const coldkey = keyring.addFromUri(coldkeySeed);

  // Register as a validator
  console.log(`Registering a neuron. Coldkey: ${coldkey.address}, hotkey: ${hotkeyPub}`);
  const txRegister = api.tx.subtensorModule.burnedRegister(
    netuid, hotkeyPub
  );
  await sendTransaction(api, txRegister, coldkey);
}

async function main() {
  const api = await createApi();

  await registerNeuron(api, registratorColdkeySeed, registratorHotkeyPub);
  await registerNeuron(api, developerColdkeySeed, developerHotkeyPub);
}

main().catch(console.error).finally(() => process.exit());