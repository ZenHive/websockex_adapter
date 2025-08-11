# JSON-RPC Elixir Migration Tasks

Migration plan for json_rpc_elixir library to use ZenWebsocket as the underlying WebSocket transport.

## Migration Overview

**Goal**: Replace WebSockex with ZenWebsocket while maintaining full API compatibility and adding enhanced features.

**Strategy**: 3-phase incremental migration ensuring zero breaking changes for existing users.

**Timeline**: Estimated 6-8 weeks for complete migration.

## Task Structure

### Task ID Format
Use `JRE####` format for JSON-RPC Elixir migration tasks:
- Phase 1 (Compatibility): JRE0001-JRE0099
- Phase 2 (Enhancement): JRE0100-JRE0199  
- Phase 3 (Native Integration): JRE0200-JRE0299
- Testing & Documentation: JRE0300-JRE0399

---

## Phase 1: Compatibility Layer (Weeks 1-3)

### JRE0001: Create ZenWebsocket Compatibility Module (✅ PLANNED)
**Description**: Create drop-in replacement for WebSockex using ZenWebsocket

**Priority**: Critical

**Requirements**:
- Implement `JsonRpc.Client.ZenWebsocket` module
- Maintain exact API compatibility with existing `JsonRpc.Client.WebSocket`
- Support all existing WebSockex options
- Preserve existing error handling patterns

**Implementation Details**:
```elixir
defmodule JsonRpc.Client.ZenWebsocket do
  @moduledoc """
  ZenWebsocket-based implementation of JSON-RPC WebSocket client.
  Drop-in replacement for JsonRpc.Client.WebSocket.
  """
  
  # Public API (must match WebSocket module exactly)
  def start_link(conn_info, opts \\ [])
  def call_with_params(client, method, params, timeout \\ 5000)
  def call_without_params(client, method, timeout \\ 5000)
  def notify_with_params(client, method, params)
  def notify_without_params(client, method)
end
```

**Technical Requirements**:
- GenServer-based implementation using ZenWebsocket.Client
- State management compatible with existing Handler.State
- Message correlation using id_to_pid mapping
- Timeout handling with double-receive pattern
- Connection lifecycle management

**Success Criteria**:
- All existing json_rpc_elixir tests pass without modification
- Performance benchmarks show improvement over WebSockex
- Memory usage remains stable or improves

**Dependencies**: ZenWebsocket v1.0+

---

### JRE0002: Implement State Bridge Pattern (✅ PLANNED)
**Description**: Create state management bridge between WebSockex and ZenWebsocket patterns

**Priority**: Critical

**Requirements**:
- Convert between WebSockex Handler.State and ZenWebsocket state
- Maintain id_to_pid correlation mapping
- Handle reconnection state preservation
- Support unrecognized_frame_handler pattern

**Implementation Details**:
```elixir
defmodule JsonRpc.StateBridge do
  @moduledoc """
  Bridges state management between WebSockex and ZenWebsocket patterns.
  """
  
  defstruct [
    :zen_websocket_client,
    :next_id,
    :id_to_pid,
    :time_before_reconnect,
    :unrecognized_frame_handler
  ]
  
  def from_websockex_state(websockex_state)
  def to_websockex_compatible(bridge_state)
  def update_correlation(bridge_state, id, pid)
  def clear_correlations(bridge_state)
end
```

**Technical Requirements**:
- Preserve exact correlation semantics
- Handle concurrent request tracking
- Support reconnection state cleanup
- Maintain frame handler compatibility

**Success Criteria**:
- Zero data loss during state transitions
- Correlation tracking maintains accuracy
- Reconnection preserves essential state

---

### JRE0003: Connection Lifecycle Management (✅ PLANNED)
**Description**: Implement WebSocket connection lifecycle using ZenWebsocket

**Priority**: Critical

**Requirements**:
- Handle connect/disconnect events
- Implement reconnection with exponential backoff
- Manage pending request cleanup during reconnection
- Support connection status monitoring

