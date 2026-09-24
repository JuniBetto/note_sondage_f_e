# Step 2 — messaggi separati per conversazione

## Comportamento implementato

`ChatLocalDataSource` salva i messaggi in `chat_cache_box` con chiavi `messages_v2::<utente codificato>::<conversazione codificata>`. I due componenti sono codificati separatamente per evitare collisioni con i separatori. Il limite resta di 50 messaggi persistenti per conversazione; la lista già caricata in memoria può contenerne di più, come prima.

La lettura di conversazioni e summary non deserializza più i messaggi. `getMessages` e `upsertMessage` caricano soltanto i messaggi della conversazione richiesta e li conservano in memoria. La lettura anticipata a box ancora chiuso può riprovare dopo l'inizializzazione. Un JSON danneggiato di una chat produce un cache miss di quella chat e non cancella i dati delle altre.

Conversazioni e summary mantengono il formato esistente. Le API del repository e del Bloc restano invariate; le scritture ordinarie vengono ancora attese. In questo step la persistenza ordinaria in background non era ancora implementata; il comportamento successivo è documentato in [STEP3.md](STEP3.md).

## Migrazione e recupero

La prima lettura dei messaggi legacy continua a fornire la cache sincrona. Per individuare la chat è ancora necessario decodificare una volta il vecchio blob JSON; si costruiscono però le entità dei messaggi solo della chat richiesta. La copia completa nelle nuove entry viene poi pianificata sulla coda degli eventi, senza attendere il disco nel getter. È una lavorazione sullo stesso isolate, quindi il suo lavoro CPU può ancora influire sulla fluidità durante questo primo aggiornamento.

La migrazione:

1. Copia anche le chat mai aperte, ordinando e conservando gli ultimi 50 messaggi.
2. Preserva le entry già nel nuovo formato, comprese le liste vuote autorevoli, senza sovrascriverle con messaggi vecchi.
3. Attende le scritture e il flush prima di eliminare la chiave legacy dell'utente.
4. Mantiene il vecchio blob se copia, flush o rimozione falliscono; il tentativo successivo riprende senza sovrascrivere le entry già presenti.

Migrazione e scritture messaggi vengono ordinate nella stessa coda del datasource singleton. Ogni scrittura cattura utente e contenuto prima di attendere: un cambio account non cambia la destinazione di un'operazione pendente. Gli errori non bloccano le operazioni successive. Se una normale scrittura riesce ma la migrazione di altri dati legacy fallisce, il salvataggio nuovo rimane valido e il blob legacy viene conservato. Gli errori di migrazione automatica vengono segnalati nel log senza contenuti dei messaggi.

`migrateLegacyMessages()` permette di attendere esplicitamente il completamento per l'account corrente (usato dai test e dal benchmark). Dopo la copia riuscita e la rimozione del vecchio blob, la migrazione compatta il box una sola volta: altrimenti Hive conserverebbe i frame del blob cancellato, aumentando il costo di riapertura. Se la compattazione fallisce, i messaggi nuovi sono comunque già persistiti e leggibili; l'errore viene registrato senza invalidare la migrazione. I campi JSON originali sono preservati, evitando di espandere ogni messaggio legacy con campi nulli. Il benchmark misura la riapertura dopo questa migrazione reale, senza interventi aggiuntivi sul file.

## Verifiche

- Tutti i **197 test della feature chat** superati, inclusi i test dello step 1 e **17 nuovi test** relativi a questo step.
- Errori di copia, flush e cancellazione simulati tramite un wrapper di un box Hive reale; ripresa verificata dopo chiusura e riapertura su disco.
- Scritture ravvicinate e cambio account verificati mentre la migrazione è sospesa.
- Verifiche delle chiavi effettivamente lette e scritte: nessuna lettura dei messaggi dalle summary e nessuna riscrittura delle chat non coinvolte a migrazione conclusa.
- Analisi statica dei file di produzione/test/benchmark interessati senza problemi.

Esecuzione completa dei test:

