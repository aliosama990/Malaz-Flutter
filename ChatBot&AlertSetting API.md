# Malaz Flutter Project — ChatBot + Alert Setting Plan

## 1) Scope

We will work only on the newly added in-scope backend areas:

### ChatBot
- `POST /Chatbot/Talk-chat`
- `GET /Chatbot/sessions`
- `GET /Chatbot/sessions/{sessionId}/messages`

### Alert Setting
- `GET /Child/{childId}/alert-setting`
- `PUT /Child/{childId}/alert-setting`

We will not assume any additional endpoints.
We will not expand scope beyond what is present in the latest Postman collection.

---

## 2) Implementation Goal

The goal is to integrate these new backend areas into the Flutter app using the same project approach already used in the existing integration work:

- contract-grounded models
- service/provider integration
- minimal UI wiring
- state management aligned with existing patterns
- consistent error handling
- clear verification after each phase

---

## 3) Execution Order

We will follow this order strictly.

### Phase A — Contract Extraction

First, confirm each endpoint contract precisely from the Postman collection before implementing anything.

#### ChatBot
We need to extract and confirm:
- request shape for `POST /Chatbot/Talk-chat`
- response shape for `POST /Chatbot/Talk-chat`
- response shape for `GET /Chatbot/sessions`
- response shape for `GET /Chatbot/sessions/{sessionId}/messages`

Important grounded note:
- the ChatBot `reply` is returned as a **JSON string nested inside a string**, not plain text directly

#### Alert Setting
We need to extract and confirm:
- response shape for `GET /Child/{childId}/alert-setting`
- request body for `PUT /Child/{childId}/alert-setting`

Confirmed settings fields:
- `safeZoneAlerted`
- `highHeartRateAlert`
- `soSenableAlert`

---

## 4) Phase B — Data Layer

After contract extraction, implement the data/service layer first, without starting with UI.

### ChatBot data layer
Create the required models and service methods for:
- chat session model
- chat message model
- talk-chat request/response handling
- safe parsing of the nested `reply` JSON string

Expected service methods:
- `sendMessage`
- `getSessions`
- `getSessionMessages`

### Alert Setting data layer
Create the required model and service methods for:
- alert setting model
- `getAlertSetting(childId)`
- `updateAlertSetting(childId, payload)`

---

## 5) Phase C — Provider / State Layer

After the data layer is stable, implement the provider/state layer.

### ChatBot provider/state responsibilities
The provider should manage:
- sessions list
- current conversation messages
- sending state
- loading state
- error state
- current `sessionId` lifecycle

### Alert Setting provider/state responsibilities
The provider should manage:
- fetching the current settings
- updating toggle values
- loading/saving state
- error/success state

---

## 6) Phase D — UI Wiring

Only after the data and provider layers are grounded and stable.

### ChatBot UI wiring
Wire the existing ChatBot screen if present, or complete the minimal required flow if partially implemented.

Minimum working flow:
- start a new chat with `sessionId = null` (or equivalent empty state based on the contract)
- save the returned `sessionId`
- reuse that `sessionId` for later messages
- display the conversation messages
- load and show session history
- open an older session and display its messages

### Alert Setting UI wiring
Wire the alert setting screen for a child.

Required flow:
- fetch settings when the screen opens
- bind UI toggles to the real backend values
- update/save changes to backend
- show clear loading/error/success states consistent with project patterns

---

## 7) Critical Grounded Notes

### ChatBot
- `reply` is not plain text; it is a **JSON string inside a string**
- parsing must be done safely
- the first message starts with `null` / no `sessionId`
- the returned `sessionId` must be stored and reused for later messages
- sessions endpoint appears to return a **raw list**
- messages endpoint also appears to return a **raw list**
- these may not follow the usual envelope pattern used in other project areas

### Alert Setting
- the endpoints live under `Child/{childId}/alert-setting`
- the implementation must use the existing child flow `childId`
- do not invent extra fields
- the update payload must remain limited to:
  - `safeZoneAlerted`
  - `highHeartRateAlert`
  - `soSenableAlert`

---

## 8) Working Strategy

We will use the same implementation strategy that worked well for the earlier project areas:

1. contract extraction
2. model + service layer
3. provider/state layer
4. minimal UI wiring
5. QA checklist and retest

We will move one small grounded step at a time.
We will not jump ahead.
We will not redesign unrelated parts.
We will not broaden scope silently.

---

## 9) Acceptance Criteria

The work is considered complete only when the following are true.

### ChatBot acceptance criteria
- a new chat can be started from the app
- the first message can be sent without a prior `sessionId`
- the app stores the returned `sessionId`
- later messages in the same conversation reuse that `sessionId`
- the app can load the sessions list
- the app can open an older session
- the app can display previous messages correctly
- bot replies are shown correctly after safe parsing

### Alert Setting acceptance criteria
- the app can fetch alert settings for a specific child
- the settings values display correctly in UI
- the user can edit the three settings
- the app can save the updated values
- the updated state is reflected correctly after save

---

## 10) QA Plan

### ChatBot QA
Verify:
- first message flow with no previous session
- multiple consecutive messages in the same session
- session history list loading
- opening an older session
- loading and error states
- malformed or failed reply parsing behavior if encountered

### Alert Setting QA
Verify:
- fetch settings for a valid child
- update one toggle only
- update all toggles
- confirm correct state after save
- unauthorized/error handling
- loading/saving UX behavior

---

## 11) Recommended Build Order

This is the recommended implementation order:

1. ChatBot contract extraction
2. ChatBot data layer
3. ChatBot provider/state layer
4. ChatBot UI wiring
5. Alert Setting contract extraction
6. Alert Setting data layer
7. Alert Setting provider/state layer
8. Alert Setting UI wiring
9. Final QA

This order is preferred because ChatBot is the more complex area due to:
- nested reply parsing
- session lifecycle handling
- raw-list response patterns

Alert Setting is smaller and more straightforward, so it can follow after ChatBot.

---

## 12) Boundaries

To keep the work safe and grounded:

- do not invent undocumented backend behavior
- do not assume extra API fields
- do not change API contracts
- do not redesign unrelated architecture
- do not touch unrelated UI or flows
- do not expand scope beyond ChatBot and Alert Setting
- keep changes incremental, reviewable, and consistent with existing project patterns
