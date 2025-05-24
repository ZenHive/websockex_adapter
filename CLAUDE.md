# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**WebsockexAdapter** is a robust WebSocket client library for Elixir, specifically designed for financial APIs (particularly Deribit cryptocurrency trading). Built on Gun transport, it started with 8 foundation modules and is now being enhanced with critical financial infrastructure while maintaining strict simplicity principles.

**Financial Development Principle**: Start simple, add complexity only when necessary based on real data. This is a well-established principle in financial software development, especially for market making.

## Development Commands

### Core Development
- `mix compile` - Compile the project
- `mix test` - Run test suite (93 tests, all using real APIs)
- `mix test --cover` - Run tests with coverage reporting
- `mix coverage` - Alias for test with coverage

### Code Quality Tools
- `mix lint` - Run Credo static analysis in strict mode
- `mix typecheck` - Run Dialyzer type checking  
- `mix security` - Run Sobelow security analysis
- `mix check` - Run all quality checks (lint + typecheck + security + coverage)
- `mix rebuild` - Full rebuild (clean deps, recompile, run all checks)

### Documentation
- `mix docs` - Generate documentation

### Testing Commands
- `mix test.api` - Run real API integration tests (via lib/mix/tasks/test.ex)
- `mix test.api --deribit` - Deribit-specific API tests
- `mix test.performance` - Performance and stress testing

## Architecture

### Architecture Evolution

#### Foundation Modules (8 core - complete)
```
lib/websockex_adapter/
├── client.ex              # Main client interface (5 public functions)
├── config.ex              # Configuration struct and validation
├── frame.ex               # WebSocket frame encoding/decoding  
├── connection_registry.ex # ETS-based connection tracking
├── reconnection.ex        # Exponential backoff retry logic
├── message_handler.ex     # Message parsing and routing
├── error_handler.ex       # Error categorization and recovery
├── json_rpc.ex           # JSON-RPC 2.0 protocol support
```

#### Enhancement Modules (financial infrastructure - in progress)
```
├── correlation_manager.ex # Request/response correlation
├── rate_limiter.ex        # API rate limit management
└── examples/
    └── deribit_adapter.ex # Deribit platform integration
```

**Note**: Heartbeat functionality is integrated directly into the Client GenServer for optimal performance and reduced complexity.

### Public API (Only 5 Functions)
```elixir
# Everything users need for WebSocket operations
WebsockexAdapter.Client.connect(url, opts)
WebsockexAdapter.Client.send_message(client, message) 
WebsockexAdapter.Client.close(client)
WebsockexAdapter.Client.subscribe(client, channels)
WebsockexAdapter.Client.get_state(client)
```

### Core Architecture Principles
- **Foundation Phase Complete** - 8 core modules established
- **Enhancement Phase** - Adding critical financial infrastructure
- **Maximum 5 functions per module** for new modules
- **Maximum 15 lines per function**
- **Use behaviors** when ≥2 implementations exist or when clarifying interfaces
- **Direct Gun API usage** - no wrapper layers
- **Use GenServers** when you need message handling, state, or supervision
- **Real API testing only** - zero mocks

## Code Style Guidelines

### Documentation Optimization
Balance token optimization with readability:

**DO (Optimized Documentation):**
```elixir
@moduledoc """
WebSocket client for real-time cryptocurrency trading APIs.

- Uses Gun transport for WebSocket connections
- Handles automatic reconnection with exponential backoff
- Supports message routing and frame handling
"""

@doc """
Connects to WebSocket endpoint with configuration options.

Returns client struct for subsequent operations.
"""
```

**DON'T (Verbose Documentation):**
```elixir
@moduledoc """
This module provides a comprehensive WebSocket client implementation
specifically designed for cryptocurrency trading platforms. It offers
robust connection management, automatic reconnection capabilities,
and efficient message handling for real-time market data streaming.
"""
```

