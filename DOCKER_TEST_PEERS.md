# Docker Test Peer Network - ErmesDart

Un ambiente di test Docker completo che simula una rete peer-to-peer decentralizzata con STUN e blockchain per test reali del NAT traversal.

**Status**: ✅ **FULLY FUNCTIONAL** - Tutti i 5 messaggi consegnati correttamente tra peer (2026-04-08)

## Architettura

La rete comprende 4 container + 1 deployer:

```
docker-compose-test-peers.yml
├── ganache            (Ethereum blockchain EVM - porta 9545)
├── stun-server        (STUN server coturn - porta 3478 UDP)
├── peer-alice         (Dart app - Alice, account 0 Hardhat)
├── peer-bob           (Dart app - Bob, account 1 Hardhat)
└── contract-deployer  (one-shot, deploya SignalingContract)

Network: ermes-peers-network (bridge Docker)
```

## Avvio

```bash
cd C:\Users\lgualandi\Documents\Development\Parresia\ErmesDart

# Build e avvia la rete di test completa
docker compose -f docker-compose-test-peers.yml up --build

# Stop
docker compose -f docker-compose-test-peers.yml down
```

## Test Results (2026-04-08)

**Alice** (Sender, IS_INITIATOR=true):
- ✅ Connessione a Ganache (retry after 1 attempt)
- ✅ Creazione segnale con IP Docker: `172.22.0.5:9001`
- ✅ Opening connection a Bob
- ✅ Invio di 5 messaggi

**Bob** (Receiver, IS_INITIATOR=false):
- ✅ Connessione a Ganache (retry after 1 attempt)  
- ✅ Creazione segnale con IP Docker: `172.22.0.6:9002`
- ✅ Opening connection a Alice
- ✅ **Ricezione di 5/5 messaggi**:
  ```
  ✅ Message 0: [Alice] Message 0: 2026-04-08 18:33:15.260368
  ✅ Message 1: [Alice] Message 1: 2026-04-08 18:33:15.764386
  ✅ Message 2: [Alice] Message 2: 2026-04-08 18:33:16.265361
  ✅ Message 3: [Alice] Message 3: 2026-04-08 18:33:16.766423
  ✅ Message 4: [Alice] Message 4: 2026-04-08 18:33:17.267402
  ```

## Cosa Succede

1. **Ganache** si avvia e diventa healthy (porta 9545)
2. **STUN server** (coturn) si avvia sulla porta 3478 UDP
3. **Contract deployer** deploya il SignalingContract a `0x5FbDB2315678afecb367f032d93F642f64180aa3`
4. **Peer Alice** (account 0) e **Peer Bob** (account 1) si avviano e:
   - Si connettono a Ganache
   - Creano istanze OrcErmes
   - Scoprano i loro indirizzi pubblici tramite STUN
   - Postano i segnali sulla blockchain
   - Attendono il segnale del peer remoto (polling)
   - Aprono connessioni peer-to-peer
   - Scambiano messaggi

## File Chiave

| File | Descrizione |
|------|-------------|
| `docker-compose-test-peers.yml` | Docker Compose file con la configurazione di rete |
| `Dockerfile.peer` | Multi-stage Dockerfile per build Dart dei peer |
| `packages/ermes_peer_node/` | Package Dart standalone per il peer node |
| `packages/ermes_peer_node/bin/main.dart` | Logica completa del peer app |

## Variabili di Ambiente dei Peer

Ogni peer riceve queste variabili di ambiente:

```
MY_PRIVATE_KEY        # Chiave privata Ethereum (account 0 o 1)
MY_ADDRESS            # Indirizzo Ethereum del peer
REMOTE_ADDRESS        # Indirizzo Ethereum del peer remoto
GANACHE_URL           # URL di Ganache (http://ganache:8545)
CONTRACT_ADDRESS      # Indirizzo del SignalingContract deploiato
STUN_SERVER           # Hostname del server STUN (stun-server)
STUN_PORT             # Porta STUN (3478)
IS_INITIATOR          # true/false - chi invia messaggi per primo
MESSAGE_COUNT         # Quanti messaggi inviare (default 5)
PEER_NAME             # Alice o Bob - per logging
```

## Account Hardhat Standard

| Account | Indirizzo | Chiave Privata |
|---------|-----------|----------------|
| 0 (Alice) | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` |
| 1 (Bob)   | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` |

## Troubleshooting

### Ganache non diventa healthy
- Aspetta ~30-40 secondi, il health check ha un timeout lungo
- Controlla: `docker logs ermes-test-ganache`

### Peer non partono
- Verifica che Ganache sia healthy: `docker ps`
- I peer hanno dipendenza da `ganache:service_started` nel compose

