# Caricamento della lista chat e prima apertura

## Problema e modifica

La misura fornita dall'utente sul backend `localhost:8080` indica circa 10,4 secondi per 21 richieste seriali della lista e circa 1,4 secondi per aprire una chat. Il codice confermava la catena `summary team → membri → summary diretti`, ripetuta per ogni team su web e mobile.

Le due pagine ora usano `ChatListController`, con una coda condivisa che consente fino a 6 richieste contemporanee. Summary team e membri sono indipendenti; i summary diretti partono quando sono noti i membri e usano la stessa coda. Il limite resta valido anche durante refresh sovrapposti. Il numero complessivo di chiamate resta legato a team e partecipanti.

La cache di team e summary viene mostrata prima del completamento della rete. Ogni risposta aggiorna la lista e il suo ordinamento. I membri conosciuti nella sessione permettono di mostrare subito anche le anteprime dirette al ritorno nella pagina; al primo avvio, le dirette attendono che siano noti i partecipanti. Un errore parziale conserva i dati disponibili, invece di azzerare conteggi e anteprime. Una risposta valida senza membri o senza conversazione diretta rimuove invece i dati non più attuali.

La cache della lista in memoria è associata all'utente. Cambio account, chiusura della pagina, eliminazione di un team e nuovi caricamenti invalidano le risposte vecchie e impediscono di iniziare le relative richieste ancora in coda. Le richieste HTTP già inviate terminano, ma il controller ne ignora i risultati non più pertinenti.

Per aprire una chat, il Bloc avvia insieme conversazione e messaggi se trova un ID nella conversazione **oppure nel summary della lista** in cache. Questo copre anche una chat mai aperta nella sessione. Il summary diretto deve corrispondere al team e al partecipante richiesti. La risposta della conversazione viene comunque verificata prima di pubblicare i messaggi; se l'ID cambia, si carica la pagina dell'ID nuovo. Senza ID in cache rimane la dipendenza necessaria tra le due richieste.

## Verifiche

Esecuzione finale del 24 settembre 2026: **395 test dell'app superati**, **79 test di controller/Bloc su Chrome superati**, analisi statica dei 6 file interessati senza problemi e `git diff --check` superato. Questo intervento aggiunge 20 casi e rafforza i due casi esistenti di apertura dalla cache. I conteggi VM e Chrome includono casi condivisi, non sono tutti test distinti.

I test aggiunti usano risposte controllate per verificare:

- Cache visibile durante la richiesta team, senza sovrascrivere risposte server con letture locali tardive.
- Fino a 6 richieste simultanee, inclusi i summary diretti; deduplicazione dei partecipanti.
- Aggiornamenti parziali visibili, errori isolati, conteggi conservati, cancellazioni autorevoli e ordinamento.
- Ritorno dalla chat mentre i team sono ancora in caricamento, refresh sovrapposti, cambio account, team eliminati e pagina chiusa.
- Prefetch per chat team/dirette, anche dal solo summary; nessuna seconda richiesta messaggi se l'ID coincide.
- ID cambiato, summary di un altro partecipante, errori anticipati e risultati tardivi dopo cambio chat.

Una simulazione con timer virtuale usa 8 team, 5 dirette e 450 ms per chiamata: **21 richieste di dettaglio in 4 gruppi, pari a 1,8 secondi simulati**, contro 9,45 secondi seriali. Esclude la richiesta iniziale dei team, rete reale, elaborazione del backend e rendering. È una verifica della pianificazione, non una misura end-to-end né una promessa di arrivare a 1 secondo sul dispositivo.

## Riproduzione

```sh
flutter test --no-pub --concurrency=1 --reporter expanded
flutter test --no-pub --platform chrome test/feature/chat/ui/controllers/chat_list_controller_test.dart test/feature/chat/ui/bloc/chat/chat_bloc_test.dart --reporter expanded
flutter analyze --no-pub lib/feature/chat/ui/controllers/chat_list_controller.dart lib/feature/chat/ui/mobile/chat_mobile_team_list_page.dart lib/feature/chat/ui/web/chat_web_team_list_page.dart lib/feature/chat/ui/bloc/chat/chat_bloc.dart test/feature/chat/ui/controllers/chat_list_controller_test.dart test/feature/chat/ui/bloc/chat/chat_bloc_test.dart
```

Per questo host, il launcher alternativo Flutter è documentato nel [README](README.md).

La misura reale successiva alla modifica va eseguita sulla nuova build nello stesso frontend locale e con lo stesso account della misura iniziale. Durante questa verifica non era disponibile nei browser accessibili una scheda locale autenticata; è stato richiesto l'URL del frontend. Nessun nuovo tempo end-to-end viene attribuito a web o mobile sulla base dei soli test.

## Osservazione dal vivo del 24 settembre 2026

Successivamente l'utente ha reso disponibile la sessione autenticata su `http://localhost:8081/` nel browser integrato di Codex. Sono state aperte singolarmente sei conversazioni non ancora visitate dall'agente nella prova; la lista era già caricata. Queste sono misure della prima apertura osservata, **non prove certificate con cache Hive vuota**: la cache persistente non è stata letta né cancellata. Non è stata verificata la revisione della build in esecuzione e non si attribuisce a questi risultati un miglioramento rispetto alla misura precedente.

Cronometro esterno (`Date.now()` nel controller del browser), avviato immediatamente prima del comando di clic e fermato alla rilevazione nell'albero accessibile dell'ultimo messaggio indicato dall'anteprima, oppure dello stato esplicito `No messages yet`. Comprende il costo del controllo del browser e del campionamento, non misura esattamente il primo frame. Nessuna pausa fra clic e osservazioni. Risultati indicativi, un campione per conversazione, sul computer dell'utente; nessuna misura su telefono fisico o delle singole richieste HTTP.

| Conversazione | Tempo osservato | Contenuto rilevato |
| --- | ---: | --- |
| Anna_squa | 1,101 s | Messaggi |
| team_test | 1,324 s | Messaggi |
| team5 | 1,430 s | Messaggi |
| team4 | 1,492 s | Stato vuoto |
| team6 | 1,990 s | Stato vuoto |
| Diretta di team5 | 1,927 s | Messaggi |

Media dei sei campioni: 1,544 s. Media delle quattro conversazioni con messaggi: 1,446 s. La precisione delle cifre registrate non implica la stessa accuratezza del tempo di rendering.

Due tentativi sono esclusi: `team4 tt`, per timeout del selettore iniziale prima della verifica successiva dei messaggi; `team3`, perché il criterio attendeva un messaggio dell'anteprima mentre la chat mostrava uno stato vuoto. Il timeout di quest'ultimo non è un tempo di caricamento. Le discrepanze fra anteprime e stati vuoti richiedono una verifica separata prima di attribuirle a un segnaposto, alla cache o ai dati server.

La lista è stata lasciata aperta. Per certificare l'apertura a cache vuota e distinguere rete, cache e rendering serve una prova isolata con stato della cache noto e strumentazione dell'app o del browser.
