export function getLogger(prefix) {
  const path = [].concat(prefix).map(name => `[${name}]`).join('');
  return {
    info: (...args) => console.log(`[Logger][${path}][info]`, ...args),
    debug: (...args) => console.log(`[Logger][${path}][debug]`, ...args)
  }
}
