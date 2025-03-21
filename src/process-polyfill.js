// Add a process polyfill for the browser
if (typeof window !== 'undefined' && !window.process) {
  window.process = {
    env: {}
  };
}