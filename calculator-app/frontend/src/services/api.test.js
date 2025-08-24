import { calculate, getHistory, handleResponse } from './api';

global.fetch = jest.fn();

describe('API Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // --------------------------
  // handleResponse unit tests
  // --------------------------
  test('handleResponse throws error for HTML content', async () => {
    const response = {
      headers: { get: () => 'text/html' },
      text: () => Promise.resolve('<html>Error</html>'),
      ok: false,
    };

    await expect(handleResponse(response)).rejects.toThrow(/Server returned HTML/);
  });

  test('handleResponse returns JSON when ok', async () => {
    const mockData = { result: 42 };
    const response = {
      headers: { get: () => 'application/json' },
      json: () => Promise.resolve(mockData),
      ok: true,
    };

    const result = await handleResponse(response);
    expect(result).toEqual(mockData);
  });

  test('handleResponse throws JSON error when !ok', async () => {
    const response = {
      headers: { get: () => 'application/json' },
      json: () => Promise.resolve({ error: 'Bad request' }),
      ok: false,
    };

    await expect(handleResponse(response)).rejects.toThrow('Bad request');
  });

  test('handleResponse returns plain text when ok', async () => {
    const response = {
      headers: { get: () => 'text/plain' },
      text: () => Promise.resolve('Plain OK'),
      ok: true,
    };

    const result = await handleResponse(response);
    expect(result).toBe('Plain OK');
  });

  test('handleResponse throws plain text error when !ok', async () => {
    const response = {
      headers: { get: () => 'text/plain' },
      text: () => Promise.resolve('Something failed'),
      ok: false,
      status: 400,
    };

    await expect(handleResponse(response)).rejects.toThrow('Something failed');
  });

  // --------------------------
  // calculate tests
  // --------------------------
  test('calculate sends correct request and handles success', async () => {
    const mockResponse = { result: 8 };
    fetch.mockResolvedValueOnce({
      ok: true,
      headers: { get: () => 'application/json' },
      json: () => Promise.resolve(mockResponse),
    });

    const result = await calculate(5, 3, 'add');
    expect(result).toEqual(mockResponse);
    expect(fetch).toHaveBeenCalledWith(
      expect.stringContaining('/calculate'),
      expect.objectContaining({
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: JSON.stringify({ a: 5, b: 3, operation: 'add' }),
      })
    );
  });

  test('calculate handles error response', async () => {
    fetch.mockResolvedValueOnce({
      ok: false,
      headers: { get: () => 'application/json' },
      json: () => Promise.resolve({ error: 'Division by zero' }),
    });

    await expect(calculate(5, 0, 'divide')).rejects.toThrow('Division by zero');
  });

  test('calculate handles network failure', async () => {
    fetch.mockRejectedValueOnce(new Error('Network down'));

    await expect(calculate(1, 2, 'add')).rejects.toThrow('Network down');
  });

  // --------------------------
  // getHistory tests
  // --------------------------
  test('getHistory fetches history successfully', async () => {
    const mockHistory = [{ id: 1, operation: 'add', result: 8 }];
    fetch.mockResolvedValueOnce({
      ok: true,
      headers: { get: () => 'application/json' },
      json: () => Promise.resolve({ history: mockHistory }),
    });

    const history = await getHistory();
    expect(history).toEqual({ history: mockHistory });
    expect(fetch).toHaveBeenCalledWith(
      expect.stringContaining('/history'),
      expect.objectContaining({
        method: 'GET',
        headers: { 'Accept': 'application/json' },
      })
    );
  });

  test('getHistory handles fetch failure', async () => {
    fetch.mockRejectedValueOnce(new Error('Network error'));
    await expect(getHistory()).rejects.toThrow('Network error');
  });

  test('getHistory handles text error response', async () => {
    fetch.mockResolvedValueOnce({
      ok: false,
      headers: { get: () => 'text/plain' },
      text: () => Promise.resolve('History failed'),
      status: 500,
    });

    await expect(getHistory()).rejects.toThrow('History failed');
  });
});
