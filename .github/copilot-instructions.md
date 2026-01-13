# Copilot Instructions - Development Standards

## Package Management
- Utilizza sempre **npm** per la gestione dei pacchetti

## .NET Standards
- Usare sempre l'**ultima versione di .NET**

## Architecture & Design Patterns

### Interfacce e Classi
- Le classi devono implementare delle **interface**
- I tipi stanno nel progetto delle interfacce
- Se i tipi sono numerosi, creare un **progetto dedicato** per loro

### Dart
- In Dart, sia le **abstract class** che le **interface class** sono considerate interfacce

### Project Structure
- Utilizzare sempre il path:  `repository` → `service`
- Se richiesto, aggiungere anche `upper service`

### UpperService Pattern
- **UpperService** è una classe che riceve in input: 
  - `service` (il servizio principale)
  - `service before` (operazioni preliminari)
  - `service after` (operazioni finali)
- In ogni metodo: 
  - I metodi di `before` vengono chiamati **prima**
  - Viene eseguito il metodo principale
  - I metodi di `after` vengono chiamati **dopo**
- Di base sono **vuoti**, ma possono essere implementati a bisogno

## Testing Strategy
- I **test devono essere in un progetto separato** dedicato
- I test devono essere scritti sulle **interfacce**, non sulle implementazioni
- Nei progetti di implementazione, è presente **solo un riferimento ai test**
- Questo riferimento chiama i test sviluppati con le interfacce usando le classi concrete
- Fare sia test per verificare il funzionamento corretto che test per i casi di errore
- Fare sempre test sulla consistenza dei dati, input e output

## Code Quality Standards

### Exception Handling
- **Evitare `try-catch` eccessivi** - utilizzarli solo quando strettamente necessario
- Non utilizzare il tipo `null` - in caso di valore assente, **lanciare un'eccezione**

### Mocking
- **Non usare mock** a meno che non sia esplicitamente richiesto

### Naming Conventions
- Seguire la **naming convention del linguaggio utilizzato** nel progetto
  - C#: PascalCase per classi e metodi, camelCase per variabili
  - JavaScript/TypeScript: camelCase per variabili e funzioni, PascalCase per classi
  - Dart: camelCase per variabili e funzioni, PascalCase per classi
  - etc.

## Summary
Questi standard garantiscono:
- ✅ Coerenza architettonica tra i vari progetti
- ✅ Testabilità attraverso interfacce
- ✅ Manutenibilità e scalabilità
- ✅ Qualità del codice
- ✅ Separazione delle responsabilità