### Function Structure
**DO (Optimized Code Structure):**
```elixir
def connect(%Config{url: url} = config, opts \\ []) do
  timeout = config.timeout
  headers = config.headers

  with {:ok, gun_pid} <- open_connection(url, opts),
       {:ok, stream_ref} <- upgrade_to_websocket(gun_pid, headers),
       :ok <- await_websocket_upgrade(gun_pid, stream_ref, timeout) do
    {:ok, %Client{gun_pid: gun_pid, stream_ref: stream_ref, state: :connected}}
  else
    error -> {:error, error}
  end
end
```

**DON'T (Verbose, Complex Structure):**
```elixir
def establish_websocket_connection_with_configuration(configuration_parameters, additional_options \\ []) do
  # Complex, verbose implementation with unnecessary abstraction
end
```

## Configuration

### Environment Setup
Required environment variables for Deribit integration:
```bash
export DERIBIT_CLIENT_ID="your_client_id" 
export DERIBIT_CLIENT_SECRET="your_client_secret"
```

### Configuration Options
WebsockexAdapter.Config supports 6 essential options:
- `url` - WebSocket endpoint URL
- `headers` - Connection headers  
- `timeout` - Connection timeout (default: 5000ms)
- `retry_count` - Maximum retry attempts (default: 3)
- `retry_delay` - Initial retry delay (default: 1000ms) 
- `heartbeat_interval` - Ping interval (default: 30000ms)

## Testing Strategy

### Real API Testing Policy (CRITICAL)
**NO MOCKS ALLOWED** - This project uses ONLY real API testing:
- `test.deribit.com` for Deribit integration
- Local mock servers using existing `MockWebSockServer` infrastructure
- Real network conditions and error scenarios

**Testing Rationale**: Financial software requires testing against real conditions - network latency, connection drops, actual API behavior. Mocks hide real-world edge cases that can cause financial losses.

### Test Structure
```
test/websockex_adapter/           # Core module tests
test/integration/             # Real API integration tests  
test/support/                 # Shared test infrastructure
```

### Integration Test Requirements
- Tag integration tests with `@tag :integration`
- Test realistic scenarios including market conditions
- Verify end-to-end functionality across component boundaries
- Document test scenarios with clear descriptions

**Example Integration Test:**
```elixir
@tag :integration
test "maintains subscriptions across reconnection", %{deribit_config: config} do
  # Use real Deribit testnet connection (no mocks)
  {:ok, client} = WebsockexAdapter.Client.connect(config.url, config.opts)

  # Subscribe to real market data
  {:ok, _} = WebsockexAdapter.Client.subscribe(client, ["book.BTC-PERPETUAL.raw"])
  
  # Simulate connection drop
  Process.exit(client.gun_pid, :kill)
  
  # Verify reconnection and subscription restoration
  wait_for_reconnection(client)
  assert_subscription_active(client, "book.BTC-PERPETUAL.raw")
end
```

### Key Test Support Modules
- `MockWebSockServer` - Controlled WebSocket server for testing
- `CertificateHelper` - TLS certificate generation  
- `NetworkSimulator` - Network condition simulation
- `TestEnvironment` - Environment management

## Error Handling Architecture

### Core Principles
- **Pass raw errors** without wrapping in custom structs
- **Use consistent {:ok, result} | {:error, reason} pattern**
- **Apply "let it crash" philosophy** for unexpected errors
- **Add minimal context** information only when necessary

### Error Categories
- **Connection errors** - Network failures, timeouts
- **Protocol errors** - Malformed WebSocket frames  
- **Authentication errors** - Invalid credentials
- **Application errors** - Business logic failures

### Error Handling Pattern
**DO (Pattern Matching on Raw Errors):**
```elixir
def handle_connection_error({:error, error}) do
  case error do
    {:timeout, _duration} -> handle_timeout_error()
    {:connection_refused, _details} -> handle_connection_refused()
    {:protocol_error, frame_error} -> handle_frame_error(frame_error)
    _ -> {:error, :unknown_connection_error}
  end
end
```

**DON'T (Custom Error Transformation):**
```elixir
def handle_connection_error({:error, error}) do
  # Don't transform errors unnecessarily
  error_type = classify_websocket_error(error)
  # Complex transformation logic...
end
```

### Recovery Patterns
- Exponential backoff reconnection with state preservation
- Automatic subscription re-establishment  
- Comprehensive error categorization for appropriate handling

