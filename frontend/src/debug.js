// Debug configuration for frontend app
const DEBUG_MODE = {
  enabled: true,
  logLevel: 'verbose', // 'error', 'warn', 'info', 'verbose', 'debug'
  socketLogs: true,
  apiLogs: true,
  renderLogs: false
};

// Debug logger function
export const debugLog = (type, ...args) => {
  if (!DEBUG_MODE.enabled) return;
  
  // Only log if the type's logging is enabled or it's an 'error' (always log errors)
  const shouldLog = 
    type === 'error' || 
    (type === 'socket' && DEBUG_MODE.socketLogs) ||
    (type === 'api' && DEBUG_MODE.apiLogs) ||
    (type === 'render' && DEBUG_MODE.renderLogs);
  
  if (!shouldLog) return;
  
  const timestamp = new Date().toISOString();
  
  switch (type) {
    case 'error':
      console.error(`[DEBUG][${timestamp}][ERROR]`, ...args);
      break;
    case 'socket':
      console.log(`[DEBUG][${timestamp}][SOCKET]`, ...args);
      break;
    case 'api':
      console.log(`[DEBUG][${timestamp}][API]`, ...args);
      break;
    case 'render':
      console.log(`[DEBUG][${timestamp}][RENDER]`, ...args);
      break;
    default:
      console.log(`[DEBUG][${timestamp}]`, ...args);
  }
};

// Expose DEBUG_MODE settings
export const setDebugMode = (settings) => {
  Object.assign(DEBUG_MODE, settings);
};

export const getDebugMode = () => ({...DEBUG_MODE});

export default DEBUG_MODE; 