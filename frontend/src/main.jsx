import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';
import DEBUG_MODE, { debugLog } from './debug';

// Initialize debug mode based on environment
if (import.meta.env.MODE === 'development') {
  // Enable full debugging in development mode
  DEBUG_MODE.enabled = true;
  DEBUG_MODE.logLevel = 'verbose';
  DEBUG_MODE.socketLogs = true;
  DEBUG_MODE.apiLogs = true;
  DEBUG_MODE.renderLogs = true;
  
  debugLog('debug', 'Debug mode enabled in development environment', DEBUG_MODE);
  
  // Add global debug access for browser console debugging
  window.__DEBUG_MODE = DEBUG_MODE;
} else {
  // Disable most debugging in production
  DEBUG_MODE.enabled = false;
  DEBUG_MODE.renderLogs = false;
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
); 