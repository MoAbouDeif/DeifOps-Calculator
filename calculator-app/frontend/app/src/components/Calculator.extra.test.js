import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import Calculator from './Calculator';
import * as api from '../services/api';

// Mock the API module
jest.mock('../services/api');

describe('Calculator additional tests', () => {
  afterEach(() => {
    jest.resetAllMocks();
    document.body.className = '';
  });

  test('operation buttons and select reflect the chosen operation', () => {
    render(<Calculator />);

    const addBtn = screen.getByTestId('add-button');
    const multiplyBtn = screen.getByTestId('multiply-button');
    const opSelect = screen.getByTestId('operation-select');

    expect(addBtn).toHaveClass('active');
    expect(opSelect.value).toBe('add');

    fireEvent.click(multiplyBtn);
    expect(multiplyBtn).toHaveClass('active');
    expect(opSelect.value).toBe('multiply');

    fireEvent.change(opSelect, { target: { value: 'divide' } });
    expect(screen.getByTestId('divide-button')).toHaveClass('active');
    expect(opSelect.value).toBe('divide');
  });

  test('validates blank and non-numeric inputs and prevents API call', async () => {
    render(<Calculator />);

    fireEvent.click(screen.getByTestId('calculate-button'));

    // individual awaits instead of multiple inside waitFor
    expect(await screen.findByTestId('first-number-input')).toHaveClass('input-error');
    expect(await screen.findByTestId('second-number-input')).toHaveClass('input-error');
    expect(await screen.findByTestId('result-error'))
      .toHaveTextContent('Please enter valid numbers in both fields');

    expect(api.calculate).not.toHaveBeenCalled();

    fireEvent.change(screen.getByTestId('first-number-input'), { target: { value: 'abc' } });
    fireEvent.change(screen.getByTestId('second-number-input'), { target: { value: '5' } });
    fireEvent.click(screen.getByTestId('calculate-button'));

    expect(await screen.findByTestId('first-number-input')).toHaveClass('input-error');
    expect(api.calculate).not.toHaveBeenCalled();
  });

  test('shows loading spinner and success result after successful API call', async () => {
    api.calculate.mockResolvedValueOnce({ result: 15 });

    render(<Calculator />);

    fireEvent.change(screen.getByTestId('first-number-input'), { target: { value: '3' } });
    fireEvent.change(screen.getByTestId('second-number-input'), { target: { value: '5' } });
    fireEvent.click(screen.getByTestId('multiply-button'));
    fireEvent.click(screen.getByTestId('calculate-button'));

    expect(screen.getByTestId('calculate-button')).toHaveAttribute('aria-busy', 'true');
    expect(screen.getByTestId('spinner')).toBeInTheDocument();

    // split assertions
    expect(api.calculate).toHaveBeenCalledWith(3, 5, 'multiply');
    expect(await screen.findByTestId('result-success')).toBeInTheDocument();
    expect(await screen.findByTestId('result-success')).toHaveTextContent('Result: 15');
    expect(await screen.findByTestId('calculate-button')).toHaveAttribute('aria-busy', 'false');
  });

  test('displays API error when calculate rejects', async () => {
    api.calculate.mockRejectedValueOnce(new Error('Division by zero'));

    render(<Calculator />);

    fireEvent.change(screen.getByTestId('first-number-input'), { target: { value: '10' } });
    fireEvent.change(screen.getByTestId('second-number-input'), { target: { value: '0' } });
    fireEvent.click(screen.getByTestId('divide-button'));
    fireEvent.click(screen.getByTestId('calculate-button'));

    expect(api.calculate).toHaveBeenCalledWith(10, 0, 'divide');
    expect(await screen.findByTestId('result-error')).toBeInTheDocument();
    expect(await screen.findByTestId('result-error'))
      .toHaveTextContent('Error: Division by zero');
    expect(await screen.findByTestId('calculate-button')).toHaveAttribute('aria-busy', 'false');
  });
});
