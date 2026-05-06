# Shift Create Modal

This file documents the expected behavior of the `create shift` modal and the
realtime fan-out logic.  It exists to prevent regressions.

## Relevant files

### Flutter
- `lib/feature/shift/ui/widgets/shift_day_dialog.dart` – modal UI, state, result
- `lib/feature/shift/ui/mobile/shift_mobile_widget.dart` – mobile calendar, consumes intent
- `lib/feature/shift/ui/web/shift_web_page.dart` – web calendar, consumes intent

### Backend (note_sondage_auth)
- `aggregator/service/impl/ShiftAggregationServiceImpl.java` – assign / update / delete + realtime fan-out
- `aggregator/realtime/ShiftRealtimePublisher.java` – publishes events to notification service
- `aggregator/client/ShiftServiceClient.java` – calls note_sondage_shift

---

## ShiftDayDialogResult fields

| Field | Type | Meaning |
|---|---|---|
| `profileId` | `String?` | Selected shift profile UUID |
| `startTime` | `TimeOfDay` | Shift start |
| `endTime` | `TimeOfDay` | Shift end |
| `overnight` | `bool` | Crosses midnight |
| `alarmOffsets` | `List<int>` | Negative minutes before start (e.g. `-30`) |
| `note` | `String?` | Free-text note |
| `deleted` | `bool` | `true` → delete action |
| `isPublic` | `bool` | `true` → visible to team (set automatically when `teamId` is set) |
| `teamId` | `String?` | UUID of selected team; `null` for personal shifts |
| `targetUserIds` | `List<String>` | Firebase UIDs to assign. Empty = self. One = specific member. Multiple = all selected. |

---

## Modal layout

### Always visible (create and edit)
- **Close button (×)** – top-right, always present; closes with `null` (no save)
- Shift profile selector
- Start time
- End time
- Overnight toggle
- Alarms
- Note field

### Visible only when the user can manage at least one team
- Team selector dropdown

### Visible after a team is selected
- `Tutti i membri del team` option
- `Un membro specifico` option
- Contextual banner: _"Il turno sarà visibile a tutto il team selezionato"_

### Visible after choosing `Un membro specifico`
- Member list of the selected team (loaded on demand via `TeamMemberUseCase`)

### Edit mode specifics
- **Non-manager member** opening a public team shift → modal is **read-only**
- Read-only banner displayed: _"Turno pubblico – solo il team owner può modificarlo"_
- Delete button only shown when `existing != null && !_readOnly`

---

## Assignment semantics

### 1. Personal private shift
- No team selected
- `isPublic = false`, `teamId = null`, `targetUserIds = []`
- Stored and visible only to the authenticated user

### 2. Personal public shift
- No team selected, user enables public toggle
- `isPublic = true`, `teamId = null`, `targetUserIds = []`
- Visible to members of the user's teams (via `visibleTeamIds` query on shift-service)

### 3. Team shift – all members
- Team selected, `_assignToAllMembers = true`
- `isPublic = true`, `teamId = <selected>`, `targetUserIds = [all assignable member UIDs]`
- One assignment per member is created by the calling bloc/use-case

### 4. Team shift – specific member
- Team selected, `_assignToAllMembers = false`, one member picked
- `isPublic = true`, `teamId = <selected>`, `targetUserIds = [<memberFirebaseUid>]`
- Single assignment for that member, owned by them, with team context

---

## Realtime fan-out rules (backend – `ShiftAggregationServiceImpl`)

Applies to `SHIFT_ASSIGNED`, `SHIFT_UPDATED`, `SHIFT_DELETED` events.

| Scenario | Recipients |
|---|---|
| Shift assigned to **specific other member** (`assigningToOtherUser = true`, `teamId` set) | **Actor (owner) + Target member only** |
| Shift public, assigned to **self** with teamId | **All team members** (owner + all active members) |
| Private shift (no team) | **Target user only** |

Implementation: `resolveShiftRecipients(auth, actor, target, publicShift, teamId, assigningToOtherUser)`

---

## What counts as a regression

Any of the following is a regression:

- The **close (×) button** disappears from the modal header
- The team selector disappears during create for a team-owner user
- `Tutti i membri del team` is no longer available after team selection
- `Un membro specifico` is no longer available after team selection
- The member list does not appear after choosing `Un membro specifico`
- A team-scoped shift loses its `teamId` on update
- A team-scoped shift opens with different data on another team member's device
- A personal public shift is not visible to the user's teams
- A user without edit grants can modify a public/team shift
- A user without `ADMIN`/`MANAGE`-level team shift grants can open the team assignment branch in create mode
- A shift assigned to a **specific member** sends realtime to the whole team instead of actor + target
- A shift assigned to **all members** does not appear on each member's calendar in real time

---

## Manual QA checklist

### 1 – Personal private shift
Create a shift with no team selected.

- [ ] Close (×) button is visible and dismisses the modal without saving
- [ ] Shift saved as private, appears only on the creator's calendar