**Implementation Details**:
```elixir
defmodule JsonRpc.ConnectionManager do
  use GenServer
  
  def init({url, opts}) do
    {:ok, client} = ZenWebsocket.Client.connect(url, [
      reconnect_on_error: true,
      retry_count: 5,
      retry_delay: 100,
      heartbeat_interval: 30_000
    ])
    
    state = %{
      client: client,
      url: url,
      opts: opts,
      connected: true
    }
    
    {:ok, state}
  end
  
  def handle_info({:gun_down, _gun_pid, _protocol, _reason, _stream_refs}, state)
  def handle_info({:gun_up, _gun_pid, _protocol}, state)
end
```

**Technical Requirements**:
- Monitor ZenWebsocket.Client process
- Handle Gun connection events
- Implement proper backoff timing
- Clear message queues on disconnect

**Success Criteria**:
- Reconnection success rate > 99%
- No message leaks during disconnection
- Backoff timing matches WebSockex behavior

---

### JRE0004: Message Correlation System (✅ PLANNED)
**Description**: Implement request/response correlation using ZenWebsocket

**Priority**: Critical

**Requirements**:
- Track JSON-RPC request IDs to caller PIDs
- Handle response routing to correct callers
- Implement timeout management
- Support concurrent request handling

**Implementation Details**:
```elixir
defmodule JsonRpc.CorrelationManager do
  def register_request(manager, id, caller_pid, timeout)
  def handle_response(manager, id, response)
  def handle_timeout(manager, caller_pid)
  def cleanup_expired_requests(manager)
  
  defp send_response_to_caller(pid, response)
  defp send_timeout_to_caller(pid)
  defp start_timeout_timer(id, timeout)
end
```

**Technical Requirements**:
- ETS-based correlation tracking for performance
- Process monitoring for caller cleanup
- Timer management for request timeouts
- Race condition handling in timeout scenarios

**Success Criteria**:
- 100% response correlation accuracy
- Timeout handling matches existing behavior
- Memory cleanup prevents leaks

---

### JRE0005: Frame Processing Compatibility (✅ PLANNED)
**Description**: Implement WebSocket frame processing compatible with existing Handler

**Priority**: High

**Requirements**:
- Process text frames as JSON-RPC messages
- Handle malformed frames gracefully
- Support unrecognized frame handlers
- Maintain error handling patterns

**Implementation Details**:
```elixir
defmodule JsonRpc.FrameProcessor do
  def process_frame({:text, data}, state) do
    case Jason.decode(data) do
      {:ok, json} -> process_json_rpc_message(json, state)
      {:error, reason} -> handle_decode_error(reason, data, state)
    end
  end
  
  def process_frame(frame, state) do
    state.unrecognized_frame_handler.(frame)
    {:ok, state}
  end
  
  defp process_json_rpc_message(message, state)
  defp handle_decode_error(reason, data, state)
end
```

**Technical Requirements**:
- JSON parsing with error recovery
- Response vs notification detection
- Error propagation to correlation manager
- Defensive programming against malformed data

**Success Criteria**:
- All valid JSON-RPC messages processed correctly
- Malformed data handled without crashes
- Error rates match or improve upon WebSockex version

---

### JRE0006: API Creator Integration (✅ PLANNED)
**Description**: Ensure ApiCreator macro works with ZenWebsocket backend

**Priority**: High

**Requirements**:
- Support existing ApiCreator method definitions
- Maintain generated function signatures
- Preserve retry and timeout logic
- Support response parsing patterns

**Implementation Details**:
- Update ApiCreator to detect ZenWebsocket backend
- Modify generated code to use new client interface
- Ensure backward compatibility with existing method configs
- Test all ApiCreator features with new backend

**Technical Requirements**:
- Macro compilation compatibility
- Function signature preservation
- Error handling consistency
- Performance maintenance

