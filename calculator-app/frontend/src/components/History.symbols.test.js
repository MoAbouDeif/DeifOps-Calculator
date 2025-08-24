import { render, screen, waitFor, within } from '@testing-library/react';
import History from './History';
import * as api from '../services/api';

jest.mock('../services/api');

describe('History operation symbols (extra branch coverage)', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('renders multiply and divide symbols correctly', async () => {
    const mockData = [
      { created_at: '2023-08-08T15:10:00Z', operand1: 2, operand2: 4, operation: 'multiply', result: 8 },
      { created_at: '2023-08-08T15:15:00Z', operand1: 9, operand2: 3, operation: 'divide', result: 3 },
    ];

    jest.spyOn(api, 'getHistory').mockResolvedValueOnce({ history: mockData });

    render(<History />);

    const section = await screen.findByTestId('history-section');

    await waitFor(() => {
      const items = within(section).queryAllByTestId('history-item');
      expect(items.length).toBe(2);
    });

    const items = within(section).queryAllByTestId('history-item');
    expect(within(items[0]).getByText(/2\s*×\s*4/)).toBeInTheDocument();
    expect(within(items[1]).getByText(/9\s*÷\s*3/)).toBeInTheDocument();

    expect(api.getHistory).toHaveBeenCalledTimes(1);
  });
});