### 2 – Personal public shift
Create a shift with no team selected, enable public toggle.

- [ ] Shift appears on the creator's calendar
- [ ] Shift is visible in read-only mode to other members of the creator's teams

### 3 – Team shift – all members
Create a shift as a team owner, select a team, leave `Tutti i membri del team` checked.

- [ ] Close (×) button is visible
- [ ] `Tutti i membri del team` is visible and selected by default
- [ ] `Un membro specifico` is also visible
- [ ] Saving creates one assignment per team member
- [ ] Each member sees the shift on their own calendar **immediately** (realtime)
- [ ] No separate public/private toggle is shown for team shifts

### 4 – Team shift – specific member
Create a shift as a team owner, select a team, choose `Un membro specifico`, pick one member.

- [ ] Member list is displayed
- [ ] Saving creates one assignment for that member
- [ ] The **target member** sees the shift on their calendar immediately (realtime)
- [ ] The **actor (owner)** also sees the refresh immediately (realtime)
- [ ] Other team members are **not** notified

### 5 – User without team management grants
Open create shift as a regular member (no ADMIN/MANAGE shift grant).

- [ ] Team assignment section is **not shown**
- [ ] Personal shift creation still works normally

### 6 – Edit existing team-scoped shift (manager)
Reopen a previously saved team-scoped shift.

- [ ] Selected team is still displayed
- [ ] `teamId` is still present in the result
- [ ] Saving an update triggers realtime refresh on the correct recipients (actor + target, or whole team)

### 7 – Edit existing public team shift (non-manager member)
Open a team-scoped public shift as a regular member.

- [ ] Modal is **read-only**
- [ ] Read-only banner is visible
- [ ] No save/delete action is possible
- [ ] Close (×) button is still visible


## Goal

When a user creates a shift, the modal must support both personal shifts and
team-scoped shifts without hiding key options.

This behavior already existed and must be preserved.

## Expected Create Flow

When the user opens `create shift`, the modal must always show:
- a visible `close` button in the top bar
- shift profile
- start time
- end time
- overnight toggle
- alarms
- note

If the user can manage at least one team with the proper shift grants, the
modal must also show:
- team selector

If the user is only a viewer or simple member without the required grants,
the modal must not expose team-scoped shift creation options.

If the user selects a team, the modal must show:
- `Tutti i membri del team`
- `Un membro specifico`

If the user chooses `Un membro specifico`, the modal must also show:
- the list of members of the selected team

If the user selects a team, the modal must also explain that:
- the shift is always visible to the selected team
- team-scoped shifts do not use a separate private/public toggle

At any point, the user must be able to close the modal with the top-right
`close` button without saving changes.

## Expected Semantics

### 1. Personal private shift

If no team is selected:
- the shift is private
- the shift belongs only to the current user

### 2. Personal public shift

If no team is selected and the user explicitly makes the shift public:
- the shift remains owned by the current user
- the shift becomes visible to the members of the teams where that user belongs

### 3. Team-scoped shift

If a team is selected:
- the shift is always public to that team
- the creator can assign it to one specific team member
- or to all members of that team
- all users must see aligned data for the corresponding assignment
- users without the required grants must see it in read-only mode

## Edit Behavior

When reopening an existing team-scoped shift:
- the selected team must still be visible
- `teamId` must still be present
- a team-scoped shift must not silently become a personal shift

When reopening an existing team-scoped public shift:
- the team context must still be visible
- users without the proper role/grants must see the modal in read-only mode

## What Counts As A Regression

Any of the following is a regression:
- the `close` button disappears from the modal header
- the team selector disappears during create
- `Tutti i membri del team` is no longer available
- `Un membro specifico` is no longer available
- the member list does not appear after choosing `Un membro specifico`
- a team-scoped shift loses its `teamId` on update
- a team-scoped shift opens with different data on another team member device
- a personal public shift is not visible to the user teams that should see it
- a user without edit grants can modify a team/public shift
- a user without `ADMIN` or `MANAGE`-level team shift grants can still open the
  team assignment branch in create mode

## Manual QA Checklist

Before considering shift modal changes complete, verify:

1. Create shift with no team selected.
Expected:
- the `close` button is visible
- personal private shift flow works

2. Create personal public shift with no team selected.
Expected:
- the personal visibility toggle is available
- the shift remains personal
- the shift can be made visible to the user teams

3. Create shift as a user with team shift management grants and select a team.
Expected:
- the `close` button is visible
- `Tutti i membri del team` is visible
- `Un membro specifico` is visible
- member list appears when `Un membro specifico` is selected
- no separate team private/public toggle is required
- the modal explains that the shift is visible to the selected team

4. Open create shift as a user without `ADMIN` or `MANAGE` grants on the team.
Expected:
- personal shift creation still works
- team assignment branch is not exposed

5. Reopen a team-scoped shift in edit.
Expected:
- selected team is still present
- assignment semantics are still team-scoped

6. Reopen a public team-scoped shift as a non-manager member.
Expected:
- same shift data is visible
- modal is read-only
