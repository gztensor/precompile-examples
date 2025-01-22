import { WsProvider, ApiPromise } from "@polkadot/api";
import { WS_ENDPOINT, CONN_TIMEOUT } from '../config';

function withTimeout(promise: Promise<ApiPromise>, timeoutMs: number | undefined) {
  // Create a promise that rejects in <timeoutMs> milliseconds
  let timeoutHandle: string | number | NodeJS.Timeout | undefined;
  const timeoutPromise = new Promise((resolve, reject) => {
      timeoutHandle = setTimeout(() => reject(new Error('Promise timed out')), timeoutMs);
  });

  // Returns a race between our timeout and the passed in promise
  return Promise.race([promise, timeoutPromise]).then(result => {
      clearTimeout(timeoutHandle);
      return result;
  }).catch(error => {
      clearTimeout(timeoutHandle);
      throw error;
  });
}

export async function createApi() {
  const wsProvider = new WsProvider(WS_ENDPOINT);
  let api = new ApiPromise({ provider: wsProvider });
  try {
    await withTimeout(api.isReady, CONN_TIMEOUT);
  } catch (error) {
    api.disconnect();
    throw Error('Connection timeout')
  }
  return api;
}

export function closeApi(api: ApiPromise) {
  api && api.disconnect();
}
