import React, { useEffect, useState } from 'react';
import { getHistory } from '../services/api';

const getOperationSymbol = (operation) => {
  switch (operation) {
    case 'add': return '+';
    case 'subtract': return '−';
    case 'multiply': return '×';
    case 'divide': return '÷';
    default: return '';
  }
};

const formatDate = (dateString) => {
  const options = {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  };
  return new Date(dateString).toLocaleDateString(undefined, options);
};

const History = () => {
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchHistory = async () => {
      try {
        const response = await getHistory();
        setHistory(response.history || []);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchHistory();
  }, []);

  if (loading) {
    return (
      <div className="history-section" data-testid="history-loading">
        <h3><i className="fas fa-history"></i> Calculation History</h3>
        <div className="spinner" data-testid="spinner">
          <div className="bounce1"></div>
          <div className="bounce2"></div>
          <div className="bounce3"></div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="history-section" data-testid="history-error">
        <h3><i className="fas fa-history"></i> Calculation History</h3>
        <div className="result error">Error: {error}</div>
      </div>
    );
  }

  return (
    <div className="history-section" data-testid="history-section">
      <h3><i className="fas fa-history"></i> Calculation History</h3>
      <ul data-testid="history-list">
        {history.length === 0 ? (
          <li data-testid="no-history">No calculation history found</li>
        ) : (
          history.map((item, index) => (
            <li key={index} data-testid="history-item">
              <div className="history-calculation">
                <span>{item.operand1} {getOperationSymbol(item.operation)} {item.operand2}</span>
                <strong>= {item.result}</strong>
              </div>
              <div className="history-timestamp">
                {formatDate(item.created_at)}
              </div>
            </li>
          ))
        )}
      </ul>
    </div>
  );
};

export default History;
