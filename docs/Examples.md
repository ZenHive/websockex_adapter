# WebsockexAdapter Examples

This guide provides practical examples of using WebsockexAdapter in various scenarios. All examples are fully tested and available in the `lib/websockex_adapter/examples/` directory.

## Working Examples

All examples have comprehensive test coverage and demonstrate real-world usage patterns:

### Core Examples (in `examples/docs/`)
- **[Basic Usage](../lib/websockex_adapter/examples/docs/basic_usage.ex)** - Basic connection and messaging patterns ([tests](../test/websockex_adapter/examples/basic_usage_test.exs))
- **[Error Handling](../lib/websockex_adapter/examples/docs/error_handling.ex)** - Robust error recovery patterns ([tests](../test/websockex_adapter/examples/error_handling_test.exs))
- **[JSON-RPC Client](../lib/websockex_adapter/examples/docs/json_rpc_client.ex)** - JSON-RPC 2.0 protocol usage
- **[Subscription Management](../lib/websockex_adapter/examples/docs/subscription_management.ex)** - Channel subscription patterns ([tests](../test/websockex_adapter/examples/subscription_management_test.exs))

### Platform Adapters
- **Platform Adapter Template** - Template for creating platform-specific adapters (see platform_adapter_template.ex)
- **Deribit Integration** - Complete examples moved to market_maker project for better separation of concerns

### Architecture Examples
- **[Adapter Supervisor](../lib/websockex_adapter/examples/adapter_supervisor.ex)** - Fault-tolerant supervision patterns
- **[Supervised Client](../lib/websockex_adapter/examples/supervised_client.ex)** - Client supervision with restart strategies
- **[Usage Patterns](../lib/websockex_adapter/examples/usage_patterns.ex)** - Common WebSocket patterns and best practices

## Running the Examples

### Basic Connection Example

```bash
# Run the basic usage example test
mix test test/websockex_adapter/examples/basic_usage_test.exs

# Or run it in IEx
iex -S mix
```

```elixir
# In IEx, try the basic usage example
alias WebsockexAdapter.Examples.Docs.BasicUsage

# Echo server example
{:ok, result} = BasicUsage.echo_example()

# Custom headers example
{:ok, client} = BasicUsage.connect_with_headers("wss://echo.websocket.org", "Bearer token123")
```

### Platform Integration Example

For comprehensive platform integration examples (including Deribit), see the `market_maker` project which demonstrates:
- Authentication flows
- Supervised adapters with automatic recovery
- Market data subscriptions
- Trading operations
- Error handling and reconnection

The WebsockexAdapter library provides the infrastructure, while platform-specific business logic resides in dedicated projects.

## Example Patterns

### Error Recovery Pattern

See [error_handling.ex](../lib/websockex_adapter/examples/docs/error_handling.ex) for a complete implementation:

```elixir
alias WebsockexAdapter.Examples.Docs.ErrorHandling

# Start a resilient client
{:ok, client} = ErrorHandling.start_link("wss://echo.websocket.org")

# The client automatically handles:
# - Connection failures with exponential backoff
# - Message send failures with retries
# - WebSocket errors with appropriate recovery
```

### Subscription Management Pattern

See [subscription_management.ex](../lib/websockex_adapter/examples/docs/subscription_management.ex) for implementation:

```elixir
alias WebsockexAdapter.Examples.Docs.SubscriptionManagement

# Start a client with managed subscriptions
{:ok, manager} = SubscriptionManagement.start_link("wss://test.deribit.com/ws/api/v2")

# Add subscriptions (automatically restored on reconnection)
:ok = SubscriptionManagement.add_subscription(manager, "ticker.BTC-PERPETUAL.raw")
:ok = SubscriptionManagement.add_subscription(manager, "book.ETH-PERPETUAL.100ms")

# List active subscriptions
subscriptions = SubscriptionManagement.list_subscriptions(manager)
```

### JSON-RPC Pattern

See [json_rpc_client.ex](../lib/websockex_adapter/examples/docs/json_rpc_client.ex) for implementation:

```elixir
alias WebsockexAdapter.Examples.Docs.JsonRpcClient

# Start a JSON-RPC client
{:ok, client} = JsonRpcClient.start_link("wss://api.example.com/jsonrpc")

# Make RPC calls with automatic correlation
{:ok, result} = JsonRpcClient.call(client, "get_account_info", %{account_id: "123"})
{:ok, balance} = JsonRpcClient.call(client, "get_balance", %{currency: "USD"})
```

## Testing Your Implementation

All examples come with comprehensive tests. To run them:

```bash
# Run all example tests
mix test test/websockex_adapter/examples/

# Run specific example test
mix test test/websockex_adapter/examples/basic_usage_test.exs

# Run with coverage
mix test --cover test/websockex_adapter/examples/
```

## Best Practices

1. **Use GenServers for Stateful Connections**: See `DeribitGenServerAdapter` for a production-ready pattern
2. **Handle Errors at the Appropriate Level**: Let the framework handle reconnection, focus on business logic
3. **Test Against Real APIs**: All examples use real WebSocket endpoints for testing
4. **Monitor Connection Health**: Use telemetry events and health checks
5. **Batch Operations**: For high-frequency data, batch updates before processing

## Extending for Your Platform

To create an adapter for your platform:

1. Study the platform adapter template in `examples/platform_adapter_template.ex`
2. Follow the [adapter building guide](guides/building_adapters.md)
3. Implement platform-specific:
   - Authentication flow
   - Message formatting
   - Subscription management
   - Error handling
4. Add comprehensive tests using real API endpoints
5. Document platform-specific features

## Additional Resources

- [Architecture Overview](Architecture.md)
- [Building Custom Adapters](guides/building_adapters.md)
- [Troubleshooting Reconnection](guides/troubleshooting_reconnection.md)
- [API Documentation](https://hexdocs.pm/websockex_adapter)