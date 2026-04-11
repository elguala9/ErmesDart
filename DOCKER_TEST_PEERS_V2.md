# Docker Test Peer Network - ErmesDart v2 (JSON-Driven)

**Status**: ✅ **FULLY CONFIGURABLE** - 4-peer all-to-all topology via JSON config (2026-04-08)

## Novità nella v2

- **4 peer** (Alice, Bob, Charlie, Dave) invece di 2
- **All-to-all topology**: tutti i 4 peer si scambiano messaggi (12 coppie direzionali × 3 messaggi = 36 totali)
- **JSON config file**: tutti i messaggi, timing, network params sono in `test_config.json`
- **Volume mount**: l'utente edita il JSON localmente senza rebuild
- **Messaggi strutturati**: ogni messaggio è JSON con `id`, `from`, `to`, `content`, `sequence`
- **Verifica 3-livelli**: routing check (messaggio inviato al peer giusto) + sender check (identità verificata) + completeness check

## Architettura

```
docker-compose-test-peers.yml
├── ganache              (Ethereum blockchain EVM - porta 9545)
├── stun-server          (STUN server coturn - porta 3478 UDP)
├── peer-alice           (Dart app - account 0)
├── peer-bob             (Dart app - account 1)
├── peer-charlie         (Dart app - account 2)  [NUOVO]
├── peer-dave            (Dart app - account 3)  [NUOVO]
└── contract-deployer    (one-shot, deploya SignalingContract)

Network: ermes-peers-network (bridge Docker)
Volume: ./packages/ermes_peer_node/config → /app/config:ro
```

## Avvio

```bash
cd C:\Users\lgualandi\Documents\Development\Parresia\ErmesDart

# Build e avvia la rete di test completa (4 peer)
docker compose -f docker-compose-test-peers.yml up --build

# Stop
docker compose -f docker-compose-test-peers.yml down
```

## File di Configurazione

### `packages/ermes_peer_node/config/test_config.json`

Struttura:

```json
{
  "network": {
    "ganache_url": "http://ganache:8545",
    "contract_address": "0x5FbDB2315678afecb367f032d93F642f64180aa3",
    "stun_server": "stun-server",
    "stun_port": 3478,
    "ganache_retry_count": 30,
    "ganache_retry_delay_seconds": 2,
    "post_connection_delay_seconds": 2,
    "message_interval_ms": 500,
    "keepalive_seconds": 60
  },
  "peers": [
    { "name": "Alice", "address": "0xf39fd...", "private_key": "0xac09...", "shsp_port": 9001 },
    { "name": "Bob", "address": "0x7099...", "private_key": "0x59c6...", "shsp_port": 9002 },
    { "name": "Charlie", "address": "0x3c44...", "private_key": "0x5de4...", "shsp_port": 9003 },
    { "name": "Dave", "address": "0x90f7...", "private_key": "0x7c85...", "shsp_port": 9004 }
  ],
  "scenarios": [
    { "id": "msg-ab-1", "from": "0xf39fd...", "to": "0x70997...", "content": "Alice→Bob message 1", "sequence": 0 },
    { "id": "msg-ab-2", "from": "0xf39fd...", "to": "0x70997...", "content": "Alice→Bob message 2", "sequence": 1 },
    // ... 36 messaggi totali (3 per ogni coppia direzionale)
  ]
}
```

### Cosa puoi modificare

| Campo | Dove | Effetto |
|-------|------|--------|
| `network.ganache_url` | JSON | URL connessione Ganache |
| `network.stun_server` | JSON | Hostname STUN |
| `network.message_interval_ms` | JSON | Delay tra messaggi (ms) |
| `network.keepalive_seconds` | JSON | Timeout ricezione messaggi (s) |
| `peers[].shsp_port` | JSON | Porta SHSP locale per peer |
| `scenarios[]` | JSON | Aggiungi/rimuovi/modifica messaggi |

Non è necessario rebuild Docker — basta editare il JSON e riavviare i container.

## Formato Messaggi (Wire)

Ogni messaggio inviato su P2P è JSON UTF-8:

```json
{
  "id": "msg-ab-1",
  "from": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
  "to": "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
  "content": "Alice→Bob message 1",
  "sequence": 0
}
```

