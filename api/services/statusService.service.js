let isFree = true;
let lastHash = 'none';

export default {
  setBusy: () => {
    isFree = false;
  },
  setFree: (hash) => {
    lastHash = lastHash === 'none' ? hash : lastHash;
    isFree = true;
  },
  getIsFree: () => {
    return isFree;
  },
  getLastHash: () => {
    return lastHash;
  }
}