## Simplicity Guidelines

### Foundational Principles
- **Code simplicity is a primary feature**, not an afterthought
- **Implement minimal viable solution first**
- **Each component has a limited "complexity budget"**
- **Create abstractions only with proven value** (≥2 concrete examples)
- **Start simple and add complexity incrementally**
- **Prioritize execution and practical operational efficiency**

### Module Structure Evolution
- **Foundation Phase**: 8 core modules (complete)
- **Enhancement Phase**: Adding critical financial infrastructure
  - Each new module must demonstrate clear value proposition
  - Modules added only when proven necessary by real use cases
  - Maintain strict quality constraints per module
- **Maximum 5 functions per module** for all modules
- **Maximum function length of 15 lines**
- **Maximum of 2 levels of function calls** for any operation
- **Choose the right tool**: pure functions for stateless operations, GenServers for stateful/concurrent needs

### When to Use GenServers

**Use GenServers when you need to:**
- **Receive messages** - e.g., Gun WebSocket frames that arrive asynchronously
- **Maintain state** - e.g., connection state, subscriptions, correlation tracking
- **Coordinate concurrent access** - e.g., rate limiting, connection pooling
- **Implement supervision** - e.g., supervised processes with restart strategies

**Use pure functions/ETS when:**
- **No message handling needed** - e.g., frame encoding/decoding
- **Simple lookups suffice** - e.g., connection registry
- **Stateless transformations** - e.g., message parsing, validation

### Anti-Patterns to Avoid
- No premature optimization without performance data
- No "just-in-case" code for hypothetical requirements
- No abstractions without at least 2 concrete usage examples
- No complex macros unless absolutely necessary
- No overly clever solutions that prioritize elegance over maintainability
- No avoiding GenServers when they're the natural solution

**Remember**: "The elegance comes from doing less, not more. Removing complexity, not adding it!"

## WebSocket Connection Architecture

### Connection Model
- WebSocket connections are Gun processes managed by WebsockexAdapter.Client
- Connection processes are monitored, not owned by complex supervisors
- Failures detected by `Process.monitor/1` and classified by exit reasons

### Reconnection Requirements
**DO (Follow Established Pattern):**
```elixir
{:ok, client} = WebsockexAdapter.Client.connect(url, [
  timeout: 5000,
  retry_count: 3,
  retry_delay: 1000,
  heartbeat_interval: 30000
])
```

**DON'T (Custom Reconnection Logic):**
```elixir
# Don't create custom reconnection loops outside the framework
```

## Platform Integration

### Deribit Adapter
Complete Deribit cryptocurrency exchange integration:
- Authentication flow
- Subscription management  
- Heartbeat/test_request handling
- JSON-RPC 2.0 message formatting
- Cancel-on-disconnect protection
- Supervised reconnection pattern (adapter handles all reconnection)

Located in `lib/websockex_adapter/examples/deribit_adapter.ex`

#### Reconnection Architecture Pattern
When using adapters like `DeribitGenServerAdapter`, the reconnection responsibility is clearly divided:

**Supervised Pattern (Recommended for production):**
```elixir
# Adapter disables client's internal reconnection
connect_opts = [
  reconnect_on_error: false,  # Client stops cleanly on errors
  heartbeat_config: %{...}    # Other options preserved
]

# Adapter handles ALL reconnection scenarios:
# - Network failures (connection drops)
# - Process crashes (client dies)
# - Authentication restoration
# - Subscription restoration
```

**Standalone Pattern (For simple use cases):**
```elixir
# Client handles its own reconnection
{:ok, client} = Client.connect(url)  # reconnect_on_error: true (default)
```

This architecture eliminates duplicate reconnection attempts and provides clear ownership of the reconnection logic.

## Key Dependencies

### Core Runtime
- `gun ~> 2.2` - HTTP/2 and WebSocket client
- `jason ~> 1.4` - JSON encoding/decoding
- `telemetry ~> 1.3` - Metrics and monitoring

