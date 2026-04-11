# Collect Docker peer test results and create summary report (PowerShell)
param(
    [string]$ResultsDir = "test_results",
    [string]$SummaryFile = "test_results_summary.json"
)

Write-Host "📊 Collecting peer test results..."

if (-not (Test-Path $ResultsDir)) {
    Write-Host "❌ No test results directory found at $ResultsDir"
    exit 1
}

# Find all result JSON files
$resultFiles = Get-ChildItem "$ResultsDir\*_result.json" -ErrorAction SilentlyContinue
$resultCount = @($resultFiles).Count

if ($resultCount -eq 0) {
    Write-Host "❌ No peer test results found in $ResultsDir"
    exit 1
}

Write-Host "✅ Found $resultCount peer results"

# Build summary
$summary = @{
    timestamp = (Get-Date -Format "o")
    total_peers = $resultCount
    results = @()
    summary = @{
        peers_passed = 0
        total_peers = $resultCount
        success_rate = "0/$resultCount"
        total_messages_expected = 0
        total_messages_received = 0
        all_passed = $false
    }
}

$peersPasssed = 0
$totalExpected = 0
$totalReceived = 0

# Process each result file
foreach ($file in $resultFiles) {
    $content = Get-Content $file | ConvertFrom-Json
    $summary.results += $content

    if ($content.success) {
        $peersPasssed++
    }

    $totalExpected += $content.expected_messages
    $totalReceived += $content.received_messages
}

# Update summary stats
$summary.summary.peers_passed = $peersPasssed
$summary.summary.success_rate = "$peersPasssed/$resultCount"
$summary.summary.total_messages_expected = $totalExpected
$summary.summary.total_messages_received = $totalReceived
$summary.summary.all_passed = ($peersPasssed -eq $resultCount)

# Write summary to file
$summary | ConvertTo-Json -Depth 10 | Out-File $SummaryFile -Encoding UTF8

Write-Host ""
Write-Host "✅ Test summary saved to: $SummaryFile"
Write-Host ""
Write-Host "📄 Summary:"
Get-Content $SummaryFile | ConvertFrom-Json | ConvertTo-Json

Write-Host ""
if ($summary.summary.all_passed) {
    Write-Host "🎉 ALL PEER TESTS PASSED!"
    exit 0
} else {
    Write-Host "❌ SOME PEER TESTS FAILED ($peersPasssed/$resultCount)"
    exit 1
}
