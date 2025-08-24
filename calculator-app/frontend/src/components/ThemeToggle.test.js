// src/components/ThemeToggle.test.js
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import ThemeToggle from './ThemeToggle';

describe('ThemeToggle Component', () => {
  afterEach(() => {
    // reset DOM and storage so tests don't leak state
    localStorage.clear();
    document.body.className = '';
  });

  test('applies dark theme from localStorage on mount', async () => {
    localStorage.setItem('theme', 'dark');
    render(<ThemeToggle />);

    // wait for useEffect to apply the class
    await waitFor(() => expect(document.body).toHaveClass('dark-theme'));
  });

  test('toggles theme via click', async () => {
    render(<ThemeToggle />);
    const toggle = screen.getByTestId('theme-switch');

    // default should be unchecked/off
    expect(toggle).not.toBeChecked();

    // click to toggle on
    fireEvent.click(toggle);
    await waitFor(() => expect(document.body).toHaveClass('dark-theme'));

    // click again to toggle off
    fireEvent.click(toggle);
    await waitFor(() => expect(document.body).not.toHaveClass('dark-theme'));
  });
});
