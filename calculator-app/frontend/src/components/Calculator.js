import React, { useState } from 'react';
import { calculate } from '../services/api';

const getOperationIcon = (operation) => {
  switch(operation) {
    case 'add': return 'plus';
    case 'subtract': return 'minus';
    case 'multiply': return 'times';
    case 'divide': return 'divide';
    default: return 'question';
  }
};

const Calculator = () => {
  const [a, setA] = useState('');
  const [b, setB] = useState('');
  const [operation, setOperation] = useState('add');
  const [error, setError] = useState('');
  const [result, setResult] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [inputErrors, setInputErrors] = useState({ a: false, b: false });

  const handleOperationChange = (op) => {
    setOperation(op);
  };

  const validateInputs = () => {
    let valid = true;
    const newErrors = { a: false, b: false };
    
    if (!a.trim()) {
      newErrors.a = true;
      valid = false;
    } else {
      const numA = parseFloat(a);
      if (isNaN(numA)) {
        newErrors.a = true;
        valid = false;
      }
    }
    
    if (!b.trim()) {
      newErrors.b = true;
      valid = false;
    } else {
      const numB = parseFloat(b);
      if (isNaN(numB)) {
        newErrors.b = true;
        valid = false;
      }
    }
    
    setInputErrors(newErrors);
    return valid;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!validateInputs()) {
      setError('Please enter valid numbers in both fields');
      return;
    }
    
    setIsLoading(true);
    setError('');
    setResult('');
    
    try {
      const numA = parseFloat(a);
      const numB = parseFloat(b);
      
      const data = await calculate(numA, numB, operation);
      setResult(data.result);
      
    } catch (err) {
      setError(err.message || 'An unexpected error occurred');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="card">
      <div className="input-group">
        <label htmlFor="a"><i className="fas fa-number"></i> First Number</label>
        <input 
          id="a" 
          type="number" 
          placeholder="Enter first number" 
          value={a}
          onChange={(e) => setA(e.target.value)}
          data-testid="first-number-input"
          className={inputErrors.a ? 'input-error' : ''}
          min="-1e100"
          max="1e100"
          step="any"
        />
        {inputErrors.a && (
          <div className="input-error-message">Please enter a valid number</div>
        )}
      </div>

      <div className="operation-selector">
        <label htmlFor="operation"><i className="fas fa-calculator"></i> Operation</label>
        <div className="operation-buttons">
          {['add', 'subtract', 'multiply', 'divide'].map(op => (
            <button
              key={op}
              type="button"
              className={`op-btn ${operation === op ? 'active' : ''}`}
              onClick={() => handleOperationChange(op)}
              aria-label={op}
              data-testid={`${op}-button`}
              tabIndex={0}
              onKeyDown={(e) => e.key === 'Enter' && handleOperationChange(op)}
            >
              <i 
                className={`fas fa-${getOperationIcon(op)}`} 
                aria-hidden="true"
                title={op.charAt(0).toUpperCase() + op.slice(1)}
              ></i>
            </button>
          ))}
        </div>
        <select 
          id="operation"
          value={operation}
          onChange={(e) => setOperation(e.target.value)}
          data-testid="operation-select"
          aria-label="Select operation"
        >
          <option value="add">Addition (+)</option>
          <option value="subtract">Subtraction (−)</option>
          <option value="multiply">Multiplication (×)</option>
          <option value="divide">Division (÷)</option>
        </select>
      </div>

      <div className="input-group">
        <label htmlFor="b"><i className="fas fa-number"></i> Second Number</label>
        <input 
          id="b" 
          type="number" 
          placeholder="Enter second number" 
          value={b}
          onChange={(e) => setB(e.target.value)}
          data-testid="second-number-input"
          className={inputErrors.b ? 'input-error' : ''}
          min="-1e100"
          max="1e100"
          step="any"
        />
        {inputErrors.b && (
          <div className="input-error-message">Please enter a valid number</div>
        )}
      </div>

      <button 
        className="calculate-btn"
        onClick={handleSubmit}
        disabled={isLoading}
        data-testid="calculate-button"
        aria-busy={isLoading}
      >
        <span className="btn-text">Calculate</span>
        {isLoading && (
          <div className="spinner" data-testid="spinner">
            <div className="bounce1"></div>
            <div className="bounce2"></div>
            <div className="bounce3"></div>
          </div>
        )}
      </button>

      {result && (
        <div className="result success" data-testid="result-success">
          Result: {result}
        </div>
      )}
      
      {error && (
        <div className="result error" data-testid="result-error">
          Error: {error}
        </div>
      )}
    </div>
  );
};

export default Calculator;