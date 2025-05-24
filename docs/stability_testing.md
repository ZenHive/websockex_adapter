# WebsockexAdapter Stability Testing Guide

This guide covers the stability testing capabilities for WebsockexAdapter, specifically designed for production-grade WebSocket connections with financial APIs.

## Overview

The stability tests verify:
- **Continuous heartbeat functionality** over extended periods
- **Automatic reconnection** on failures
- **Memory stability** under load
- **Message handling performance**
- **Network disruption recovery**

## Available Tests

### 1. Development Stability Test (1 hour)
Quick validation test for development environments.

```bash
# Run 1-hour test
mix stability_test

# Or directly
mix test --only stability_dev test/websockex_adapter/examples/deribit_stability_dev_test.exs
```

### 2. Production Stability Test (24 hours)
Comprehensive test for production validation.

```bash
# Run 24-hour test
mix stability_test --full

# Or directly
mix test --only stability test/websockex_adapter/examples/deribit_stability_test.exs
```

## Prerequisites

Set your Deribit credentials:
```bash
export DERIBIT_CLIENT_ID="your_client_id"
export DERIBIT_CLIENT_SECRET="your_client_secret"
```

## Test Components

### StabilityMonitor
Tracks key metrics during the test:
- Heartbeat count and intervals
- Reconnection events
- Error occurrences
- Message throughput

### MessageHandler
Custom WebSocket handler that:
- Records heartbeat messages
- Tracks market data updates
- Logs connection/disconnection events

## Test Output

The tests provide:
1. **Periodic Status Reports** (every minute/5 minutes)
2. **Final Assessment Report** with:
   - Heartbeat success rate
   - Connection stability metrics
   - Error analysis
   - Overall pass/fail assessment

Example output:
```
📊 === STABILITY TEST STATUS REPORT ===
⏱️  Runtime: 2.5 hours
💓 Heartbeats: 300 (120.0/hour)
🔄 Reconnections: 0
❌ Errors: 0
📨 Messages: 15423
🕐 Last heartbeat: 15s ago
=====================================
```

## Success Criteria

### Development Test (1 hour)
- Heartbeat success rate > 90%
- Reconnections < 2
- Errors < 5

### Production Test (24 hours)
- Heartbeat success rate > 95%
- Reconnection rate < 1 per hour
- Error rate < 2 per hour

## Monitoring During Tests

The tests automatically:
- Verify adapter process health every 30 seconds
- Re-authenticate if connection is lost
- Restore subscriptions after reconnection
- Generate detailed logs for debugging

## Report Files

Tests generate timestamped reports:
```
stability_report_2025-01-23T12:00:00Z.txt
```

## Troubleshooting

Common issues:
1. **Missing credentials**: Set DERIBIT_CLIENT_ID and DERIBIT_CLIENT_SECRET
2. **Network issues**: Ensure stable internet connection
3. **Rate limits**: Test uses minimal API calls to avoid limits

## Integration with CI/CD

For CI environments, use the 1-hour test:
```yaml
test:
  script:
    - mix deps.get
    - mix compile
    - mix stability_test
```

For pre-production validation, run the full 24-hour test in a staging environment.