**Success Criteria**:
- All existing ApiCreator usage works unchanged
- Generated functions perform equally or better
- Compilation times remain stable

---

### JRE0007: Testing Infrastructure Compatibility (✅ PLANNED)
**Description**: Ensure all existing tests pass with ZenWebsocket backend

**Priority**: Critical

**Requirements**:
- Run existing test suite against new implementation
- Fix any compatibility issues
- Maintain test coverage levels
- Verify performance benchmarks

**Implementation Details**:
- Create test configuration switching mechanism
- Run parallel test suites during development
- Identify and fix breaking changes
- Update test helpers if needed

**Technical Requirements**:
- Test environment switching
- Mock server compatibility
- Assertion behavior preservation
- Performance test maintenance

**Success Criteria**:
- 100% existing test pass rate
- Test coverage remains above 90%
- Performance tests show improvement or parity

---

## Phase 2: Enhanced Integration (Weeks 4-5)

### JRE0100: Rate Limiting Integration (✅ PLANNED)
**Description**: Add ZenWebsocket rate limiting features to JSON-RPC client

**Priority**: Medium

**Requirements**:
- Integrate ZenWebsocket.RateLimiter
- Add rate limiting configuration to ApiCreator
- Support per-method rate limits
- Provide rate limit status monitoring

**Implementation Details**:
```elixir
# Enhanced ApiCreator with rate limiting
use JsonRpc.ApiCreator, [
  %{
    method: "getUser",
    rate_limit: {100, :per_minute},
    rate_limit_strategy: :token_bucket
  }
]
```

**Technical Requirements**:
- Token bucket algorithm implementation
- Per-method limit configuration
- Rate limit exceeded error handling
- Monitoring and metrics integration

**Success Criteria**:
- Rate limits enforced accurately
- Performance impact < 5%
- Rate limit errors handled gracefully

---

### JRE0101: Enhanced Error Handling (✅ PLANNED)
**Description**: Leverage ZenWebsocket's comprehensive error categorization

**Priority**: Medium

**Requirements**:
- Integrate enhanced error types
- Improve error recovery strategies
- Add error context information
- Support custom error handlers

**Implementation Details**:
```elixir
defmodule JsonRpc.EnhancedErrorHandler do
  def categorize_error(error) do
    case error do
      {:connection_timeout, _} -> {:retry, :exponential_backoff}
      {:authentication_failed, _} -> {:abort, :credential_error}
      {:rate_limited, retry_after} -> {:retry, {:fixed_delay, retry_after}}
    end
  end
end
```

**Technical Requirements**:
- Error classification system
- Recovery strategy mapping
- Context preservation
- Logging integration

**Success Criteria**:
- Error recovery success rate > 95%
- Error context provides useful debugging info
- Recovery strategies reduce failure rates

---

### JRE0102: Heartbeat Integration (✅ PLANNED)
**Description**: Integrate ZenWebsocket's heartbeat functionality

**Priority**: Medium

**Requirements**:
- Configure automatic heartbeat/ping handling
- Support JSON-RPC test_request patterns
- Add heartbeat monitoring
- Handle heartbeat failures

**Implementation Details**:
```elixir
# Heartbeat configuration
def start_link(conn, opts \\ []) do
  enhanced_opts = Keyword.merge(opts, [
    heartbeat_interval: 30_000,
    heartbeat_timeout: 5_000,
    heartbeat_method: "test_request"
  ])
  
  JsonRpc.Client.ZenWebsocket.start_link(conn, enhanced_opts)
end
```

**Technical Requirements**:
- JSON-RPC heartbeat message format
- Heartbeat response validation
- Connection health monitoring
- Automatic reconnection on heartbeat failure

**Success Criteria**:
- Connection stability improves measurably
- Heartbeat overhead < 1% of bandwidth
- Failure detection time < 35 seconds

---

### JRE0103: Metrics and Monitoring (✅ PLANNED)
**Description**: Add comprehensive metrics using ZenWebsocket's telemetry

