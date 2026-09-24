# Baseline cache chat — step 1

Questo documento conserva il riferimento iniziale. Lo stato attuale delle verifiche è in [STEP4.md](STEP4.md).

Questa fase aggiunge solo test, fixture sintetiche e misure ripetibili. Nessuna modifica a `lib/`, al formato Hive o all'ordine delle scritture.

## Comportamenti protetti

- Prima lettura sincrona della cache legacy con Hive reale in una directory temporanea.
- Cache visibile e utilizzabile durante entrambe le chiamate server pendenti, per chat team e dirette; sostituzione con la risposta server.
- Messaggi in cache conservati se la riconciliazione fallisce offline.
- Distinzione tra conversazione certamente vuota e cache senza messaggi ma con `lastMessageAt` valorizzato.
- Ordinamento, aggiornamento senza duplicare gli ID, isolamento fra conversazioni e snapshot della lista non modificabili.
- Riavvio del box con nuova istanza del datasource: ultimi 50 messaggi conservati; pagina vuota autorevole conservata.
- Round-trip di allegati, risposte, reazioni, cancellazioni e ricevute di lettura.
- Conversazioni team/dirette e summary persistenti.
- Cambio utente, logout e ritorno all'utente precedente: nessuna esposizione dei messaggi dell'altro account, anche usando gli stessi ID di conversazione.
- JSON legacy malformato trattato come cache miss.
- Repository con Hive reale: la prima pagina aggiorna la cache; le pagine precedenti non la sovrascrivono.

I test già presenti del Bloc e del repository coprono anche paginazione, deduplicazione delle pagine precedenti, invii e aggiornamenti dei messaggi. I nuovi test verificano il comportamento pubblico: non impongono che le scritture future restino bloccanti o che il formato resti un blob unico. Solo la fixture legacy è intenzionalmente legata al vecchio formato, per poterla riutilizzare nei test di migrazione.

## Riprodurre i controlli

Dalla radice Flutter, con lo SDK configurato dal progetto (Flutter 3.35.6 / Dart 3.9.2 dichiarati nei metadati; vedere sotto la versione effettiva del runner):

```sh
flutter test --no-pub test/feature/chat/infrastructure/data_source/chat_local_data_source_test.dart test/feature/chat/infrastructure/repositories/chat_repository_impl_test.dart test/feature/chat/ui/bloc/chat/chat_bloc_test.dart --reporter expanded
flutter analyze --no-pub test/support/chat_cache_fixtures.dart test/feature/chat/infrastructure/data_source/chat_local_data_source_test.dart test/feature/chat/ui/bloc/chat/chat_bloc_test.dart benchmark/chat_cache_benchmark.dart
flutter test --no-pub benchmark/chat_cache_benchmark.dart --concurrency=1 --reporter expanded --dart-define=CHAT_CACHE_BENCHMARK_OUTPUT=benchmark/results/chat_cache_candidate.json
```

Il benchmark è fuori da `test/` e si esegue esplicitamente. Nessuna soglia di millisecondi viene usata per far fallire i test funzionali. Il file `results/chat_cache_baseline.json` è il riferimento iniziale: salvare i confronti in un file diverso.

Su questa macchina il launcher Puro standard ha restituito `Invalid SDK hash` e `flutter-dev` non trovava `bin/internal/shared.sh`. È stato possibile eseguire lo stesso SDK dal sorgente locale di flutter_tools, senza modificare l'installazione. Per riprodurre su questo host sostituire `flutter` nei comandi con:

```sh
dart --packages=/Users/arthurbetto/.puro/envs/3.35.6/flutter/packages/flutter_tools/.dart_tool/package_config.json /Users/arthurbetto/.puro/envs/3.35.6/flutter/packages/flutter_tools/bin/flutter_tools.dart
```

## Metodo e limiti delle misure

Per ciascuno dei carichi (1, 10, 100, 500 conversazioni, 50 messaggi ciascuna), il benchmark crea un database temporaneo con testo sintetico di circa 270 caratteri per messaggio. La preparazione, la scrittura della fixture, le asserzioni e la pulizia sono fuori dagli intervalli misurati. Usa tre riscaldamenti e venti campioni per carico, cambiando l'ordine dei carichi a ogni giro.

Ogni campione ricrea il box e l'istanza del datasource. Registra separatamente:

