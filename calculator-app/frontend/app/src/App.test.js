// src/App.test.js
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders main parts (calculator + history)', () => {
  render(<App />);

  // Calculator present
  expect(screen.getByTestId('first-number-input')).toBeInTheDocument();

  // History may be loading or present — accept either
  const historySection = screen.queryByTestId('history-section');
  const historyLoading = screen.queryByTestId('history-loading');
  expect(historySection || historyLoading).toBeTruthy();

  // Footer and links
  expect(screen.getByText(/© 2023 Simple Calculator | Made by MoAboDaif/)).toBeInTheDocument();
  expect(screen.getByLabelText('Help')).toBeInTheDocument();
  expect(screen.getByLabelText('Settings')).toBeInTheDocument();
  expect(screen.getByLabelText('GitHub Repository')).toBeInTheDocument();
});
