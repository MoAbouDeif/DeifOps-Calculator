import { render, screen, waitFor, within } from '@testing-library/react';
import History from './History';
import * as api from '../services/api';

describe('History Component', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('displays history data correctly', async () => {
    const mockData = [
      { created_at: '2023-08-08T15:00:00Z', operand1: 5, operand2: 3, operation: 'add', result: 8 },
      { created_at: '2023-08-08T15:05:00Z', operand1: 10, operand2: 4, operation: 'subtract', result: 6 },
    ];

    const spy = jest.spyOn(api, 'getHistory').mockResolvedValueOnce({ history: mockData });

    render(<History />);

    await waitFor(() => expect(spy).toHaveBeenCalled());
    const section = await screen.findByTestId('history-section');

    await waitFor(() => {
      const items = within(section).queryAllByTestId('history-item');
      expect(items.length).toBe(2);
    });

    const items = within(section).queryAllByTestId('history-item');
    expect(within(items[0]).getByText(/5\s*\+\s*3/)).toBeInTheDocument();
    expect(within(items[1]).getByText(/10\s*−\s*4/)).toBeInTheDocument();

    expect(spy).toHaveBeenCalledTimes(1);
  });

  test('shows empty state when no history', async () => {
    const spy = jest.spyOn(api, 'getHistory').mockResolvedValueOnce({ history: [] });

    render(<History />);

    await waitFor(() => expect(spy).toHaveBeenCalled());
    await screen.findByTestId('history-section');

    expect(screen.getByTestId('no-history')).toBeInTheDocument();
    expect(screen.getByText('No calculation history found')).toBeInTheDocument();
  });
});
