# Step 3 — persistenza fuori dall'attesa della UI

## Comportamento

Il repository attende la risposta del server e aggiorna subito la cache in memoria. Restituisce poi il risultato senza aspettare la scrittura Hive. Questo vale per conversazioni team/dirette, summary, prima pagina dei messaggi, invii di testo e allegati, reazioni e cancellazioni. Le pagine precedenti continuano a non sostituire la prima pagina in cache.

Gli errori di rete mantengono il comportamento precedente. Un errore della cache, sincrono o asincrono, viene invece registrato senza trasformare una risposta positiva del server in un errore di invio: si evita così di indurre un nuovo invio di un messaggio già confermato. I log contengono il tipo di errore, non contenuti dei messaggi o identificativi utente.

La coda del datasource ora include anche metadati e summary. Ogni salvataggio cattura chiavi con l'utente e una copia dei dati prima di attendere. La conversione JSON e l'I/O vengono eseguiti in un successivo evento, in ordine, permettendo al chiamante di usare prima il risultato. Non viene creato un isolate: il lavoro CPU resta sul thread Dart, e le copie necessarie per aggiornare la memoria restano sincrone. Il limite dei messaggi persistenti resta 50 per chat.

## Cambio utente e operazioni pendenti

Il repository registra l'utente all'inizio della richiesta di rete. Se al ritorno l'utente corrente è diverso (o è avvenuto il logout), non salva quella risposta nella cache. Il risultato della richiesta resta restituito al suo chiamante; il controllo riguarda la cache e non cambia il ciclo di vita del Bloc.

Le scritture già accodate conservano la destinazione originale. Gli snapshot ancora in attesa o falliti sono indicizzati con chiavi che includono l'utente: non vengono mostrati ad altri account, ma restano leggibili se l'utente torna prima del completamento della scrittura. Una scrittura più vecchia che termina non elimina lo snapshot di una scrittura più recente ancora pendente.

Se una scrittura fallisce, la coda prosegue e l'ultimo snapshot resta leggibile in memoria durante la sessione; un successivo salvataggio dello stesso dato può persisterlo. Non viene introdotto un ciclo di retry automatico. La migrazione legacy mantiene le garanzie dello step 2 e usa la stessa coda; non blocca più il ritorno dei risultati del repository.

`ChatLocalDataSource.save*` e `upsertMessage` restituiscono ancora Future attendibili fino alla persistenza (utile per test e chiamanti che richiedano esplicitamente l'attesa). Il repository gestisce questi Future in background. `flushPendingWrites()` permette di attendere che le operazioni già accodate terminino; non rilancia i loro errori, che sono gestiti dai Future delle singole scritture. I test lo usano prima di verificare il disco o chiudere Hive.

Questa è una cache di risposte già confermate dal server, non una coda di invio offline. Se l'app viene terminata prima del completamento, l'ultimo aggiornamento può mancare nella cache al riavvio e verrà recuperato dal server. Non si può garantire il completamento di scritture in background dopo una chiusura forzata del processo.

## Verifiche

**250 test della feature chat superati**, inclusi i 197 dello step 2 e 53 nuovi casi. Analisi statica dei cinque file Dart interessati senza problemi; `git diff --check` superato.

I nuovi test non dipendono da soglie di tempo: un `Completer` mantiene bloccato il backend mentre si verifica che il repository abbia già restituito il risultato e che la memoria contenga i dati aggiornati.

Copertura aggiunta:

- Tutte le 9 operazioni che aggiornano la cache: risposta disponibile con scrittura bloccata, successo preservato se il disco fallisce, cache ignorata se cambia utente o avviene logout, errori di rete ancora propagati.
- Errore sincrono della cache gestito.
- Hive reale: flush pendente finché il salvataggio è bloccato e verifica dopo riavvio.
- Invio confermato dal server con errore disco, logout/ritorno e salvataggio successivo riuscito.
- Sequenza account A → B → logout → A con scritture pendenti, preservando l'ultimo aggiornamento e le destinazioni.
- Metadati e summary accodati leggibili prima del salvataggio e isolati dopo riavvio.
- Risposta server tardiva dopo logout senza creazione di entry anonime.
- Snapshot dei messaggi indipendente da modifiche successive alle liste del chiamante.
- Risposta server disponibile anche con migrazione legacy bloccata, con persistenza corretta alla fine.

Comandi dalla radice Flutter:

```sh
flutter test --no-pub test/feature/chat --concurrency=1 --reporter expanded
flutter analyze --no-pub lib/feature/chat/infrastructure/data_source/chat_local_data_source.dart lib/feature/chat/infrastructure/repositories/chat_repository_impl.dart test/feature/chat/infrastructure/data_source/chat_local_data_source_test.dart test/feature/chat/infrastructure/repositories/chat_repository_impl_test.dart benchmark/chat_cache_benchmark.dart
flutter test --no-pub benchmark/chat_cache_benchmark.dart --concurrency=1 --reporter expanded --dart-define=CHAT_CACHE_FORMAT=migrated --dart-define=CHAT_CACHE_BENCHMARK_OUTPUT=benchmark/results/chat_cache_step3_migrated.json
```

Per il launcher Flutter alternativo di questo host, vedere [README](README.md).

## Interpretazione del benchmark

La metrica `upsert` resta il tempo completo della chiamata al datasource, inclusa la persistenza, per mantenere il confronto con lo step 2. Sono aggiunte due misure della stessa chiamata a `repository.sendMessage`, eseguita dopo l'upsert:

- `repository_return`: fino alla restituzione del risultato, con risposta remota simulata immediata e cache in memoria aggiornata.
- `repository_durable`: dall'inizio della stessa chiamata fino al completamento delle scritture accodate.

Il risultato viene verificato anche leggendo la cache da una nuova istanza del datasource. Il benchmark usa Hive reale, 20 campioni per carico dopo 3 riscaldamenti. Questi numeri isolano il costo locale: non includono rete reale o rendering dell'interfaccia e non sostituiscono la verifica sul dispositivo prevista nello step 4. I report JSON degli step 1 e 2 restano invariati.

## Risultati

Benchmark superato con lo stesso runtime effettivo dello step 2. Valori in millisecondi, salvo il numero di chat.

| Chat × 50 messaggi | Ritorno repository, mediana | Ritorno repository, p95 | Persistenza della stessa chiamata, mediana | Prima lettura locale, mediana |
| --- | ---: | ---: | ---: | ---: |
| 1 | 0.138 | 0.188 | 0.737 | 0.274 |
| 10 | 0.148 | 0.214 | 0.837 | 0.358 |
| 100 | 0.141 | 0.314 | 0.815 | 0.726 |
| 500 | 0.145 | 0.177 | 0.775 | 3.820 |

Con 500 chat il repository restituisce il messaggio confermato in circa **0,146 ms**, mentre la persistenza della stessa chiamata termina in circa **0,776 ms** dall'inizio. Il guadagno più rilevante è che un disco lento o una migrazione in corso non trattengono più il risultato del server, comportamento verificato dai test con operazioni bloccate.

Questa nuova misura non è un confronto diretto con la metrica `upsert` dello step 2: il repository viene misurato dopo un upsert di preparazione e la risposta remota è simulata. Il tempo totale di persistenza può avere un piccolo costo aggiuntivo per la pianificazione sulla coda degli eventi; la UI non lo attende. La prima lettura con 500 chat resta circa 3,82 ms, coerente con il miglioramento dello step 2.

Campioni completi e dettagli dell'ambiente: [chat_cache_step3_migrated.json](results/chat_cache_step3_migrated.json).