Il **receiver** decodifica il JSON e verifica:
1. **routing**: `payload.to` deve essere il suo indirizzo
2. **identità**: `payload.from` deve corrispondere al sender ID registrato in OrcErmes
3. **integrità**: l'ID è stabile e tracciabile nei log

## Exit Code e Verifica

Ogni peer container ritorna:
- `0` = ✅ Tutti i messaggi attesi ricevuti, nessun errore
- `1` = ❌ Messaggi mancanti, misdirected, spoofed, o invio fallito

### Controllare exit codes

```bash
# Dopo che i container terminano (naturalmente dopo 60s keepalive)
docker inspect ermes-test-peer-alice --format='{{.State.ExitCode}}'
docker inspect ermes-test-peer-bob --format='{{.State.ExitCode}}'
docker inspect ermes-test-peer-charlie --format='{{.State.ExitCode}}'
docker inspect ermes-test-peer-dave --format='{{.State.ExitCode}}'

# Successo: tutti ritornano 0
```

## Nei Log Cosa Cercare

Ogni peer stampa:
- `[PeerName] ✅ SENT id=...` per ogni messaggio inviato
- `[PeerName] ✅ RECEIVED id=...` per ogni messaggio ricevuto
- `[PeerName] MISDIRECTED msg id=...` se un messaggio non era per lui
- `[PeerName] SPOOFED msg id=...` se il sender non corrisponde
- `[PeerName] === VERIFICATION SUMMARY ===` con statistiche finali
- `[PeerName] ✅ ALL CHECKS PASSED` se tutto OK

Esempio output Alice:

```
[Alice] Starting — address: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
[Alice] Connected to Ganache
[Alice] Opening 3 connections...
[Alice] Connecting to Bob (0x70997970c51812dc3a010c7d01b50e0d17dc79c8)...
[Alice] Connected to Bob
[Alice] Connecting to Charlie (0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc)...
[Alice] Connected to Charlie
[Alice] Connecting to Dave (0x90f79bf6eb2c4f870365e785982e1f101e93b906)...
[Alice] Connected to Dave
[Alice] Waiting 2s for handshakes...
[Alice] Sending 9 messages...
[Alice] ✅ SENT id=msg-ab-1 to=0x70997970c51812dc3a010c7d01b50e0d17dc79c8 seq=0
[Alice] ✅ SENT id=msg-ab-2 to=0x70997970c51812dc3a010c7d01b50e0d17dc79c8 seq=1
[Alice] ✅ SENT id=msg-ab-3 to=0x70997970c51812dc3a010c7d01b50e0d17dc79c8 seq=2
[Alice] ✅ SENT id=msg-ac-1 to=0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc seq=0
[Alice] ✅ SENT id=msg-ac-2 to=0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc seq=1
[Alice] ✅ SENT id=msg-ac-3 to=0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc seq=2
[Alice] ✅ SENT id=msg-ad-1 to=0x90f79bf6eb2c4f870365e785982e1f101e93b906 seq=0
[Alice] ✅ SENT id=msg-ad-2 to=0x90f79bf6eb2c4f870365e785982e1f101e93b906 seq=1
[Alice] ✅ SENT id=msg-ad-3 to=0x90f79bf6eb2c4f870365e785982e1f101e93b906 seq=2
[Alice] Waiting up to 60s for inbound messages...
[Alice] ✅ RECEIVED id=msg-ba-1 from=0x70997970c51812dc3a010c7d01b50e0d17dc79c8 seq=0: Bob→Alice message 1
[Alice] ✅ RECEIVED id=msg-ba-2 from=0x70997970c51812dc3a010c7d01b50e0d17dc79c8 seq=1: Bob→Alice message 2
[Alice] ✅ RECEIVED id=msg-ba-3 from=0x70997970c51812dc3a010c7d01b50e0d17dc79c8 seq=2: Bob→Alice message 3
[Alice] ✅ RECEIVED id=msg-ca-1 from=0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc seq=0: Charlie→Alice message 1
[Alice] ✅ RECEIVED id=msg-ca-2 from=0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc seq=1: Charlie→Alice message 2
[Alice] ✅ RECEIVED id=msg-ca-3 from=0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc seq=2: Charlie→Alice message 3
[Alice] ✅ RECEIVED id=msg-da-1 from=0x90f79bf6eb2c4f870365e785982e1f101e93b906 seq=0: Dave→Alice message 1
[Alice] ✅ RECEIVED id=msg-da-2 from=0x90f79bf6eb2c4f870365e785982e1f101e93b906 seq=1: Dave→Alice message 2
[Alice] ✅ RECEIVED id=msg-da-3 from=0x90f79bf6eb2c4f870365e785982e1f101e93b906 seq=2: Dave→Alice message 3
[Alice] === VERIFICATION SUMMARY ===
[Alice] Expected: 9 messages
[Alice] Received: 9 messages
[Alice] ✅ ALL CHECKS PASSED
```

