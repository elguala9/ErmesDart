# SignalingContract Deployer Troubleshooting Report (2026-03-03)

## Problema
L'immagine Docker `elguala96/signaling-contract-deployer:v1.0.1` non completa il deploy del contratto:
- **Exit Code**: 1 (failure)
- **Duration**: ~10 secondi
- **Output**: Solo "🚀 Starting smart contract deployment..." poi silenzio

## Investigazione

### 1. Configurazione dell'Immagine
```
- Entrypoint: ./entrypoint.sh
- Base: Node.js 18.20.8
- Working Dir: /app
- Variabili di ambiente: RPC_URL, PRIVATE_KEY
```

### 2. Connectivity Test
✅ Ganache risponde correttamente:
```bash
curl http://localhost:9545 -d '{"jsonrpc":"2.0","method":"web3_clientVersion","id":1}'
# Response: {"id":1,"jsonrpc":"2.0","result":"Ganache/v7.9.2/..."}
```

### 3. RPC Trace su Ganache
Quando il deployer si avvia via docker-compose:
- Ganache riceve richieste RPC: eth_gasPrice, eth_getTransactionCount, eth_estimateGas
- **PERO'**: NON riceve `eth_sendRawTransaction` (il deploy non viene inviato)
- Questo suggerisce il deployer si blocca **PRIMA** di sendare la transazione

### 4. Errore Precedente
Quando il deployer era stato lanciato in docker-compose prima:
```
⚠️  Failed to deploy SignalingContract: RPCError: got code -32700 with msg "Invalid signature v value"
```
Questo è un errore di firma della transazione Ethereum:
- **-32700**: Parse error (ma il messaggio parla di "signature v value")
- Potrebbe essere incompatibilità tra versione di `web3.js`/`ethers.js` e Ganache

### 5. Comportamento Anomalo
- Il container termina senza stampare traceback o error message
- Il deployer si blocca silenziosamente dopo il primo messaggio
- Non produce log di debug su cosa sta facendo

## Possibili Root Cause

### A) Incompatibilità Versioni (LIKELY)
- Deployer usa versione vecchia di `web3.js` o `ethers.js`
- Ganache v7.9.2 potrebbe aver cambiato il formato della firma
- **Sintomo**: "Invalid signature v value" - significa il campo `v` della firma è invalido

### B) Problema di Compilazione
- Il deployer potrebbe bloccarsi compilando il contratto Solidity
- Manca un'uscita graceful se la compilazione fallisce

### C) Variabili d'Ambiente Non Riconosciute
- Potrebbe aspettarsi variabili diverse da RPC_URL/PRIVATE_KEY
- O potrebbe cercare un file di configurazione

### D) Network/DNS issue in Docker
- Se RPC_URL non è corretto per l'ambiente Docker
- Test: `http://host.docker.internal:9545` vs `http://parresia-contract-ganache:8545`

## Azioni Testate
1. ✅ Docker image pull - funziona
2. ✅ Docker run singolo - si avvia ma fallisce
3. ✅ Docker compose - si avvia ma fallisce
4. ✅ Variabili d'ambiente - ricevute correttamente
5. ❌ Connessione RPC - parziale (legge ma non scrive)
6. ❌ Firma transazione - codice "Invalid signature v value"

## Conclusione
**Il deployer ha un bug interno** - probabilmente incompatibilità di versione con Ganache 7.9.2.
Non è un problema della nostra configurazione (RPC_URL, PRIVATE_KEY, network).

## Soluzione Consigliata
1. **Contattare maintainer** del deployer per aggiornamento
2. **Alternativa**: Deployare il contratto manualmente via Dart script in setUp
3. **Workaround**: Disabilitare deployer nel docker-compose e deployare manualmente