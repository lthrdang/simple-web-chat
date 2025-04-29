param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$GcpProjectId,
    
    [Parameter(Mandatory=$true)]
    [string]$GcpRegion,
    
    [Parameter(Mandatory=$false)]
    [switch]$Setup,
    
    [Parameter(Mandatory=$false)]
    [switch]$Dashboard,
    
    [Parameter(Mandatory=$false)]
    [switch]$Logs,
    
    [Parameter(Mandatory=$false)]
    [switch]$Alerts
)

# Validate environment
if ($Environment -notin @("dev", "staging", "prod")) {
    Write-Host "Invalid environment. Must be one of: dev, staging, prod"
    exit 1
}

# Check if Google Cloud SDK is installed
$gcloudStatus = gcloud --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Google Cloud SDK is not installed. Please install it and try again."
    exit 1
}

# Check if kubectl is installed
$kubectlStatus = kubectl version --client 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "kubectl is not installed. Please install it and try again."
    exit 1
}

# Set Google Cloud project
gcloud config set project $GcpProjectId

# Get GKE credentials
gcloud container clusters get-credentials "chat-cluster-$Environment" --region $GcpRegion

# Function to set up monitoring
function Setup-Monitoring {
    Write-Host "Setting up monitoring..."
    
    # Create monitoring dashboard
    $dashboardConfig = @{
        displayName = "Chat Application Dashboard"
        gridLayout = @{
            widgets = @(
                @{
                    title = "CPU Usage"
                    xyChart = @{
                        dataSets = @(
                            @{
                                timeSeriesQuery = @{
                                    timeSeriesFilter = @{
                                        filter = "metric.type = 'kubernetes.io/container/cpu/core_usage_time'"
                                        aggregation = @{
                                            perSeriesAligner = "ALIGN_RATE"
                                        }
                                    }
                                }
                            }
                        )
                    }
                },
                @{
                    title = "Memory Usage"
                    xyChart = @{
                        dataSets = @(
                            @{
                                timeSeriesQuery = @{
                                    timeSeriesFilter = @{
                                        filter = "metric.type = 'kubernetes.io/container/memory/used_bytes'"
                                        aggregation = @{
                                            perSeriesAligner = "ALIGN_RATE"
                                        }
                                    }
                                }
                            }
                        )
                    }
                },
                @{
                    title = "Request Latency"
                    xyChart = @{
                        dataSets = @(
                            @{
                                timeSeriesQuery = @{
                                    timeSeriesFilter = @{
                                        filter = "metric.type = 'custom.googleapis.com/opencensus/request_latency'"
                                        aggregation = @{
                                            perSeriesAligner = "ALIGN_RATE"
                                        }
                                    }
                                }
                            }
                        )
                    }
                },
                @{
                    title = "Error Rate"
                    xyChart = @{
                        dataSets = @(
                            @{
                                timeSeriesQuery = @{
                                    timeSeriesFilter = @{
                                        filter = "metric.type = 'custom.googleapis.com/opencensus/error_count'"
                                        aggregation = @{
                                            perSeriesAligner = "ALIGN_RATE"
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
            )
        }
    }
    
    $dashboardConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath "./monitoring/dashboard.json" -Encoding UTF8
    gcloud monitoring dashboards create --config-from-file="./monitoring/dashboard.json"
    
    # Set up log-based metrics
    $logMetricConfig = @{
        name = "error_rate"
        description = "Error rate metric"
        filter = "resource.type = 'k8s_container' AND severity >= ERROR"
        metricDescriptor = @{
            type = "custom.googleapis.com/error_rate"
            displayName = "Error Rate"
            metricKind = "GAUGE"
            valueType = "DOUBLE"
        }
    }
    
    $logMetricConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath "./monitoring/log-metric.json" -Encoding UTF8
    gcloud logging metrics create error_rate --config-from-file="./monitoring/log-metric.json"
    
    # Set up log sink
    gcloud logging sinks create chat-logs bigquery.googleapis.com/projects/$GcpProjectId/datasets/chat_logs
    
    # Set up alerting policies
    $alertPolicyConfig = @{
        displayName = "High CPU Usage"
        conditions = @(
            @{
                displayName = "CPU usage is high"
                conditionThreshold = @{
                    filter = "metric.type = 'kubernetes.io/container/cpu/core_usage_time'"
                    comparison = "COMPARISON_GT"
                    threshold_value = 0.8
                    duration = "300s"
                }
            }
        )
    }
    
    $alertPolicyConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath "./monitoring/alert-policy.json" -Encoding UTF8
    gcloud monitoring policies create --policy-from-file="./monitoring/alert-policy.json"
    
    Write-Host "Monitoring setup completed!"
}

# Function to show dashboard
function Show-Dashboard {
    Write-Host "Opening monitoring dashboard..."
    Start-Process "https://console.cloud.google.com/monitoring/dashboards?project=$GcpProjectId"
}

# Function to show logs
function Show-Logs {
    Write-Host "Opening logs..."
    Start-Process "https://console.cloud.google.com/logs?project=$GcpProjectId"
}

# Function to show alerts
function Show-Alerts {
    Write-Host "Opening alerting policies..."
    Start-Process "https://console.cloud.google.com/monitoring/alerting?project=$GcpProjectId"
}

# Execute requested operations
if ($Setup) {
    Setup-Monitoring
}

if ($Dashboard) {
    Show-Dashboard
}

if ($Logs) {
    Show-Logs
}

if ($Alerts) {
    Show-Alerts
}

Write-Host "`nMonitoring completed!" 