## Scenari di Test Personalizzati

### Aggiungere messaggi

Editare `test_config.json` nella sezione `scenarios`:

```json
{
  "id": "msg-custom-1",
  "from": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
  "to": "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
  "content": "Custom test message",
  "sequence": 10
}
```

### Rimuovere peer

Commentare il service in `docker-compose-test-peers.yml` e rimuovere i suo messaggi dal JSON.

### Testare errori (misdirection)

Creare uno scenario con un `to` sbagliato:

```json
{
  "id": "msg-evil-1",
  "from": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
  "to": "0x90f79bf6eb2c4f870365e785982e1f101e93b906",  // Dave
  "content": "Intended for Bob but goes to Dave",
  "sequence": 0
}
```

Dave riceverà il messaggio e stamperà `MISDIRECTED` perché il `to` non corrisponde. Exit code = 1.

## Account Hardhat Standard

| Account | Indirizzo | Chiave Privata | Port |
|---------|-----------|----------------|------|
| 0 (Alice) | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` | 9001 |
| 1 (Bob) | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` | 9002 |
| 2 (Charlie) | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a` | 9003 |
| 3 (Dave) | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | `0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6` | 9004 |

## Flusso Temporale Tipico

```
t=0s     ganache + stun + deployer partono
t=5-10s  deployer completa il deploy
t=10s    peer-alice, peer-bob, peer-charlie, peer-dave partono
t=12-15s Tutti i 4 peer scoprono IP via STUN/hostname fallback
t=15s    Tutti i 4 peer postano segnali sulla blockchain
t=16-20s Handshake SHSP tra tutti i peer
t=21s    Tutti i 4 peer iniziano a inviare messaggi
t=21-30s 36 messaggi consegnati (36 × 500ms ≈ 18s + network delay)
t=30-60s Keepalive window: peer ricevono i messaggi rimanenti
t=60s    Timeout keepalive, exit code verificato
```

## Troubleshooting

### Ganache non diventa healthy
- Aspetta ~30-40 secondi, il health check ha timeout lungo
- Controlla: `docker logs ermes-test-ganache`

### Peer non partono
- Verifica che Ganache sia healthy: `docker ps`
- Controlla: `docker logs ermes-test-peer-alice` ecc.

### Messaggi mancanti
- Verifica che il JSON sia valido: `docker compose config`
- Controlla i log di ogni peer per `MISDIRECTED` o `SPOOFED`

### Port già in uso
```bash
docker compose -f docker-compose-test-peers.yml down -v
docker system prune -a
```

### Limpiare e ricominciare
```bash
docker compose -f docker-compose-test-peers.yml down
docker system prune -a
docker compose -f docker-compose-test-peers.yml up --build
```

## Estensioni Possibili

1. **Sequence validation**: Aggiungere check per rilevare messaggi fuori ordine
2. **Metrics**: Aggiungere Prometheus per latenza e throughput
3. **Chaos testing**: Aggiungere delay/packet loss tra peer
4. **Scalability**: N peer, topology fully connected o custom
5. **Stress test**: KB/s di data, throughput test
6. **Custom handlers**: Estendere verifica payload (e.g. checksum, encryption)

## Note Tecniche

- **OrcErmes**: Facade che gestisce N peer connections simultanee
- **Wire format**: JSON UTF-8 per ogni messaggio (human-readable nei logs)
- **Address normalization**: Tutti gli indirizzi sono lowercase
- **Storage**: Singleton per-processo, isolato tra container
- **Volume mount**: Config read-only (`:ro`), non modificabile dai peer
