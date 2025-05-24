# Deribit API Documentation

## Introduction

This documentation describes the Deribit API v2.1.1. The Deribit API provides three different interfaces to access the API:

- JSON-RPC over WebSocket (preferred)
- JSON-RPC over HTTP
- FIX (Financial Information eXchange)

For detailed information about each interface and general API concepts, start with the [Overview](overview.md).

## API Sections

The Deribit API functionality is divided into the following sections:

1. [**Overview**](overview.md) - General API information, naming conventions, and rate limits
2. [**JSON-RPC**](json_rpc.md) - Detailed information about the JSON-RPC protocol implementation
3. [**Authentication**](authentication.md) - Methods for authentication and token management
4. [**Session Management**](session_management.md) - Methods for managing API sessions and heartbeats
5. [**Supporting**](supporting.md) - Utility methods for testing and status checking
6. [**Subscription Management**](subscription_management.md) - Methods for managing WebSocket subscriptions
7. [**Market Data**](market_data.md) - Methods for retrieving market data (orderbooks, trades, etc.)
8. [**Trading**](trading.md) - Methods for trading (buy, sell, edit, cancel, etc.)
9. [**Combo Books**](combo_books.md) - Methods for working with combination instruments
10. [**Block Trade**](block_trade.md) - Methods for executing block trades
11. [**Block RFQ**](block_rfq.md) - Methods for Request for Quote functionality
12. [**Wallet**](wallet.md) - Methods for wallet operations (deposits, withdrawals, transfers)
13. [**Account Management**](account_management.md) - Methods for account and position information
14. [**Subscriptions**](subscriptions.md) - Available subscription channels for WebSocket

## Usage Notes

- Deribit features a testing environment, `test.deribit.com`, which can be used to test the API
- The production environment is located at `www.deribit.com`
- Test and production environments are completely separate and require different credentials
- To see your API keys, check **Account > API** tab on the Deribit website
- Most API calls have request limits which are described in the [Rate Limits](overview.md#rate-limits) section

## API Endpoints

- **Test Environment (Testnet)**: 
  - WebSocket: wss://test.deribit.com/ws/api/v2/
  - HTTP: https://test.deribit.com/api/v2/

- **Production Environment**:
  - WebSocket: wss://www.deribit.com/ws/api/v2/
  - HTTP: https://www.deribit.com/api/v2/

## Authentication

Before accessing private methods, you need to authenticate with your API credentials. See the [Authentication](authentication.md) section for detailed information.

## WebSocket vs HTTP

While both WebSocket and HTTP interfaces provide access to the same methods, WebSocket offers several advantages:

- Lower latency due to persistent connection
- Subscription functionality for real-time updates
- Better handling of rate limiting
- Lower overhead for multiple requests

For these reasons, the WebSocket interface is recommended for most use cases, especially for trading applications.

## Error Handling

The API uses standard JSON-RPC error handling with specific error codes. See the [JSON-RPC](json_rpc.md#response-messages) section for more information on error responses.

## Further Resources

For additional help and examples, please refer to:

- [Deribit API Console](https://test.deribit.com/api-console) - Interactive API testing tool
- [Deribit Support](https://support.deribit.com) - Support portal with additional documentation
- [Deribit GitHub](https://github.com/deribit) - Official code samples and libraries