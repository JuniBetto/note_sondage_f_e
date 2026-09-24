# Step 4 — verifica delle regressioni, web e mobile

## Stato

Verifica del 23 settembre 2026. I controlli automatici descritti sotto sono passati. Il collaudo dell'interfaccia e la misura dell'apertura su telefono/browser con una chat di prova restano da eseguire: questi risultati non certificano ancora il tempo percepito dall'utente né l'assenza di ogni possibile regressione.

In questo step non è stato modificato il codice di produzione degli step 2 e 3. Sono stati estesi i test e il benchmark per esercitare anche IndexedDB nel browser.

## Risultati funzionali

| Controllo | Esito | Ambito |
| --- | --- | --- |
| Intera suite dell'app su VM | 368 superati | Chat e altre feature, widget e golden inclusi |
| Suite cache aggiornata su VM | 34 superati | Hive su filesystem; include il nuovo stress test |
| Suite cache aggiornata su Chrome | 34 superati | Hive su IndexedDB reale |
| Repository e Bloc su Chrome | 129 superati | Apertura, riconciliazione, offline, operazioni sui messaggi |
| Analisi statica | Nessun problema | Tutti gli 8 file Dart interessati, fixture e benchmark inclusi |
| `git diff --check` | Superato | Nessun errore di whitespace nel diff tracciato |

La suite completa è stata eseguita prima dell'aggiunta del nuovo caso degli 80 invii; successivamente è stata rieseguita la suite cache modificata. I conteggi si sovrappongono: non vanno sommati come se fossero tutti casi distinti. I casi web eseguiti sono 163.

Il nuovo stress test blocca la prima scrittura, esegue 80 invii con conferma remota simulata e verifica che tutti i risultati e i messaggi in memoria siano già disponibili. Sblocca poi il disco, attende la coda, chiude e riapre Hive: gli ultimi 50 messaggi devono essere presenti, ordinati, senza duplicati e senza modificare un'altra chat.

La stessa suite datasource usa una directory temporanea su VM e IndexedDB sul profilo/origine isolati del runner Chrome, eliminando il database di prova a fine test. Le prove non usano messaggi o account reali. La riapertura del box verifica la persistenza; non simula un arresto forzato del processo durante una scrittura.

Copertura complessiva delle verifiche eseguite:

- Lettura immediata dalla cache, chat team/dirette, riconciliazione e mantenimento dei messaggi offline.
- Migrazione legacy, chat mai aperte, ripartenza dopo errori di copia/flush/cancellazione, precedenza dei dati nuovi e pagine vuote autorevoli.
- Scritture in background, errori disco, avanzamento della coda dopo un errore, snapshot indipendenti e raffica di invii.
- Paginazione senza sostituire la prima pagina persistita, ordinamento e limite degli ultimi 50 messaggi al riavvio.
- Allegati, reply, reazioni, cancellazioni e ricevute: round-trip dei dati; delega del repository; comportamento del Bloc.
- Logout, cambio account, scritture pendenti e risposte server tardive senza contaminare la cache di un altro utente.

Le verifiche su allegati e operazioni remote usano risposte simulate: non verificano upload/download reali, notifiche o il backend.

## Confronto delle prestazioni locali

Il codice di produzione non cambia in questo step. Il benchmark condiviso è stato rieseguito su VM, verificando anche che il comando originale continui a funzionare; confronto con la baseline sullo stesso runtime effettivo. Mediane in millisecondi:

| Chat × 50 messaggi | Prima lettura, prima | Prima lettura, dopo | Upsert con persistenza, prima | Upsert con persistenza, dopo |
| --- | ---: | ---: | ---: | ---: |
| 1 | 0.346 | 0.307 | 0.770 | 0.897 |
| 10 | 2.296 | 0.378 | 5.425 | 0.967 |
| 100 | 26.543 | 0.756 | 57.301 | 1.060 |
| 500 | 139.426 | 4.078 | 299.533 | 1.227 |

Con 500 chat la prima lettura locale passa da circa 139 a 4,08 ms. Il ritorno di `repository.sendMessage`, con server simulato immediato, è circa 0,170 ms; la UI non attende più la persistenza. Con una sola chat l'upsert completo è leggermente più costoso in questa esecuzione (circa 0,13 ms in più); l'ottimizzazione riguarda soprattutto la crescita con la cronologia e l'attesa sul percorso UI, non garantisce un costo totale inferiore per ogni operazione e carico.

Rimane un costo distinto: Hive è ancora un box normale e all'apertura carica le entry. Con 500 chat, l'apertura del box è circa 67 ms; la migrazione iniziale una tantum è circa 445 ms. Spostare il lavoro sulla coda degli eventi non lo trasferisce su un altro isolate. Questi numeri non dimostrano da soli che ogni frame della prima apertura sia fluido.

