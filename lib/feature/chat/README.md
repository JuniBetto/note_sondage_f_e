# Chat Feature

Feature Flutter per la chat mobile e web, con lista conversazioni e pagina dedicata per il contenuto chat.

## Route

- mobile lista team: `sondage/chat`
- mobile conversazione: `sondage/chat/conversation?teamId=...`
- web lista team: `chat`
- web conversazione: `chat?teamId=...`

## Versione coperta

- V1
  - una chat per team
  - messaggi testuali
  - storico messaggi
  - aggiornamento realtime via WebSocket
- V2
  - immagini e documenti
  - push notification chat
  - messaggi letti/non letti
  - unread count nella lista team
- V3 parziale
  - chat diretta tra membri del team
  - reply al messaggio
  - reaction emoji
  - soft delete del proprio messaggio

## Architettura

- `domain/`
  - entita' chat
  - repository
  - use case
- `infrastructure/`
  - data source remoto
  - mapper
  - implementazione repository
- `ui/`
  - `widgets/team_chat_screen.dart`
  - `widgets/chat_team_list_card.dart`
  - `widgets/chat_direct_list_card.dart`
  - `widgets/chat_direct_action_dialog.dart`
  - `widgets/chat_draft_attachment.dart`
  - `mobile/chat_mobile_team_list_page.dart`
  - `mobile/chat_mobile_conversation_page.dart`
  - `web/chat_web_page.dart`
  - `web/chat_web_team_list_page.dart`
  - `web/chat_web_conversation_page.dart`

## Realtime

- il caricamento conversazione e messaggi passa da `API_BASE_URL` su `8080`
- il realtime ascolta il notification-service WebSocket su `8085`
- se serve un endpoint esplicito si puo' usare `--dart-define=NOTIFICATION_WS_URL=ws://host:8085`
- le push foreground vengono soppresse quando l'utente e' gia' dentro una route chat

## UX attuale

- mobile: la sezione e' visibile come `Sondage/Chat`
- mobile e web: prima si vede la lista conversazioni, poi si apre una pagina dedicata alla chat
- la lista mostra canali team e storico chat direct
- la direct si apre dal nome utente dentro una chat team oppure dalla lista direct gia' esistente

## Limiti attuali

- niente ricerca messaggi
- niente permessi avanzati

## Evoluzioni previste

- V3 restante: ricerca messaggi e permessi avanzati
