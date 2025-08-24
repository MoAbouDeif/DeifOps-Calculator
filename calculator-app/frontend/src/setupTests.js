/**
 * src/setupTests.js
 * This file is automatically loaded by Create React App.
 * Put global test setup here.
 */

// jest-dom provides custom matchers like .toBeInTheDocument()
import '@testing-library/jest-dom';

// Optional: mock matchMedia if your components use it (common in theme toggles)
if (typeof window !== 'undefined' && !window.matchMedia) {
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: (query) => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: () => {}, // deprecated API
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => false,
    }),
  });
}

// Optional: reset or mock localStorage for deterministic tests
beforeEach(() => {
  try {
    localStorage.clear();
  } catch (e) {
    // JSDOM provides localStorage but be defensive
  }
});
