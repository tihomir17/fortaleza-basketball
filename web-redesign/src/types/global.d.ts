declare global {
  var global: typeof globalThis;
  
  namespace NodeJS {
    interface Timeout {
      ref(): this;
      unref(): this;
    }
  }
}

export {};