**Priority**: Low

**Requirements**:
- Request/response timing metrics
- Connection health metrics
- Error rate monitoring
- Performance dashboards

**Implementation Details**:
```elixir
defmodule JsonRpc.Metrics do
  def track_request_timing(method, duration)
  def track_connection_health(status)
  def track_error_rates(error_type, count)
  def generate_performance_report()
end
```

**Technical Requirements**:
- Telemetry event integration
- Metrics aggregation
- Dashboard compatibility
- Low-overhead instrumentation

**Success Criteria**:
- Comprehensive operational visibility
- Performance overhead < 2%
- Useful debugging information

---

## Phase 3: Native Integration (Weeks 6-8)

### JRE0200: Native ZenWebsocket Implementation (✅ PLANNED)
**Description**: Rewrite core modules to use ZenWebsocket natively

**Priority**: High

**Requirements**:
- Remove WebSockex dependency completely
- Optimize for ZenWebsocket patterns
- Simplify codebase architecture
- Improve performance characteristics

**Implementation Details**:
```elixir
defmodule JsonRpc.Client.Native do
  @behaviour ZenWebsocket.MessageHandler
  
  def init(opts) do
    {:ok, %{
      correlation_manager: JsonRpc.CorrelationManager.new(),
      response_parsers: %{},
      metrics_collector: JsonRpc.Metrics.new()
    }}
  end
  
  def handle_message({:text, data}, state) do
    with {:ok, json} <- Jason.decode(data),
         {:ok, new_state} <- JsonRpc.MessageRouter.route(json, state) do
      {:ok, new_state}
    else
      error -> {:error, error}
    end
  end
end
```

**Technical Requirements**:
- Clean architecture using ZenWebsocket behaviors
- Optimal performance patterns
- Reduced memory footprint
- Simplified error handling

**Success Criteria**:
- 20%+ performance improvement
- 30%+ reduction in lines of code
- Simplified debugging and maintenance

---

### JRE0201: Advanced Features Integration (✅ PLANNED)
**Description**: Implement advanced ZenWebsocket features not available in WebSockex

**Priority**: Medium

**Requirements**:
- Connection pooling support
- Advanced reconnection strategies
- Sophisticated rate limiting
- Enhanced monitoring capabilities

**Implementation Details**:
```elixir
defmodule JsonRpc.AdvancedClient do
  def start_pool(pool_size, conn_info, opts \\ []) do
    ZenWebsocket.ConnectionPool.start_link(
      pool_size: pool_size,
      connection_opts: [
        adapter: JsonRpc.Client.Native,
        url: conn_info
      ]
    )
  end
end
```

**Technical Requirements**:
- Pool management strategies
- Load balancing algorithms
- Advanced monitoring
- Failover capabilities

**Success Criteria**:
- Connection pool efficiency > 90%
- Failover time < 1 second
- Advanced features work reliably

---

### JRE0202: Performance Optimization (✅ PLANNED)
**Description**: Optimize performance using ZenWebsocket's advanced features

**Priority**: Medium

**Requirements**:
- Message batching optimization
- Connection reuse strategies
- Memory usage optimization
- Latency reduction techniques

**Implementation Details**:
- Implement message batching for high-frequency requests
- Optimize JSON parsing and encoding
- Use ETS for high-performance lookups
- Implement zero-copy message handling where possible

**Technical Requirements**:
- Benchmarking infrastructure
- Performance regression testing
- Memory profiling
- Latency measurement

**Success Criteria**:
- 50%+ improvement in high-frequency scenarios
- Memory usage reduction of 25%
- P99 latency improvement of 30%

---

### JRE0203: Documentation and Examples (✅ PLANNED)
**Description**: Update documentation for ZenWebsocket integration

**Priority**: High

**Requirements**:
- Migration guide for existing users
- Performance comparison documentation
- New feature usage examples
- Best practices guide

