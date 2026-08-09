# TODO

## Remove path-based dependency_overrides once packages are published

`pubspec.yaml` (root) currently overrides these deps with local sibling-repo
paths instead of pub.dev versions:

- `shsp` -> `../SingleHandShakeProtocolDart/packages/shsp`
- `stun` -> `../StunDart/packages/stun`
- `stun_shsp` -> `../StunShspDart/packages/stun_shsp`
- `nostr_signaling` -> `../NostrSignaling/packages/nostr_signaling`
- `callback_handler` -> `../CallbackHandlerDart/packages/callback_handler`

Once each package has a published version on pub.dev matching what's in
`pubspec.yaml` dependencies, remove its entry from `dependency_overrides`.

**Also update when removing an override:**
- Every `.github/workflows/nat-*.yml` file checks out the matching sibling
  repo (`Checkout SHSP`, `Checkout CallbackHandlerDart`, etc.) so the path
  override resolves in CI. Remove the corresponding checkout step once that
  override is gone, otherwise it's just dead CI time.

## Other known TODOs

- `pointycastle` pinned to `4.0.0` in `dependency_overrides` — remove once
  `bip39` (a `dart_nostr` dependency) supports `pointycastle >=4.0.0`.