Fonti: [baseline](results/chat_cache_baseline.json), [misura finale su VM](results/chat_cache_step4_migrated.json). Metodo, warmup e discrepanza fra SDK dichiarato e runtime effettivo sono documentati in [README](README.md) e [STEP3](STEP3.md). I report precedenti restano invariati.

## Misura aggiuntiva su Chrome / IndexedDB

Benchmark superato sul backend browser reale: 3 riscaldamenti e 20 campioni per carico, stessa fixture sintetica. Chrome 153.0.8010.53 su macOS 26.5, compilazione JavaScript del runner Flutter test; non è una build profile dell'app. Mediane in millisecondi:

| Chat × 50 messaggi | Apertura box | Prima lettura | Upsert con persistenza | Ritorno repository | Persistenza della stessa chiamata | Migrazione iniziale |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 1.05 | 0.85 | 1.25 | 0.25 | 1.30 | 2.40 |
| 10 | 2.00 | 1.00 | 1.40 | 0.20 | 1.30 | 12.35 |
| 100 | 13.00 | 1.30 | 1.90 | 0.20 | 1.30 | 118.55 |
| 500 | 60.10 | 3.40 | 2.55 | 0.30 | 1.35 | 632.75 |

Anche su web il costo del ritorno del repository resta piccolo al crescere delle chat. L'apertura del box e la migrazione restano dipendenti dal carico complessivo. Queste sono misure del codice finale: non è stata raccolta una baseline web della vecchia versione, quindi non si ricava da questa tabella un fattore di accelerazione web. I tempi molto piccoli risentono della risoluzione dei timer del browser; non misurano frame, rete o tempo dal tap alla visualizzazione.

Campioni completi: [chat_cache_step4_chrome_migrated.json](results/chat_cache_step4_chrome_migrated.json).

## Riproduzione

```sh
flutter test --no-pub --concurrency=1 --reporter expanded
flutter test --no-pub test/feature/chat/infrastructure/data_source/chat_local_data_source_test.dart --concurrency=1 --reporter expanded
flutter test --no-pub --platform chrome test/feature/chat/infrastructure/data_source/chat_local_data_source_test.dart --reporter expanded
flutter test --no-pub --platform chrome test/feature/chat/infrastructure/repositories/chat_repository_impl_test.dart test/feature/chat/ui/bloc/chat/chat_bloc_test.dart --reporter expanded
flutter test --no-pub benchmark/chat_cache_benchmark.dart --concurrency=1 --reporter expanded --dart-define=CHAT_CACHE_FORMAT=migrated --dart-define=CHAT_CACHE_BENCHMARK_OUTPUT=benchmark/results/chat_cache_candidate.json
flutter test --no-pub --platform chrome test/support/chat_cache_benchmark.dart --reporter expanded --dart-define=CHAT_CACHE_FORMAT=migrated
```

L'implementazione condivisa del benchmark si trova sotto `test/support/` perché questo runner Chrome non serve i sorgenti fuori da `test/`. Non termina con `_test.dart`, quindi non viene eseguita dalla suite ordinaria. L'entry point sotto `benchmark/` conserva il comando originale su VM. Nel browser il JSON viene emesso sulla riga `CHAT_CACHE_BENCHMARK`; `CHAT_CACHE_BENCHMARK_OUTPUT` scrive un file solo su VM. Il launcher alternativo necessario su questo host è documentato nel [README](README.md).

## Collaudo ancora necessario per chiudere lo step

Dispositivi rilevati: Chrome 153.0.8010.53 su macOS 26.5, emulatore Android 14 ARM64, iPhone fisico iOS 18.7.10. Il rilevamento non equivale all'esecuzione dell'app su questi dispositivi. Serve una chat di prova accessibile nell'ambiente scelto, per eseguire operazioni reali senza coinvolgere le conversazioni degli utenti.

| Prova sull'interfaccia | Web | Mobile |
| --- | --- | --- |
| Build profile, prima apertura e riapertura, pochi/molti messaggi | Da eseguire | Da eseguire |
| Primo avvio con cache legacy e riavvio dopo migrazione | Da eseguire | Da eseguire |
| Apertura offline con cache e riconciliazione al ritorno della rete | Da eseguire | Da eseguire |
| Invii rapidi, allegato, reazione, cancellazione e riavvio | Da eseguire | Da eseguire |
| Logout/cambio account con operazioni pendenti | Da eseguire | Da eseguire |

Registrare separatamente il tempo dal tap al primo frame contenente la cache e quello fino ai dati riconciliati dal server; annotare build, dispositivo, carico e rete. Confrontare baseline e modifica nello stesso ambiente. Una cache vuota richiede comunque la rete; una chiusura forzata prima della scrittura può lasciare la cache indietro rispetto ai dati già confermati dal server, come documentato nello step 3.