**Implementation Details**:
- Create comprehensive migration guide
- Document performance improvements
- Provide before/after examples
- Create troubleshooting guide

**Technical Requirements**:
- Clear documentation structure
- Working code examples
- Performance benchmarks
- Migration checklists

**Success Criteria**:
- Users can migrate without support
- New features are well documented
- Performance benefits are clear

---

## Testing Strategy

### JRE0300: Comprehensive Test Suite (✅ PLANNED)
**Description**: Develop comprehensive test coverage for migration

**Priority**: Critical

**Requirements**:
- Unit tests for all new modules
- Integration tests with real WebSocket servers
- Performance regression tests
- Compatibility tests with existing code

**Implementation Details**:
- Property-based testing for message correlation
- Load testing for performance verification  
- Real-world scenario testing
- Backward compatibility verification

**Technical Requirements**:
- Test automation
- Performance benchmarking
- Real API testing
- Stress testing capabilities

**Success Criteria**:
- 95%+ test coverage
- All performance benchmarks pass
- Zero regressions in functionality

---

### JRE0301: Migration Testing (✅ PLANNED)
**Description**: Test migration scenarios and backward compatibility

**Priority**: Critical

**Requirements**:
- Test incremental migration scenarios
- Verify zero-downtime migration capability
- Test rollback procedures
- Validate configuration migration

**Implementation Details**:
- Create migration simulation environment
- Test production-like scenarios
- Verify monitoring during migration
- Test error handling during migration

**Technical Requirements**:
- Migration environment setup
- Rollback verification
- Production simulation
- Error injection testing

**Success Criteria**:
- Zero-downtime migration achieved
- Rollback procedures work flawlessly
- Migration monitoring provides visibility

---

## Risk Assessment and Mitigation

### High-Risk Items
1. **API Compatibility Breaking**: Mitigation through comprehensive compatibility layer
2. **Performance Regressions**: Mitigation through continuous benchmarking
3. **State Management Issues**: Mitigation through careful state bridge design
4. **Migration Complexity**: Mitigation through phased approach

### Medium-Risk Items
1. **Memory Leaks**: Mitigation through extensive testing and monitoring
2. **Timeout Behavior Changes**: Mitigation through timeout compatibility layer
3. **Error Handling Differences**: Mitigation through error mapping layer

### Low-Risk Items
1. **Documentation Gaps**: Mitigation through comprehensive documentation plan
2. **Learning Curve**: Mitigation through examples and migration guides

## Success Metrics

### Performance Metrics
- **Latency**: 30% improvement in P99 latency
- **Throughput**: 50% improvement in high-frequency scenarios
- **Memory**: 25% reduction in memory usage
- **Connection Stability**: 99.9% uptime target

### Quality Metrics
- **Test Coverage**: Maintain 95%+ coverage
- **Bug Rate**: <1 bug per 1000 lines of code
- **Documentation**: 100% API coverage
- **Migration Success**: 95% successful migrations

### Adoption Metrics
- **User Feedback**: 90%+ positive feedback
- **Migration Rate**: 80% of users migrate within 6 months
- **Support Requests**: <10% increase during migration period

## Dependencies and Prerequisites

### Technical Dependencies
- ZenWebsocket v1.0+ with stable API
- Gun v2.2+ for transport layer
- Jason v1.4+ for JSON handling
- Elixir v1.18+ for compatibility

### Resource Requirements
- 1-2 senior Elixir developers
- Testing infrastructure
- Performance benchmarking tools
- Documentation resources

### Timeline Dependencies
- Phase 1 must complete before Phase 2
- All testing must complete before production release
- Documentation must be complete before user migration begins

## Conclusion

This migration plan provides a comprehensive roadmap for transitioning json_rpc_elixir from WebSockex to ZenWebsocket. The phased approach ensures minimal risk while maximizing the benefits of the more robust transport layer.

The key to success will be maintaining strict API compatibility while leveraging ZenWebsocket's enhanced features for improved performance and reliability.