### Development Tools  
- `credo ~> 1.7` - Static code analysis
- `dialyxir ~> 1.4` - Type checking
- `sobelow ~> 0.13` - Security scanning
- `ex_doc ~> 0.31` - Documentation generation

### Testing Infrastructure
- `cowboy ~> 2.10` - Test WebSocket server
- `websock ~> 0.5` - WebSocket protocol handling
- `stream_data ~> 1.0` - Property-based testing
- `x509 ~> 0.8` - Certificate generation for testing

## Working with the Codebase

### Adding New Features (Enhancement Phase)
1. **Justify the module** - demonstrate clear need with real use cases
2. **Write tests first** following TDD principles  
3. **Implement as new module** with max 5 functions
4. **Add real API tests** (no mocks)
5. **Update configuration** if needed
6. **Run `mix check`** to validate all quality gates
7. **Update architecture documentation** to include new module

### Code Quality Standards
- All public functions must have `@spec` annotations
- All modules must have `@moduledoc` documentation
- Follow functional, declarative style with pattern matching
- Use tagged tuples for consistent error handling
- Pass all static checks: `mix format`, `mix credo --strict`, `mix dialyzer`

### Debugging
- Maximum 2 modules to trace any issue
- All errors categorized in `error_handler.ex`
- Telemetry events for monitoring
- Comprehensive logging at appropriate levels

### Performance Considerations
- ETS-based connection registry for fast lookups
- Efficient process usage (GenServers where appropriate for state management)
- Efficient frame encoding/decoding
- Connection pooling via Gun transport layer

## Integration Notes

### For Financial Trading
This library targets market makers and option sellers requiring:
- **High-frequency API calls**
- **Reliable reconnection with state preservation**  
- **Real-time market data subscriptions**
- **Risk management API integration**
- **Sub-millisecond latency requirements**

### Extending for Other Platforms
Follow the Deribit adapter pattern in `examples/` directory:
1. **Implement platform-specific authentication**
2. **Add subscription message formatting**
3. **Handle platform heartbeat requirements**  
4. **Create comprehensive real API tests**
5. **Document integration patterns**
6. **Follow simplicity principles** - start minimal, add complexity only when proven necessary

## Task Management

### Task ID Format
Use `WNX####` format for all WebSocket-related tasks:
- Core functionality: WNX0001-WNX0099
- Feature enhancements: WNX0100-WNX0199
- Documentation: WNX0200-WNX0299
- Testing: WNX0300-WNX0399

### Task Tracking Standards
Tasks are tracked in `docs/TaskList.md` with the following structure:

#### Status Values
- `Planned` - Task identified but not started
- `In Progress` - Currently being worked on
- `Review` - Implementation complete, under review
- `Completed` - Fully implemented and reviewed
- `Blocked` - Cannot proceed due to dependencies

#### Priority Values
- `Critical` - Must be done immediately
- `High` - Should be done soon
- `Medium` - Normal priority
- `Low` - Nice to have

#### Review Ratings
- ⭐⭐⭐⭐⭐ (5 stars) - Excellent implementation
- ⭐⭐⭐⭐ (4 stars) - Good implementation
- ⭐⭐⭐ (3 stars) - Acceptable implementation
- ⭐⭐ (2 stars) - Needs improvement
- ⭐ (1 star) - Major issues

### Required Task Sections
Each task in TaskList.md must include:

1. **Description**: Clear explanation of what needs to be done
2. **Simplicity Progression Plan**: Step-by-step approach maintaining simplicity
3. **Simplicity Principle**: Brief explanation of simplicity approach
4. **Abstraction Evaluation**: 
   - Challenge question about necessary abstraction
   - Minimal solution proposal
   - Justification with concrete use cases
5. **Requirements**: Specific functional requirements
6. **ExUnit Test Requirements**: Unit test scenarios
7. **Integration Test Scenarios**: Real API test scenarios
8. **TypeSpec Requirements**: Type specification needs
9. **TypeSpec Documentation**: Documentation requirements for types
10. **TypeSpec Verification**: Verification steps for type correctness
11. **Error Handling**: WebSocket/Gun specific error patterns with sections:
    - Core Principles
    - Error Implementation
    - Error Examples
    - GenServer/WebSocket Specifics
