const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || '/api';

export const handleResponse = async (response) => {
  const contentType = response.headers.get('content-type');

  // Handle HTML responses (errors)
  if (contentType && contentType.includes('text/html')) {
    const text = await response.text();
    throw new Error(`Server returned HTML: ${text.slice(0, 100)}...`);
  }

  // Handle JSON responses
  if (contentType && contentType.includes('application/json')) {
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.error || 'Request failed');
    }
    return data;
  }

  // Handle other response types (plain text, etc.)
  const text = await response.text();
  if (!response.ok) {
    throw new Error(text || `Request failed with status ${response.status}`);
  }
  return text;
};

export const calculate = async (a, b, operation) => {
  try {
    const response = await fetch(`${API_BASE_URL}/calculate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({ a, b, operation }),
    });

    return await handleResponse(response);
  } catch (error) {
    throw new Error(error.message || 'Network error');
  }
};

export const getHistory = async () => {
  try {
    const response = await fetch(`${API_BASE_URL}/history`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    return await handleResponse(response);
  } catch (error) {
    throw new Error(error.message || 'Failed to fetch history');
  }
};
