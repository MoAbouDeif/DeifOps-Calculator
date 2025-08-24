// src/components/extra.branch.test.js
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import Calculator from './Calculator';
import History from './History';
import * as api from '../services/api';

jest.mock('../services/api');

describe('Branch coverage extras', () => {
  afterEach(() => {
    jest.restoreAllMocks();
    jest.resetAllMocks();
    document.body.className = '';
  });

  test('Calculator: pressing Enter on an operation button switches operation', () => {
    render(<Calculator />);

    const subtractBtn = screen.getByTestId('subtract-button');
    const opSelect = screen.getByTestId('operation-select');

    expect(subtractBtn).not.toHaveClass('active');

    fireEvent.keyDown(subtractBtn, { key: 'Enter', code: 'Enter' });

    expect(subtractBtn).toHaveClass('active');
    expect(opSelect.value).toBe('subtract');
  });

  test('History: shows error UI when getHistory rejects', async () => {
    const spy = jest.spyOn(api, 'getHistory').mockRejectedValueOnce(new Error('Network failure'));

    render(<History />);

    const errorSection = await screen.findByTestId('history-error');

    expect(errorSection).toBeInTheDocument();
    expect(screen.getByText(/Error: Network failure/)).toBeInTheDocument();
    expect(spy).toHaveBeenCalled();
  });
});
