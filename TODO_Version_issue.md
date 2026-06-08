# Dependency Version Conflict: `pointycastle`

## Problem

`nostr_signaling 0.2.0` dipende da `dart_nostr ^10.0.1` che dipende da `bip39 ^1.0.6`.
`bip39 1.0.6` (pubblicato 5 anni fa) richiede `pointycastle ^3.0.0-nullsafety.2`.

`cryptdart 0.2.0` (usato da `ermes_signaling`, `ermes_core`, `ermes_core_init`, ecc.) richiede `pointycastle ^4.0.0`.

Le due constraint sono incompatibili: `^3.0.0-nullsafety.2` richiede `<4.0.0`, mentre `^4.0.0` richiede `>=4.0.0`.

## Current Solution

In `pubspec.yaml` (workspace root) usiamo `dependency_overrides` per forzare `pointycastle: 4.0.0`:

```yaml
dependency_overrides:
  pointycastle: 4.0.0
```

`bip39` funziona correttamente con `pointycastle 4.x` nonostante il constraint vecchio, perché le API crittografiche di base non sono cambiate tra le major version.

## How to Fix Properly

Il fix ideale è che `bip39` pubblichi una nuova versione che aggiorni il constraint a `pointycastle: '>=3.0.0 <5.0.0'` (o simile).

Opzioni per risolvere definitivamente:

1. **Fork e publish di bip39** — Fare un fork di `bip39`, aggiornare il constraint in `pubspec.yaml`, pubblicare su pub.dev.
2. **Contribuire a bip39 upstream** — Aprire una PR su https://github.com/anicdh/bip39 per aggiornare il constraint.
3. **Rimpiazzare bip39 in dart_nostr** — Se `dart_nostr` upstream rimuove la dipendenza da `bip39`, il problema sparisce.
4. **Rimpiazzare cryptdart** — Se `cryptdart` abbassasse il constraint a `pointycastle: '>=3.0.0'` (ma perderebbe feature 4.x).
5. **Usare un fork alternativo di bip39** — Cercare su pub.dev se esiste un fork mantenuto.

## Track

- [ ] Rimuovere `pointycastle: 4.0.0` da `dependency_overrides` in `pubspec.yaml`
- [ ] Aggiornare `TODO_Version_issue.md` quando risolto
