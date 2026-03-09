# STUN Handler Update

**Date**: 2026-03-09

## Key Changes
- **stun**: Updated to ^1.2.0
- **Requirement**: Must use `StunHandlerSingleton` exclusively
- **Priority**: Always prioritize IPv6 over IPv4

## Usage Pattern
When working with STUN functionality:
1. Always use `StunHandlerSingleton` (not individual StunHandler instances)
2. Configure with IPv6 priority enabled
3. Applies to all STUN-based peer discovery and NAT traversal

## Implementation ✅ COMPLETED

**Changes Made**:
1. **stun_handler_factory_helper.dart**:
   - `_initializeDefault()`: Changed from `InternetAddress.anyIPv4` → `InternetAddress.anyIPv6`
   - `_initializeDefault()`: Changed `_ipv6 = false` → `_ipv6 = true`
   - `configure()`: Changed default parameter from `ipv6 = false` → `ipv6 = true`

2. **orc_ermes_advanced_factory.dart**:
   - `createWithCustomStun()`: Now explicitly calls `ipv6: true` (line 100)
   - `createWithRpc()`: Now explicitly calls `ipv6: true` (line 139)
   - `createForTesting()`: Now explicitly calls `ipv6: true` (line 172)
   - `createWithIPv6()`: Already had `ipv6: true` ✓

**Result**: StunHandlerSingleton now defaults to IPv6 across all factory methods, with explicit clarity in the code
