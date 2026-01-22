# Copilot Instructions - Development Standards
Ciò che è scritto in questo file è legge e va sempre rispettato, solo se l'utente può autorizzarti a ignorare una di queste regole

## Package Management
- Utilizza sempre **npm** per la gestione dei pacchetti typescript/javascript
- Utilizza sempre **pub.dev** per la gestione dei pacchetti Dart

## .NET Standards
- Usare sempre l'**ultima versione di .NET**

## Architecture & Design Patterns
- Nella cartella .guide della root verranno inserite delle guide per pacchetti esterni o pattern da seguire

### Interfacce e Classi
- Le classi devono implementare delle **interface**
- I tipi stanno nel progetto delle interfacce
- Se i tipi sono numerosi, creare un **progetto dedicato** per loro

### Dart
- In Dart, sia le **abstract class** che le **interface class** sono considerate interfacce
- non usare dynamic
- non usare as
- preferire il costruttore factory per le implementazioni delle interfacce
- fare codice sempre fortemente tipizzato


### Project Structure
- Utilizzare sempre il path:  `repository` → `service`
- Se richiesto, aggiungere anche `upper service`
- Usa monorepo il più possibile
- Gli unici .md sono Readme e Changelog
- Le interfacce non stanno mai con le implementazioni, sono in un pacchetto a parte
- Le intefacce stanno in un pacchetto dedicato
- Le inmplementazioni possono stare in più pacchetti, ma mai con le interfacce
- Le implementazioni devono sempre fare riferimento alle interfacce, mai il contrario

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
- I test devono essere scritti sulle **interfacce**, non sulle implementazioni. Non deve mai esserci una implementazione nei test
- I test devono essere richimabili, come delle funzioni, per essere eseguiti su qualsiasi implementazione dell'interfaccia
- Nei progetti di implementazione, non sono mai presenti test
- Per testare una classe, crea un file in cui scrivi la chiamata ai test della interfaccia da cui quella classe eredita
- Fare sia test per verificare il funzionamento corretto che test per i casi di errore
- Fare sempre test sulla consistenza dei dati, input e output
- Si creano sempre tutti i test delle classi/interfacce
- I test di una classe devono essere indipendenti dalle altre classi
- Mai usare mock senza esplicito permesso
- Usare nomi chiari per i test, che spieghino cosa viene testato
- I test DEVONO sempre pasare al 100% a meno che non specificato diversamente
- Le factory devono essere sempre testate
- Tutti i metodi di tutte le classi devono essere testate
- Le dipendenze delle varie classi devono essere soddisfatte senza usare mock
- Ogni classe deve avere una factory anche se non utilizzataù
- Non usare mai try catch nei test

## Testing TypeScript
- Usare sempre ts-mocha
- I file di test devono essere lanciati con ts-mocha

## Factory Pattern
- Ogni classe deve avere una factory dedicata
- Le factory devono essere sempre testate
- La factory ha in input una classe che termina con "Input" che contiene tutti i parametri necessari per creare l'istanza della classe
- La factory deve creare l'istanza della classe e restituirla
- Le factory devono usare il polimorfismo per creare l'isntaza con input differenti

## Code Quality Standards
- Riusa più codice possibile
- Ricordati che il codice deve essere **manutenibile e scalabile**
- Esiste la ereditarietà - usala per evitare duplicazioni
- Dividi sempre il problema in sotto problemi
- Escludendo i test - evita file più lunghi di 150 righe, in caso di frontend 200 righe
- Funzioni/metodi non più lunghi di 30 righe
- Usare oggetti come input nei costruttori delle classi
- 0 errori nel codice e 0 warning
- I commenti fatti dall'ia devono essere segnalati come tali nel codice
- Il codice generato dall'ia deve essere segnalato riga per riga con un commento
- I commenti devono essere chiari e concisi
- Dopo ogni modifica ricompila per verificare che ci siano 0 errori

## Script
- Non creare script in codice del sistema operativo (.bat, .ps1, cmd etc.)
- Prediligi gli script in package.json o similari
- Tutto deve essere facilmente runnabile
- In una monorepo gli script nei package devono essere richiamabili anche da root

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

## Typescript/JavaScript Specific
- non usare unknown
- non usare any
- non usare us
- fare codice sempre fortemente tipizzato


## Summary
Questi standard garantiscono:
- ✅ Coerenza architettonica tra i vari progetti
- ✅ Testabilità attraverso interfacce
- ✅ Manutenibilità e scalabilità
- ✅ Qualità del codice
- ✅ Separazione delle responsabilità