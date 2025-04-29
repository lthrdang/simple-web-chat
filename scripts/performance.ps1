param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$ApiUrl,
    
    [Parameter(Mandatory=$false)]
    [int]$ConcurrentUsers = 100,
    
    [Parameter(Mandatory=$false)]
    [int]$Duration = 300,
    
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = "./performance-reports"
)

# Validate environment
if ($Environment -notin @("dev", "staging", "prod")) {
    Write-Host "Invalid environment. Must be one of: dev, staging, prod"
    exit 1
}

# Check if k6 is installed
$k6Status = k6 version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "k6 is not installed. Please install it and try again."
    exit 1
}

# Create report directory if it doesn't exist
if (-not (Test-Path $ReportPath)) {
    New-Item -ItemType Directory -Path $ReportPath
    Write-Host "Created report directory: $ReportPath"
}

# Create k6 test script
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$testScript = "$ReportPath/load-test-$Environment-$timestamp.js"

@"
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const messageLatency = new Trend('message_latency');

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: $ConcurrentUsers }, // Ramp-up
    { duration: '${Duration}s', target: $ConcurrentUsers }, // Stay at peak
    { duration: '30s', target: 0 }, // Ramp-down
  ],
  thresholds: {
    'errors': ['rate<0.1'], // Error rate should be less than 10%
    'message_latency': ['p(95)<500'], // 95% of messages should be delivered within 500ms
  },
};

// Test data
const testUser = {
  email: 'test@example.com',
  password: 'test123',
};

// Test scenarios
export default function() {
  // Login
  const loginRes = http.post('$ApiUrl/api/auth/login', JSON.stringify(testUser), {
    headers: { 'Content-Type': 'application/json' },
  });
  
  check(loginRes, {
    'login successful': (r) => r.status === 200,
  });
  
  errorRate.add(loginRes.status !== 200);
  
  if (loginRes.status === 200) {
    const token = loginRes.json('token');
    
    // Send message
    const startTime = new Date();
    const messageRes = http.post(
      '$ApiUrl/api/chats/messages',
      JSON.stringify({
        content: 'Test message',
        chatId: 'test-chat-id',
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
      }
    );
    
    const endTime = new Date();
    messageLatency.add(endTime - startTime);
    
    check(messageRes, {
      'message sent': (r) => r.status === 201,
    });
    
    errorRate.add(messageRes.status !== 201);
  }
  
  sleep(1);
}
"@ | Out-File -FilePath $testScript -Encoding UTF8

# Run performance test
Write-Host "Running performance test..."
k6 run $testScript

# Generate HTML report
$htmlReport = "$ReportPath/performance-report-$Environment-$timestamp.html"

@"
<!DOCTYPE html>
<html>
<head>
    <title>Performance Test Report - $Environment</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .metric { margin: 10px 0; padding: 10px; background: #f5f5f5; }
        .threshold { color: red; }
    </style>
</head>
<body>
    <h1>Performance Test Report</h1>
    <p>Environment: $Environment</p>
    <p>Date: $(Get-Date)</p>
    <p>Concurrent Users: $ConcurrentUsers</p>
    <p>Duration: $Duration seconds</p>
    
    <h2>Test Results</h2>
    <div class="metric">
        <h3>Error Rate</h3>
        <p>Threshold: < 10%</p>
        <p>Actual: <span id="errorRate">Loading...</span></p>
    </div>
    
    <div class="metric">
        <h3>Message Latency</h3>
        <p>Threshold: 95th percentile < 500ms</p>
        <p>Actual: <span id="messageLatency">Loading...</span></p>
    </div>
    
    <h2>Recommendations</h2>
    <ul>
        <li>Monitor error rates and investigate any spikes</li>
        <li>Optimize database queries if latency is high</li>
        <li>Consider horizontal scaling if CPU usage is high</li>
        <li>Implement caching for frequently accessed data</li>
    </ul>
</body>
</html>
"@ | Out-File -FilePath $htmlReport -Encoding UTF8

Write-Host "`nPerformance test completed!"
Write-Host "Test script: $testScript"
Write-Host "HTML report: $htmlReport" 