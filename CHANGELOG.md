# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-11-21

### Added

#### Core Features
- **Dual transport support**: WebSocket and Socket.IO
- **Robust connection management**: Automatic reconnect with exponential backoff and jitter
- **Persistent message queue**: SQLite-based queue for offline message storage
- **Ordered delivery**: Monotonic sequence numbers for message ordering
- **Acknowledgement protocol**: Server ACK with sequence numbers
- **Resume protocol**: Client can resume from last ACK after reconnect
- **Idempotency keys**: UUID-based deduplication
- **Network awareness**: Connectivity detection and auto-reconnect

#### Delivery Strategies
- At-most-once delivery
- At-least-once delivery (default)
- Best-effort ordered delivery

#### Authentication
- Token-based authentication (Bearer)
- Pluggable token refresh handler
- Secure storage integration (`flutter_secure_storage`)

#### Advanced Features
- **Presence management**: Track user online/offline/away/busy status
- **Typing indicators**: Auto-expiring typing status with configurable timeout
- **Read receipts**: Message read tracking
- **Metrics & observability**: Comprehensive metrics for monitoring
  - Connection lifecycle tracking
  - Message counts (sent, received, acked)
  - Queue size monitoring
  - Error tracking
  - Average reconnect time

#### Configuration
- Configurable retry delays and max retries
- Configurable heartbeat interval and timeout
- TLS enforcement option
- Message batching support
- Logging level configuration

#### Developer Experience
- Strongly-typed event streams
- RxDart integration for reactive programming
- Comprehensive error handling
- Detailed logging

### Documentation
- Complete README with use cases and examples
- Design notes and architecture documentation
- API documentation
- Server implementation examples (Node.js)
- Example Flutter app demonstrating all features

### Testing
- Unit tests for core functionality
- Integration test support
- Mock-friendly architecture

### Server Examples
- Socket.IO server implementation
- WebSocket server implementation
- ACK and resume protocol implementation

## [Unreleased]

### Planned Features
- Message chunking for large payloads
- Compression support (gzip/brotli)
- Binary protocol option (Protobuf/MessagePack)
- Multi-transport fallback
- Message priority queue
- Selective ACK (SACK)
- Flow control
- Server-side SDKs (Python, Go, Java)
- End-to-end encryption helpers
- Performance optimizations
- More comprehensive integration tests

---

[0.0.1]: https://github.com/example/realtime_client/releases/tag/v0.0.1
