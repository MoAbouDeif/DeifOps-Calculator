import React, { useEffect } from 'react';

const ThemeToggle = () => {
  useEffect(() => {
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'dark') {
      document.body.classList.add('dark-theme');
    }
  }, []);

  const toggleTheme = () => {
    document.body.classList.toggle('dark-theme');
    localStorage.setItem('theme', 
      document.body.classList.contains('dark-theme') ? 'dark' : 'light'
    );
  };

  return (
    <div className="theme-toggle" data-testid="theme-toggle">
      <i className="fas fa-sun"></i>
      <label className="switch">
        <input 
          type="checkbox" 
          onChange={toggleTheme} 
          data-testid="theme-switch"
          aria-label="Toggle dark mode"
        />
        <span className="slider round"></span>
      </label>
      <i className="fas fa-moon"></i>
    </div>
  );
};

export default ThemeToggle;