### Port già in uso
```bash
# Libera le porte
docker compose -f docker-compose-test-peers.yml down -v
docker system prune -a
```

### STUN fallisce
- Assicurati che UDP 3478 sia disponibile
- Controlla coturn: `docker logs ermes-test-stun-server`

## Flusso Temporale Tipico (Post-Fix)

```
t=0s     ganache + stun + deployer partono
t=5-10s  deployer completa il deploy
t=10s    peer-alice e peer-bob partono
t=12-15s Alice scopre IP via Platform.localHostname (fallback STUN)
t=12-15s Bob scopre IP via Platform.localHostname (fallback STUN)
t=15s    Alice posta segnale (con porta 9001)
t=15s    Bob posta segnale (con porta 9002)
t=16s    Alice legge segnale Bob, openConnection()
t=16s    Bob legge segnale Alice, openConnection()
t=17s    SHSP handshake completato su entrambi
t=19s    Alice (initiator=true) aspetta 2 secondi per peer ready
t=21s    Alice invia 5 messaggi (Message 0-4)
t=21-23s Bob riceve tutti i 5 messaggi su porta 9002
t=50s    Container si fermano (timeout)
```

## Stato Attuale (2026-04-08)

### ✅ Working
- Ganache blockchain RPC con retry
- SignalingContract deployment
- STUN fallback hostname resolution (container IPs: 172.22.x.x)
- Scambio segnali blockchain tra peer
- SHSP socket initialization con porta fissa
- Connection handshake (peer riconosce sé stesso e il peer remoto)
- **✅ Message delivery** - Tutti i messaggi consegnati correttamente tra peer

### ✅ Issues Risolti (Commit 2026-04-08)

**Bug 1: IP sbagliato nel fallback STUN**
- ✅ Cambiato da `localhost` (127.0.0.1) a `Platform.localHostname` (container IP reale)
- ✅ File: `ermes_signaling_handler.dart` riga 89-90

**Bug 2: Porta hardcodata 9000**
- ✅ Aggiunto parametro `_overridePort` a `ErmesSignalingHandler`
- ✅ Passato `LOCAL_SHSP_PORT` da env vars (Alice:9001, Bob:9002)
- ✅ File: `orc_ermes_advanced_factory.dart`, `ermes_signaling_handler.dart`

**Bug 3: Ordine sbagliato e codice duplicato**
- ✅ Spostato `onMessage` callback PRIMA di `openConnection()`
- ✅ Invertito ordine in `openConnection()`: posta segnale PRIMA di leggere quello remoto
- ✅ Rimosso codice manuale di STUN/signaling/polling da main.dart
- ✅ File: `main.dart`, `orc_ermes.dart`

**Bug 4: coturn non configurato**
- ✅ Aggiunto comando coturn con `--no-auth --listening-ip=0.0.0.0`
- ✅ File: `docker-compose-test-peers.yml`

**Timing issue: Primo messaggio non ricevuto**
- ✅ Aggiunto delay di 2 secondi dopo `openConnection()` per completare handshake
- ✅ File: `ermes_peer_node/bin/main.dart`

**Bonus: Robustness migliorata**
- ✅ Retry 30x per connessione Ganache (attendere healthcheck)
- ✅ Logging STUN fallback con hostname e porta
- ✅ Error handling nei send/cleanup

## Limitazioni Attuali

- **Network Bridge Docker**: I container comunicano direttamente (nessun NAT tra container)
  - Per simulare NAT completo, aggiungere reti separate + container router con iptables
- **STUN in Container**: Fallback a hostname resolution Docker (non usa coturn per IP discovery, solo come NAT traversal reference)
- **Crittografia**: Abilitata di default (AES-256 con ECDH key exchange)
- **Retransmissione**: Implementata con timer e ACK

## Estensioni Possibili

1. **Aggiungere NAT reale**: Usare network separate + container router con iptables
2. **Metrics**: Aggiungere Prometheus per monitorare latenza e throughput
3. **Chaos Engineering**: Aggiungere container che dropp pacchetti / simula latenza
4. **Scalability**: Aumentare da 2 a N peer, testare decentralizzazione
5. **Stress Test**: Inviare KB/s di data, misurare throughput e loss

## Note Tecniche

- **OrcErmes**: Facade façade di alto livello che gestisce N peer connections
- **ErmesRepository**: Implementa il SHSP handshake, gestisce UDP socket
- **ErmesSignalingServer**: Interfaccia blockchain, stoca/recupera segnali
- **StunShspHandlerSingleton**: Singleton globale per STUN + socket SHSP
- **SignalingContract**: Smart contract Solidity che stoca segnali per-account (gzip-compressed)
