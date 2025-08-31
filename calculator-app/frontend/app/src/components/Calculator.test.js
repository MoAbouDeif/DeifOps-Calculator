import { render, screen, fireEvent } from '@testing-library/react';
import Calculator from './Calculator';
import * as api from '../services/api';

jest.mock('../services/api');

test('validates inputs before submission', async () => {
  render(<Calculator />);

  fireEvent.click(screen.getByTestId('calculate-button'));

  // first input should show error class
  expect(await screen.findByTestId('first-number-input')).toHaveClass('input-error');

  // there may be multiple identical error messages; assert at least one exists
  const msgs = await screen.findAllByText('Please enter a valid number');
  expect(msgs.length).toBeGreaterThanOrEqual(1);

  // API should not be called
  expect(api.calculate).not.toHaveBeenCalled();
});