12. **Code Quality KPIs**: Measurable metrics including:
    - Lines of code
    - Functions per module
    - Lines per function
    - Call depth
    - Cyclomatic complexity
    - Test coverage
13. **Dependencies**: Required libraries and modules
14. **Architecture Notes**: High-level design considerations
15. **Status**: Current task status
16. **Priority**: Task priority level
17. **Implementation Notes**: Technical considerations
18. **Complexity Assessment**: Evaluation of solution complexity
19. **Maintenance Impact**: Long-term maintenance implications
20. **Error Handling Implementation**: Specific error scenarios and responses

### Task Documentation Format
```markdown
### WNX####: [Task Title] (✅ COMPLETED)
**Description**: [Detailed task description]

**Simplicity Progression Plan**:
1. [Step 1]
2. [Step 2]
3. [Step 3]
4. [Step 4]

**Simplicity Principle**:
[Brief description of the simplicity principle applied]

**Abstraction Evaluation**:
- **Challenge**: [Question about necessary abstraction]
- **Minimal Solution**: [Simplest viable solution]
- **Justification**:
  1. [Use case 1]
  2. [Use case 2]
  3. [Use case 3]

**Requirements**:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]
- [Requirement 4]

**ExUnit Test Requirements**:
- [Test requirement 1]
- [Test requirement 2]
- [Test requirement 3]
- [Test requirement 4]

**Integration Test Scenarios**:
- [Test scenario 1]
- [Test scenario 2]
- [Test scenario 3]
- [Test scenario 4]

**Typespec Requirements**:
- [TypeSpec requirement 1]
- [TypeSpec requirement 2]
- [TypeSpec requirement 3]

**TypeSpec Documentation**:
- [Documentation requirement 1]
- [Documentation requirement 2]
- [Documentation requirement 3]

**TypeSpec Verification**:
- [Verification step 1]
- [Verification step 2]
- [Verification step 3]

**Error Handling**
**Core Principles**
- Pass raw errors
- Use {:ok, result} | {:error, reason}
- Let it crash
**Error Implementation**
- No wrapping
- Minimal rescue
- function/1 & /! versions
**Error Examples**
- Raw error passthrough
- Simple rescue case
- Supervisor handling
**GenServer Specifics**
- Handle_call/3 error pattern
- Terminate/2 proper usage
- Process linking considerations

**Code Quality KPIs**
- Lines of code: [number] ([description])
- Functions per module: [number]
- Lines per function: [number]
- Call depth: [number]
- Cyclomatic complexity: [Low/Medium/High] ([description])
- Test coverage: [percentage] with real API testing

**Dependencies**
- [dependency]: [purpose]
- [dependency]: [purpose]
- [dependency]: [purpose]

**Architecture Notes**
- [Architecture note 1]
- [Architecture note 2]
- [Architecture note 3]
- [Architecture note 4]

**Status**: [Status]
**Priority**: [Priority]

**Implementation Notes**:
- [Implementation note 1]
- [Implementation note 2]
- [Implementation note 3]
- [Implementation note 4]

**Complexity Assessment**:
- Previous: [Previous state]
- Current: [Current state]
- Added Complexity: [Description of added complexity]
- Justification: [Why the complexity is necessary]

**Maintenance Impact**:
- [Maintenance impact 1]
- [Maintenance impact 2]
- [Maintenance impact 3]
- [Maintenance impact 4]

**Error Handling Implementation**:
- [Error scenario 1]: [Response/handling]
- [Error scenario 2]: [Response/handling]
- [Error scenario 3]: [Response/handling]
```

### WebSocket-Specific Requirements
- All WebSocket connection tasks must include real API testing requirements
- Platform integration tasks should reference existing Deribit adapter patterns
- Frame handling tasks must include malformed data testing scenarios
- Reconnection tasks must test with real network interruption scenarios

### Validation Rules
- All task IDs must be unique and use WNX prefix
- All current tasks must have detailed entries
- Completed tasks must have implementation notes and review ratings
- WebSocket tasks must include connection testing requirements
- Error handling sections must reference Gun/WebSocket error patterns