- `box_open`: riapertura Hive dal file, dopo chiusura del box.
- `first_chat_read`: `getConversationByTeamId` + `getMessages`, con cache in memoria non ancora idratata, come nel percorso iniziale del Bloc.
- `warm_chat_read`: lettura successiva dei messaggi sulla stessa istanza.
- `upsert`: aggiornamento di un messaggio, inclusa l'attesa della persistenza attuale.

Il JSON conserva tutti i campioni in microsecondi e statistiche in millisecondi (mediana, p95 con nearest rank, minimo, massimo), versione runtime e sistema operativo.

Questa è una misura del percorso **locale**, nel runner di test su macOS: non misura frame UI, HTTP, autenticazione reale o il tempo end-to-end percepito sul telefono/browser. Il filesystem può avere pagine già in cache: la riapertura Hive non equivale a un avvio a freddo del dispositivo. Nell'app il box è normalmente già aperto da `HiveInitializer`, quindi i tempi di apertura box e prima lettura vanno interpretati separatamente. La prima idratazione può inoltre essere anticipata da un accesso alle summary.

Quando cambierà il formato, mantenere questa fixture per misurare il primo accesso legacy/migrazione e aggiungere lo stesso carico nel formato nuovo per il confronto a regime. Non confondere il costo una tantum della migrazione con ogni apertura successiva. Eseguire il confronto sullo stesso host/SDK, senza altri test concorrenti.

Per confermare il guadagno percepito, prima del rilascio servirà anche una sessione sul dispositivo/browser interessato: stessa quantità di chat, build profile, cache preservata tra riavvii, prima apertura confrontata con riapertura, rete annotata e misure distinte fino alla prima visualizzazione della cache e fino alla riconciliazione server. Questa verifica end-to-end non è inclusa nei numeri del benchmark locale.

## Riferimento del codice

Codice di produzione invariato rispetto al commit `8571b582e962d4b52747db61b1833ee5bdb9dbf2`.

## Risultati della baseline

Esecuzione del 23 settembre 2026: **92 test mirati superati**, di cui 14 nuovi (9 datasource/repository con Hive reale e 5 Bloc); benchmark superato. Analisi statica dei quattro file Dart coinvolti: nessun problema; `git diff --check` superato.

| Chat × 50 messaggi | JSON fixture | Apertura box, mediana | Prima lettura, mediana | Prima lettura, p95 | Lettura successiva, mediana | Upsert, mediana |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 0.030 MB | 1.133 ms | 0.346 ms | 0.435 ms | 0.003 ms | 0.769 ms |
| 10 | 0.297 MB | 2.350 ms | 2.296 ms | 4.573 ms | 0.004 ms | 5.425 ms |
| 100 | 2.978 MB | 16.516 ms | 26.543 ms | 35.816 ms | 0.004 ms | 57.301 ms |
| 500 | 14.935 MB | 67.073 ms | 139.426 ms | 278.766 ms | 0.004 ms | 299.533 ms |

La crescita della prima lettura e dell'upsert con il numero di conversazioni è coerente con l'idratazione e la riscrittura globali. Le letture successive risultano molto più economiche. Questo giustifica la separazione per conversazione e la lettura su richiesta, ma non quantifica ancora il guadagno sul dispositivo dell'utente.

**Ambiente effettivo:** il runner dichiara Dart `3.9.0-333.2.beta` su `macos_arm64`, macOS 26.5, mentre i metadati dello SDK installato dichiarano Flutter 3.35.6 / Dart 3.9.2. La differenza è registrata, non corretta in questo step. I confronti numerici vanno eseguiti con lo stesso runtime effettivo, oppure va raccolta una nuova baseline con un'installazione coerente prima di confrontare il refactor. I campioni completi sono in [chat_cache_baseline.json](results/chat_cache_baseline.json).

## Step successivo

La separazione per conversazione è documentata in [STEP2.md](STEP2.md), con risultati distinti dalla baseline originale.

La persistenza in background è documentata in [STEP3.md](STEP3.md), con test su errori, operazioni pendenti e cambio utente.

Le verifiche finali su VM e Chrome/IndexedDB, e il collaudo su dispositivo ancora da completare, sono documentati in [STEP4.md](STEP4.md).

Il successivo intervento sulle richieste seriali della lista e sulla prima apertura è documentato in [CHAT_LIST.md](CHAT_LIST.md).
