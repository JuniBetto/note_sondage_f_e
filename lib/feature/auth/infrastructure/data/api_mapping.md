# API Mapping Documentation

Questo documento descrive gli endpoint necessari al backend per supportare le funzionalità implementate nel frontend Flutter.

## 1. Authentication (Public & Private)

Gestione dello scambio token tra Firebase e il sistema di permessi interno.

| Attività                  | Metodo | Endpoint                  | Note                                                           |
| :------------------------ | :----- | :------------------------ | :------------------------------------------------------------- |
| Scambio Firebase ID Token | `POST` | `/public/api/auth/verify` | Chiamato da `BackendAuthDataSource` dopo il login Firebase.    |
| Refresh JWT               | `POST` | `/auth/exchange-token`    | Usato dall' `AuthInterceptor` per gestire il 401 Unauthorized. |

## 2. Team & Member Management

Operazioni gestite principalmente da `TeamMemberUseCase`.

| Attività                 | Metodo  | Endpoint                                 | Note                                                                                 |
| :----------------------- | :------ | :--------------------------------------- | :----------------------------------------------------------------------------------- |
| Crea Team                | `POST`  | `/teams`                                 | Inizializza un nuovo team.                                                           |
| Lista Membri Team        | `GET`   | `/teams/{teamId}/members`                | Recupera tutti i partecipanti di un team specifico.                                  |
| Invito Membro (Email)    | `POST`  | `/teams/{teamId}/invite`                 | **Aggregato**: Verifica se l'utente esiste, altrimenti lo crea e lo associa al team. |
| Caricamento Foto Profilo | `POST`  | `/team-members/{memberId}/profile-image` | Gestisce l'upload multipart su MinIO.                                                |
| Proxy Foto Profilo       | `GET`   | `/team-members/{memberId}/profile-image` | Restituisce lo stream dell'immagine da MinIO (usato in `DioClient`).                 |
| Modifica Ruolo           | `PATCH` | `/team-members/{id}`                     | Aggiorna il `roleId` di un membro.                                                   |

## 3. Clocking (Timbrature / Presenze)

Basato sulle definizioni del `ClockingRepository`.

| Attività          | Metodo | Endpoint                   | Note                                                               |
| :---------------- | :----- | :------------------------- | :----------------------------------------------------------------- |
| Clock-In          | `POST` | `/clocking/in`             | Registra l'inizio turno (deve salvare `clock_in` e posizione GPS). |
| Clock-Out         | `POST` | `/clocking/out`            | Aggiorna il record esistente impostando `clock_out`.               |
| Storico Utente    | `GET`  | `/users/{userId}/clocking` | Recupera tutte le timbrature di un utente.                         |
| Monitoraggio Team | `GET`  | `/teams/{teamId}/clocking` | Permette agli admin di vedere chi è "in" o "out".                  |
| Filtro per Data   | `GET`  | `/clocking`                | Parametri query: `?date=YYYY-MM-DD` o `?userId=...`.               |

## 4. Sondage (Sondaggi)

Gestione dei poll e delle votazioni.

| Attività              | Metodo | Endpoint                   | Note                                                                          |
| :-------------------- | :----- | :------------------------- | :---------------------------------------------------------------------------- |
| Creazione Sondaggio   | `POST` | `/sondages`                | **Aggregato**: Salva testata, opzioni e vincoli temporali in una transazione. |
| Lista Sondaggi Team   | `GET`  | `/teams/{teamId}/sondages` | Recupera i sondaggi attivi e chiusi per il team.                              |
| Dettaglio + Risultati | `GET`  | `/sondages/{id}`           | Ritorna il sondaggio con le opzioni e i conteggi dei voti aggiornati.         |
| Invio Voto            | `POST` | `/sondages/{id}/vote`      | Registra la scelta dell'utente (vincolo: 1 voto per utente).                  |

---

## 5. Consigli per i Controller Aggregati (Backend)

Per facilitare il lavoro del frontend, i tuoi controller dovrebbero gestire queste "aggregazioni":

1. **Invite Logic**: Invece di far fare al frontend 3 chiamate (cerca utente -> crea utente -> aggiungi al team), crea un endpoint `/teams/{id}/invite` che faccia tutto sul backend.
2. **Sondage Creation**: L'endpoint `POST /sondages` dovrebbe accettare un JSON complesso che include la lista delle opzioni:
   ```json
   {
     "title": "...",
     "options": ["Opzione 1", "Opzione 2"],
     "expiresAt": "..."
   }
   ```
3. **Context Provider**: Tutte le risposte relative ai Team dovrebbero includere il ruolo dell'utente che fa la richiesta, per permettere al frontend di nascondere o mostrare i tasti "Edit/Delete" correttamente.
