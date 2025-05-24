# WebsockexAdapter Architecture

## Overview

WebsockexAdapter is a production-grade WebSocket client library built on top of the Gun HTTP/2 client. It provides a simple, reliable interface for WebSocket communications with a focus on financial trading systems.

## Core Design Principles

1. **Simplicity First** - Maximum 5 functions per module, 15 lines per function
2. **Real-World Testing** - No mocks, only real API testing
3. **Financial-Grade Reliability** - Built for high-frequency trading systems
4. **Minimal Abstraction** - Direct Gun API usage, no unnecessary wrappers

## Architecture Layers

### 1. Transport Layer (Gun)
- Direct integration with Gun for WebSocket connections
- HTTP/2 support for modern protocols
- Connection pooling and multiplexing

### 2. Core Modules

#### Client (`client.ex`)
The main interface for WebSocket operations:
- `connect/2` - Establish WebSocket connection
- `send_message/2` - Send messages to server
- `close/1` - Close connection gracefully
- `subscribe/2` - Subscribe to data channels
- `get_state/1` - Retrieve connection state

#### Frame (`frame.ex`)
WebSocket frame handling:
- Binary frame encoding/decoding
- Text frame support
- Control frame processing
- Fragmented message assembly

#### Reconnection (`reconnection.ex`)
Automatic reconnection with exponential backoff:
- Configurable retry attempts
- Exponential backoff calculation
- State preservation across reconnections
- Connection failure categorization

#### Message Handler (`message_handler.ex`)
Message routing and processing:
- Incoming message parsing
- Message type detection
- Callback routing
- Error message handling

#### Error Handler (`error_handler.ex`)
Comprehensive error management:
- Error categorization (connection, protocol, auth, application)
- Recovery strategy selection
- Error context preservation
- Logging and telemetry

### 3. Protocol Support

#### JSON-RPC (`json_rpc.ex`)
Full JSON-RPC 2.0 implementation:
- Request/response correlation
- Batch request support
- Notification handling
- Error response parsing

### 4. Infrastructure Modules

#### Connection Registry (`connection_registry.ex`)
ETS-based connection tracking:
- Fast connection lookups
- Multi-connection support
- Connection metadata storage
- Cleanup on termination

#### Rate Limiter (`rate_limiter.ex`)
Token bucket rate limiting:
- Configurable rate limits
- Burst capacity support
- Per-connection limiting
- Exchange-specific configurations

### 5. Platform Adapters

#### Deribit Adapter (`examples/deribit_adapter.ex`)
Reference implementation for exchange integration:
- Authentication flow
- Heartbeat management
- Subscription handling
- Order management
- Market data processing

## Data Flow

```
User Code
    |
    v
Client API (5 functions)
    |
    v
Message Handler <---> JSON-RPC
    |                    |
    v                    v
Frame Encoder      Rate Limiter
    |                    |
    v                    v
Gun Transport <---> WebSocket Server
    |
    v
Error Handler --> Reconnection
```

## State Management

### Connection State
- Managed by Client GenServer
- Includes: connection status, subscriptions, pending requests
- Preserved across reconnections

### Registry State
- ETS table for O(1) lookups
- Stores: PID to connection mappings
- Automatic cleanup on process termination

### Rate Limiter State
- Token bucket per connection
- Configurable refill rates
- Burst capacity tracking

## Error Handling Strategy

1. **Connection Errors**: Trigger automatic reconnection
2. **Protocol Errors**: Log and notify user callback
3. **Authentication Errors**: Halt and require user intervention
4. **Application Errors**: Pass through to user code

## Supervision Strategy

### Client Supervisor
- Simple one-for-one strategy
- Restart clients on failure
- Configurable restart intensity

### Adapter Supervision
- Platform adapters handle their own supervision
- Separation of concerns between transport and business logic
- Clean restart semantics

## Performance Considerations

1. **ETS for Fast Lookups**: Connection registry uses ETS
2. **Direct Gun API**: No abstraction overhead
3. **Efficient Frame Processing**: Minimal allocations
4. **Telemetry Integration**: Observable performance metrics

## Extension Points

### Custom Adapters
1. Implement authentication for your platform
2. Handle platform-specific message formats
3. Add custom subscription logic
4. Integrate with platform features

### Custom Protocols
1. Extend message handler for new formats
2. Add protocol-specific frame handling
3. Implement custom correlation strategies

## Testing Architecture

### Unit Tests
- Test individual modules in isolation
- Use local mock servers (not mocks!)
- Verify edge cases and error conditions

### Integration Tests
- Test against real APIs (test.deribit.com)
- Verify end-to-end functionality
- Test reconnection scenarios
- Measure real-world performance

### Stability Tests
- Long-running connection tests
- High-frequency message testing
- Network interruption simulation
- Memory leak detection

## Security Considerations

1. **TLS by Default**: All connections use TLS
2. **Credential Management**: Environment variables for secrets
3. **No Credential Logging**: Sensitive data never logged
4. **Secure Frame Masking**: Client-side frame masking

## Monitoring and Observability

### Telemetry Events
- Connection lifecycle events
- Message send/receive metrics
- Error occurrence tracking
- Performance measurements

### Health Checks
- Connection state monitoring
- Heartbeat status
- Rate limit utilization
- Queue depth tracking