```sh
flutter test --no-pub test/feature/chat --reporter expanded
```

Per il launcher alternativo necessario su questo host, vedere [README](README.md).

## Riprodurre il benchmark

```sh
flutter test --no-pub benchmark/chat_cache_benchmark.dart --concurrency=1 --reporter expanded --dart-define=CHAT_CACHE_FORMAT=migrated --dart-define=CHAT_CACHE_BENCHMARK_OUTPUT=benchmark/results/chat_cache_step2_migrated.json
flutter test --no-pub benchmark/chat_cache_benchmark.dart --concurrency=1 --reporter expanded --dart-define=CHAT_CACHE_FORMAT=legacy --dart-define=CHAT_CACHE_BENCHMARK_OUTPUT=benchmark/results/chat_cache_step2_legacy.json
```

Il caso `migrated` misura separatamente il costo una tantum della migrazione (compattazione inclusa), poi chiude il box e misura riapertura, prima lettura e upsert sul nuovo formato. Usa lo stesso contenuto sintetico, gli stessi carichi e campioni della baseline. `legacy` misura invece la prima apertura subito dopo l'aggiornamento: l'upsert attende anche la migrazione avviata dalla lettura, quindi quel dato non rappresenta il costo a regime di ogni messaggio.

Non sovrascrivere `chat_cache_baseline.json`: è la misura precedente alla modifica. Il codice attuale con `CHAT_CACHE_FORMAT=legacy` usa già il nuovo lettore compatibile e non riproduce il vecchio algoritmo.

Tutte le misure sono locali al runner macOS e non includono rete o rendering UI. Il runtime effettivo deve coincidere con quello della baseline; i dettagli e le discrepanze dello SDK di questo host sono documentati nel README dello step 1. Non è ancora una misura end-to-end sul dispositivo dell'utente.

## Risultati dopo la migrazione

Stesso runtime effettivo della baseline; 20 campioni per carico dopo 3 riscaldamenti. Tutti i valori della tabella sono mediane in millisecondi.

| Chat × 50 messaggi | Prima lettura prima | Prima lettura dopo | Apertura box prima → dopo | Upsert prima → dopo | Migrazione una tantum |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 0.346 | 0.275 | 1.133 → 0.831 | 0.769 → 0.614 | 1.853 |
| 10 | 2.296 | 0.347 | 2.350 → 2.039 | 5.425 → 0.737 | 10.761 |
| 100 | 26.543 | 0.681 | 16.516 → 12.510 | 57.301 → 0.780 | 83.999 |
| 500 | 139.426 | 3.932 | 67.073 → 62.334 | 299.533 → 0.945 | 390.618 |

Con 500 chat la prima lettura locale passa da 139,426 a 3,932 ms (circa −97%); l'upsert da 299,533 a 0,945 ms. La riapertura Hive passa da 67,073 a 62,334 ms in questa esecuzione: la compattazione evita di dover rileggere anche il blob cancellato. La prima lettura include ancora i metadati di tutte le conversazioni, quindi non è completamente costante rispetto al numero di chat.

Una prima variante senza compattazione e con riserializzazione completa dei messaggi legacy aveva aumentato il tempo di apertura del box; è stata corretta prima di concludere lo step. Il risultato salvato descrive soltanto l'implementazione finale con compattazione e conservazione dei campi JSON originali.

I campioni completi, inclusi p95 e costo della migrazione, sono in [chat_cache_step2_migrated.json](results/chat_cache_step2_migrated.json). Il benchmark locale non garantisce gli stessi millisecondi sul dispositivo; rimane da eseguire la verifica end-to-end prevista prima del rilascio.

Nel caso ancora legacy, con 500 chat la prima lettura è 64.660 ms; il primo upsert che attende la migrazione è 377.562 ms. È il costo del passaggio iniziale, distinto dal comportamento a regime. Campioni: [chat_cache_step2_legacy.json](results/chat_cache_step2_legacy.json). Entrambi i benchmark della versione finale sono passati.
