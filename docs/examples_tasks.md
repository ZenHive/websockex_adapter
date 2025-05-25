# Examples Simplification Tasks

This document outlines tasks for simplifying the WebsockexAdapter examples to align with the project's core simplicity principles.

## Core Principles Reminder

- **Maximum 5 functions per module**
- **Maximum 15 lines per function**
- **Start simple, add complexity only when proven necessary**
- **Infrastructure only - no business logic**
- **Real API testing - no mocks**

## Task Summary

### 🔴 Move to market_maker (High Priority)

#### Task 1: Move PositionTracker to market_maker
- **Files**:
  - `lib/websockex_adapter/examples/position_tracker.ex`
  - `test/websockex_adapter/examples/position_tracker_test.exs`
- **Reason**: Business logic (P&L calculations) doesn't belong in infrastructure library
- **Action**: Move to `../market_maker/examples/position_tracker.ex` and `../market_maker/test/examples/position_tracker_test.exs`
- **Lines moved**: 320 + tests

#### Task 2: Move DeltaNeutralHedger to market_maker
- **Files**:
  - `lib/websockex_adapter/examples/delta_neutral_hedger.ex`
  - `test/websockex_adapter/examples/delta_neutral_hedger_test.exs`
- **Reason**: Trading strategy implementation - user concern, not library concern
- **Action**: Move to `../market_maker/examples/delta_neutral_hedger.ex` and `../market_maker/test/examples/delta_neutral_hedger_test.exs`
- **Lines moved**: 271 + tests

### 🟡 Simplify (Medium Priority)

#### Task 3: Simplify DeribitGenServerAdapter
- **File**: `lib/websockex_adapter/examples/deribit_genserver_adapter.ex`
- **Current**: 339 lines, 17+ functions
- **Target**: <150 lines, 5 public functions
- **Purpose**: Keep as production-ready supervised pattern example
- **Changes**:
  - Extract RPC methods to shared module/data structure
  - Reduce public API to essentials:
    ```elixir
    - start_link/1
    - authenticate/1
    - subscribe/2
    - send_request/3
    - get_state/1
    ```
  - Simplify internal state management
  - Keep core monitoring/reconnection logic
  - Document as the "production pattern" for supervised connections

#### Task 4: Simplify DeribitAdapter
- **File**: `lib/websockex_adapter/examples/deribit_adapter.ex`
- **Current**: 307 lines, 30+ functions
- **Target**: <150 lines, 5 public functions
- **Changes**:
  ```elixir
  # Replace 20+ defrpc calls with data-driven approach
  @rpc_methods %{
    auth: "public/auth",
    subscribe: "public/subscribe",
    test: "public/test",
    set_heartbeat: "public/set_heartbeat",
    get_instruments: "public/get_instruments"
  }

  # Single RPC caller
  def call(adapter, method, params \\ %{})

  # Keep only essential functions
  - connect/1
  - authenticate/1
  - subscribe/2
  - call/3
  - close/1
  ```

#### Task 5: Simplify BatchSubscriptionManager
- **File**: `lib/websockex_adapter/examples/batch_subscription_manager.ex`
- **Current**: 242 lines, complex queue management
- **Target**: <100 lines, simple batching
- **Changes**:
  ```elixir
  # Remove status tracking
  # Simple chunk and delay approach
  def subscribe_batch(adapter, channels, batch_size \\ 10) do
    channels
    |> Enum.chunk_every(batch_size)
    |> Enum.each(fn batch ->
      DeribitAdapter.subscribe(adapter, batch)
      Process.sleep(200)  # Simple delay
    end)
  end
  ```

#### Task 6: Simplify SupervisedClient
- **File**: `lib/websockex_adapter/examples/supervised_client.ex`
- **Current**: 128 lines with health monitoring
- **Target**: <50 lines, supervision setup only
- **Changes**:
  - Remove health monitoring loop
  - Show basic supervisor setup
  - Link to supervision documentation

### 🟢 Keep As-Is (Low Priority)

#### Task 7: Preserve Simple Examples
- **Files**:
  - `adapter_supervisor.ex` (53 lines) ✅
  - `docs/basic_usage.ex` (48 lines) ✅
  - Other docs examples ✅
- **Reason**: Already follow simplicity principles

## New Examples to Add

### Task 8: Create Minimal Platform Adapter Template
```elixir
defmodule WebsockexAdapter.Examples.MinimalAdapter do
  @moduledoc """
  Template for creating platform adapters in <50 lines.
  Copy and modify for your specific platform.
  """

  defstruct [:client]

  def connect(url, opts \\ []) do
    case WebsockexAdapter.Client.connect(url, opts) do
      {:ok, client} -> {:ok, %__MODULE__{client: client}}
      error -> error
    end
  end

  def send_message(adapter, message) do
    WebsockexAdapter.Client.send_message(adapter.client, message)
  end

  def subscribe(adapter, channels) do
    # Platform-specific subscription format
    message = %{action: "subscribe", channels: channels}
    send_message(adapter, Jason.encode!(message))
  end

  def close(adapter) do
    WebsockexAdapter.Client.close(adapter.client)
  end
end
```

### Task 9: Reorganize Documentation Examples
The working examples already exist in `examples/docs/` with tests:
- `basic_usage.ex` ✅ (48 lines)
- `error_handling.ex` ✅ (proper patterns)
- `json_rpc_client.ex` ✅ (JSON-RPC patterns)
- `subscription_management.ex` ✅ (subscription patterns)

**Action**: Create an index/guide that references these existing working examples rather than creating new untested documentation.

## Implementation Order

1. **Week 1**: Remove business logic examples (Tasks 1-2)
2. **Week 2**: Simplify adapter examples (Tasks 3-4)
3. **Week 3**: Simplify remaining examples (Tasks 5-6)
4. **Week 4**: Add minimal templates and pattern docs (Tasks 8-9)

## Success Metrics

- No example exceeds 150 lines
- No module has more than 5 public functions
- All examples focus on infrastructure, not business logic
- Examples demonstrate patterns, not implementations
- Total example code reduced by 70%


## Review Checklist

- [ ] Each example has clear infrastructure purpose
- [ ] No business logic in any example
- [ ] All examples under 150 lines
- [ ] All modules have ≤5 public functions
- [ ] Examples show patterns, not implementations
- [ ] Documentation explains what was removed and why
- [ ] Migration paths provided for removed functionality
