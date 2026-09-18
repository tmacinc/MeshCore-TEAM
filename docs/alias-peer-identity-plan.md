# Team Alias, Peer Identity and Hybrid Sync — Plan

Status: Phases 0-4 are committed on branch `PeerIdentity`; none of it is device-tested yet. Remaining: device testing, then Part B (Team Link) when `D0sockets` takes this.
Target branch: `dev`. Team Link (`D0sockets`) adopts this afterwards; its changes are in [Part B](#part-b--team-link-d0sockets-update-spec).

---

## 1. Goals

- **Team alias.** Each user has an in-app name that only members of their team channel can see. The radio name stays, and users are encouraged to anonymize it, because everyone on the mesh can see it.
- **Stable peer identity.** Each person gets one local record, whichever way we heard about them: radio name, radio key or Link app ID. That record survives radio switches, renames and Link-only use.
- **Reliable discovery.** Team members find each other quickly without heavy traffic on the mesh, including when the radio is in manual-add mode or someone switches radios.
- **Hybrid source of truth.** Team channels, team identities and team history belong to the phone. Everything else still follows the radio.

**Non-goals**
- No change to chat or DM wire formats. The firmware adds the radio name to channel messages, and DMs are addressed by key.
- No full-key contact exchange over CAP. CAP is unsigned, so a claimed key could be used to hijack DMs; contacts always come from signed adverts.
- No history sync. Retention is local only.

## 2. Terms

| Term | Meaning |
|---|---|
| **Radio name** | The node name set on the radio. It is sent in every advert and added by the firmware to every channel message. Anyone on the mesh can see it. |
| **Alias** | The in-app team name. It is sent only in CAP on the tracking channel. |
| **Peer** | A local record for one person (`Peers` row, `peerId`). `peerId` never leaves the phone. |
| **Team channel** | A private channel with a secret key (never public or hashtag) that the phone has marked as team. See §7. |
| **Team member** | A peer seen sending TEL, topology or CAP on a team channel. |
| **Resolved** | The peer has a key, and that key is a contact on the current radio. |
| **Known, not on radio** | The peer has a key, but the current radio doesn't have that contact (e.g. after a radio switch). |
| **Unresolved** | We only have a radio name and no key yet. This is a placeholder peer. |

## 3. Data model

### 3.1 New tables

**`Peers`**

| Column | Type | Notes |
|---|---|---|
| `peerId` | int, auto-increment PK | Local only |
| `radioPublicKey` | blob(32), nullable, unique | Full key, from adverts or contact sync. Needed to add the contact to a new radio. |
| `radioKeyPrefix` | text(12), nullable | From CAP v2 before the full key is known. Always equals the start of `radioPublicKey` once that is set. |
| `appIdentityId` | text(16), nullable, unique | Link uploaderId (used on `D0sockets` only) |
| `radioName` | text, nullable | Last seen radio name. Used for exact matching of channel senders and for mentions. |
| `alias` | text, nullable | From CAP v2 |
| `aliasUpdatedAt` | int, nullable | |
| `capFlags` | int, nullable | Replaces `ContactCapabilityService` |
| `capObservedAt` | int, nullable | |
| `isTeamMember` | bool | Set on the first TEL, topology or CAP message on a team channel. Never cleared automatically. |
| `firstSeen`, `lastSeen` | int | |
| `lastTeamChannelHash` | int, nullable | |

**`PeerLocations`** replaces `ContactDisplayStates`
- Primary key `peerId`.
- Columns: last lat/lon, `lastSeen`, `lastChannelIdx`, `lastPathLen`, `isManuallyHidden`, `hiddenAt`, `totalTelemetryReceived`, `isAutonomousDevice`.
- **Never pruned.** The last known position is kept forever for search and rescue.

**`PeerPositionHistory`** replaces `ContactPositionHistories`
- Keyed by `peerId`, with the same columns as today.
- Kept for **24 hours** (`RetentionService`). The trail was already thinned to 50 points per contact, but nothing pruned it by age.

### 3.2 Changed tables

- **`Contacts`**
  - Stays a mirror of the current radio's contact list, still wiped on a radio switch.
  - No `peerId` column was added in the end: a contact is matched to its peer by public key, which can't go stale.
- **`Channels`**
  - Add `isTeam`.
  - Add radio-presence tracking. **Use the same columns as `D0sockets`**, so the later merge converges: `firmwareConfirmed` (false = not on the current radio) and `isLocalOnly`.
  - Channels that aren't on the radio take an index from `D0sockets`' negative sentinel pool.
- **`Messages`**
  - Add `senderPeerId` (nullable). `senderName` stays: message IDs are derived from it (§5.6), and it is the fallback for display.
  - Team-channel messages and team-peer DMs are no longer tied to a radio (§9).

### 3.3 Settings (SharedPreferences)
- `teamAlias`
- `teamAliasPrompted`: the first-launch and upgrade prompt has been shown (via Skip or Save).
- `teamOnlyFilter`
- `savedAutoAddChatBit`: so the radio's auto-add setting can be restored (§6.5).

### 3.4 Removed
- `ContactCapabilityService` and its prefs key. Capability state moves into `Peers`. The old entries are keyed by name, they're stale, and nothing reads them.
- `_findBestContactMatch` (already removed in Phase 0).

### 3.5 Migration (breaking)

- **Version number.** `schemaVersion` jumps **9 → 12**, because `D0sockets` already uses 10 and 11.
  - Port `_reconcileSchema()` from `D0sockets` to `dev` first.
  - It only adds tables and columns, so the drop/replace steps below need an explicit `from <= 11 && to >= 12` step.
- **Explicit step:**
  1. Create `Peers`.
  2. **Copy** `ContactDisplayStates` into `Peers` and `PeerLocations`, one peer per `publicKeyHex`, with `radioName` taken from `name`. This keeps last known positions across the upgrade.
  3. Drop `ContactDisplayStates` and `ContactPositionHistories`. Losing up to 24 hours of history is accepted.
  4. Add the new columns.
  5. Set `isTeam = true` on the channel that is currently the tracking channel, if it is eligible.
- **Prefs:** delete `contact_capability_state_v1`.

## 4. `PeerDirectory` service

This is the lookup layer. Handlers turn whatever identifier arrives into a `peerId`; screens and anything sent go back through it.

```dart
class PeerDirectory extends ChangeNotifier {
  // inbound
  PeerResolution resolveChannelSender(String radioName, {int? teamChannelHash});
  Peer? byRadioKey(Uint8List keyOrPrefix);
  Peer? byAppId(String appId);                       // Link
  Future<Peer> upsertFromCap(String radioName, CapabilityMessage cap, int channelHash);
  Future<void> bindRadioKey(Uint8List fullKey, String radioName);  // advert / contact sync
  Future<Peer> merge(int keepId, int dropId);

  // outbound
  String displayName(int peerId);   // alias → radioName → short key
  String meshName(int peerId);      // always radioName; used for @mentions/replies
  Stream<Peer?> watch(int peerId);
  Stream<List<Peer>> watchTeam();
}

enum ResolutionState { resolved, knownNotOnRadio, unresolved, ambiguous }
```

**Rules for `resolveChannelSender`, applied in order:**
1. A peer whose CAP-bound `radioKeyPrefix` matches a peer with this `radioName`.
2. A peer with this exact `radioName` and a bound key.
3. A contact on the current radio with this exact name. Bind it to a peer.
4. Otherwise, create or return a placeholder peer (`radioName` only, `unresolved`).

**Collisions.**
- If two peers with different keys share a radio name, the result is `ambiguous`.
- Attribute the TEL to the peer with the most recent CAP, and start a request (§6.3).
- Both are shown under their alias with no suffix (Tom's call): identity is the peer, the alias is display only, and telling people apart is left to the group.

**Merging.** A merge moves `PeerLocations` (keeping the newer row), history, `Messages.senderPeerId` and `Contacts.peerId` onto the surviving peer. It is triggered by:
- a CAP whose key prefix matches a different peer;
- an advert whose key matches a placeholder with the same name;
- on Link: an app ID and a radio key seen together (Part B).

**Call sites to change.** The TEL, topology, CAP and waypoint handlers and the DM receive path in `message_repository.dart`; `forwarding_v1_strategy` (key its state by `peerId`); `forwarding_policy_service`; `capability_publisher`; and the display sites in §8.

## 5. Wire protocol

### 5.1 CAP v2 advertisement

```
#CAP:2:<flags_hex2>:<radioKeyPrefix_hex12>:<alias...>
```

- **Fields.** `alias` is the last field and may contain `:`; parse it as the remainder. An empty alias means "no alias set".
- **Flags.** The v1 flag bits are unchanged.
- **Byte budget** (MeshCore text limit about 160 bytes, including the `"RadioName: "` prefix):

  | Part | Bytes |
  |---|---|
  | `#CAP:2:1f:` | 10 |
  | Key prefix + `:` | 13 |
  | Alias (≤ 24 UTF-8 bytes) | ≤ 24 |
  | **Payload total** | **≤ 47** |
  | Radio name prefix, added by the firmware | ≤ 33 |

- **Encoding.** Sent as UTF-8; the `writeString` path handles it.
- **Forward compatibility.** New parsers accept v1 and v2 and ignore trailing fields they don't know. Future fields go **before** the alias, behind a new version number.
- **Older app versions.** Their parser requires exactly 2 fields, so v2 is intercepted by prefix and dropped silently. Nothing reads peer capabilities today, so they lose nothing.

### 5.2 CAP advert request

```
#CAP:R:<targetKeyPrefix_hex12 or ->:<targetRadioName...>
```

- The radio name comes last and may contain `:`.
- Older versions: `int.tryParse("R")` fails, so the request is dropped silently.
- **Handling a request.** Respond when the target radio name equals ours. If a key prefix is given and doesn't match ours, the requester has an old key for us (we switched radios), so respond anyway.
  - The response is one flood self-advert plus our CAP v2.
  - Wait a random **0–3 s** before responding.
  - **Merge requests:** all requests aimed at us within **10 s** produce one response. This merges simultaneous requests; it is not a rate limit.

### 5.3 When CAP v2 is sent
- **On change**, after a 1-minute debounce as today, when any of these change: flags, alias, radio name, or tracking channel.
- **When a new contact appears**, 2 minutes later as today.
- **After a reconnect** following a rename.
- **Periodically:** every **60 minutes ± 5 minutes of random jitter**. The periodic send ignores the "unchanged" check.
- The "unchanged" check compares `(flags, alias, radioName, channelHash)`, not just the flags.
- CAP is only sent on a channel where `canBeTrackingChannel` is true (Phase 0).

### 5.4 TEL / topology
Unchanged.

### 5.5 Mentions and replies
Always use `meshName` (the radio name), never the alias. Otherwise, replying in a public channel would leak the alias.

### 5.6 Message IDs
- They stay derived from what was sent: sender name, timestamp and content.
- A local `peerId` must never feed into an ID. Two phones that have matched a sender differently would compute different IDs and stop removing duplicates.

## 6. Discovery

### 6.1 Principles (Tom's decisions)
- A TEL from an unknown sender triggers a flood self-advert. Both sides do this, which is what lets a brand-new group, or a new member joining an active one, find each other.
- **Never send an advert in response to an advert** (commit `b9c1682`, #55): too much traffic on real meshes.
- **No rate limiting or backoff.** The next TEL retries straight away. Stop only when the sender goes stale.
- Keep it to **one packet per received TEL**, to limit collisions during discovery.
- There are no watch-only users: sharing your location is required to see others.

### 6.2 Per-sender state (unresolved or known-not-on-radio)

| Event | Action (after a random 0–3 s delay) |
|---|---|
| TEL/topology from an **unresolved** sender, odd attempt | Flood self-advert |
| TEL/topology from an **unresolved** sender, even attempt | CAP request for that radio name |
| TEL/topology from a **known-not-on-radio** peer | Add their contact from the stored key (§6.4). If that fails, send a CAP request. |
| CAP v2 key prefix ≠ the stored key for that name | CAP request, key prefix `-` (they switched radios) |
| No TEL from that sender for **5 minutes** | Stop (same stale window as `forwarding_v1_strategy`) |
| Resolved | Clear the state |

Attempt counters live in memory only.

### 6.3 Why add the request
The self-advert only introduces *us*. The request makes the other side introduce *themselves*. This covers:
- one-way radio links;
- a sender who already knows us, so our TEL never triggers an advert from them;
- a radio switch where the radio name stayed the same.

### 6.4 Adding contacts in software
Verified in both upstream and tmacinc firmware (`BaseChatMesh::onAdvertRecv`, `MyMesh::onDiscoveredContact`, `updateContactFromFrame`):

- **`PUSH_ADVERT` (0x80), public key only:** sent when the contact **was** saved (auto-add). The existing contact sync handles it.
- **`PUSH_NEW_ADVERT` (0x8A), full contact record:** sent when the contact was **not** saved. That happens when:
  - the radio is in manual-add mode;
  - the advert is beyond the auto-add hop limit;
  - or the contact table is full.
- **Today the app ignores the 0x8A payload**, so discovery silently fails on radios in manual-add mode.
- **The 0x8A frame layout is byte-identical to `CMD_ADD_UPDATE_CONTACT` (9) after byte 0.** The route in it is unknown (flood).

**How to handle 0x8A**
1. Parse the key and name with the existing contact-record parser.
2. **Add the contact** if the key matches a team peer, or if the name matches an unresolved or ambiguous sender currently being tracked. To add it, copy the frame, set byte 0 to `9`, and send it. Then bind the key to the peer and run the contact sync.
3. Otherwise ignore it; the radio is in manual-add mode.
4. On a table-full error (`ERR_CODE_TABLE_FULL`), show a one-time prompt offering to remove the oldest non-favourite, non-team contact. Never evict one silently.

**Adding stored team contacts to a new radio.** Build a new add-contact frame from `Peers.radioPublicKey`:
- route unknown (`out_path_len = 0xFF`), zero path;
- name encoded as UTF-8, padded to 32 bytes;
- type `ADV_TYPE_CHAT`, flags `0`.

`BleCommands.buildAddUpdateContact` currently gets the flags, route and name encoding wrong; **replace it**. It has no callers.

### 6.5 Radio auto-add
- **Turn off auto-add for chat nodes, on every connect**, so the radio stops filling up with strangers:
  - Set the manual-add flag.
  - `autoadd_config` is only consulted once the manual flag is set, and both prefs default to 0 — so on a stock radio the flag alone would stop repeaters, room servers and sensors being added as well. Coming from that state, set their bits explicitly (keeping `AUTO_ADD_OVERWRITE_OLDEST`); coming from a radio already in per-type mode, only clear `AUTO_ADD_CHAT`.
  - Idempotent: a radio already set that way is left alone.
- **No restore, and nothing saved.** Managed contacts are how the app works, so there is no mode to leave and no saved state to get out of step (an earlier draft had a `manageRadioContacts` setting and saved originals; both are gone). Someone who stops using TEAM turns auto-add back on from any MeshCore app.
- **`CMD_SET_OTHER_PARAMS` (38)** also overwrites `telemetry_mode_*`, `advert_loc_policy` and `multi_acks`.
  - Parse them from `SELF_INFO` (bytes after lat/lon: `multi_acks`, `advert_loc_policy`, packed telemetry modes, `manual_add_contacts`).
  - Send them back unchanged.
- **Consequences** (documented for users in README §9, and in `TeamRadioService`):
  - Adverts heard while the phone is disconnected aren't saved. Acceptable: TELs aren't processed then either, so discovery resumes on reconnect.
  - Nobody outside the team is added silently. Their advert is listed under "Heard nearby" on the Contacts screen (§7.7), where the user adds or dismisses them.

### 6.6 New radio
On the first connection to a radio this phone hasn't used before:
1. Sync as normal.
2. Add stored team contacts to the radio if there's space (§6.4).
3. Offer to add team channels (§7.3).
4. Send one flood self-advert.
5. Send CAP v2.

## 7. Channels (hybrid)

### 7.1 Channel types
- **Public:** slot 0 / `isPublic`.
- **Hashtag:** key derived from the name (`ChannelDataKind.isHashtag`, Phase 0).
- **Private:** a secret key.
- **Team:** a private channel with `isTeam = true`. A public or hashtag channel can never be a team channel.

### 7.2 How a channel becomes a team channel
A private channel becomes a team channel when:
- it is selected as the tracking channel (the picker only lists eligible channels);
- it is imported through Team Config or a team share link;
- it is created in the app as a team channel;
- or the user marks it manually from the channel options.

It stays a team channel if tracking moves elsewhere, until the user unmarks or deletes it.

### 7.3 Sync rules (`fetchChannelsFromFirmware`)
- **Non-team channels:** the radio decides, as today.
- **Team channel on the radio:** update its slot index and set `firmwareConfirmed = true`.
- **Team channel not on the radio:** keep it, set `firmwareConfirmed = false`, and give it a sentinel index. **Don't delete it.**
- **Radio switch:** team channels, their messages, and team-peer DMs are kept. Non-team data is wiped as today.

### 7.4 Team channels not on the radio
- Shown in a different colour in the channel list. They can be opened and the history read.
- **Tapping the message box, or turning tracking on for that channel**, shows: *"Add this channel to your radio? It must be on the radio to send messages or use it for tracking."*
  - If the radio has no free slot, show the slot limit instead.
- Adding it uses the existing `_registerChannelWithFirmware`.

### 7.5 Deleting a team channel
- **Radio connected:** clear its slot on the radio (as today), then delete the channel and its messages locally.
- **Radio not connected:** delete locally only. If the radio still has it, it comes back on the next connect as an **ordinary** channel with no history. There is no pending-delete.
- Either way, clear the tracking setting if it pointed at this channel.

### 7.6 Team-only filter
- One saved toggle (`teamOnlyFilter`).
- Applies to the channel list (team channels only) and the contact list (team-member peers only).
- The map already shows only the tracking channel.

## 8. Alias and naming UI

**First launch**
- After the permissions screen, and before any radio is needed: a *Team name* prompt.
- Existing users see it once after upgrading. `teamAliasPrompted` records that it has been shown, whichever button was used.
- **The field starts empty.** Show the current radio name, if known, as greyed-out placeholder text.
  - Don't pre-fill the field. Otherwise tapping Save stores a copy of the radio name, which goes stale when the radio is renamed.
  - If the text entered equals the radio name, store it as blank.
- **Buttons:** *Skip* and *Save*. The prompt text must make each outcome clear:
  - **Save (with a name):** "Your team will see this name. Only people on your team channel can see it."
  - **Skip, or Save with the field empty:** "Your team will see your radio name. Everyone on the mesh can see your radio name."
  - **Always shown:** "You can set or change your team name later in Settings → *Team name*."
- **Skipping behaves exactly like today:** you appear everywhere under your radio name.
- **Settings uses the same wording.** When blank, the field shows "Using radio name (*name*)".

**Radio name dialog.** Change `identityNameExplanation` and the connection-screen dialog text to: *visible to everyone on the mesh, including people outside your team; consider an anonymous name.*

**Settings.** A *Team name* field next to the radio name, with a short explanation of each.

**Validation**
- Trim whitespace, strip control characters, limit to **24 UTF-8 bytes** (count bytes, not characters).
- If empty, show the radio name locally and send an empty alias field.

**Where display names come from.** `PeerDirectory.displayName` everywhere a person is shown:
- map markers (`map_screen.dart`: 433, 456, 603, 3337);
- channel chat sender names;
- contact list and search/sort;
- DM title;
- notifications (`message_notification_service.dart:225`);
- waypoint creator shown in the UI;
- forwarding debug screen.

**Contacts and DMs**
- **Team members:** alias as the main name, with the radio name underneath and a team badge.
- **Everyone else:** radio name, as today.

**Stored identifiers stay on the radio name.** `waypoint.creatorNodeId` stays the radio name (used for de-duplication); only the displayed creator name changes.

**Localization.** Every new string goes into all 7 `.arb` files. Also fix the hardcoded `'Saving...'` at `main_navigation_screen.dart:280`.

## 9. Retention

| Data | Retention |
|---|---|
| Team-channel messages | Fixed **30 days** (proposed) |
| Team-peer DMs | Fixed **30 days** (proposed; open) |
| Other messages | Unchanged: kept until channel deletion or radio switch |
| `PeerPositionHistory` | **24 hours** |
| `PeerLocations` (last known position) | **Forever** |
| `Peers` | Forever. Contact auto-purge (`contactAutoPurgeDays`) removes the radio contact only. |

Prune at startup and once a day, using `MessagesDao.deleteMessagesOlderThan` plus a new history DAO method.

## 10. What a radio switch does

| Data | Today | New |
|---|---|---|
| Peers, aliases, last known positions | n/a | Kept |
| Team channels + messages | Deleted | Kept; channels offered for adding to the new radio |
| Team-peer DMs | Deleted | Kept |
| Team contacts | Deleted | Radio mirror wiped; added again from `Peers` if the radio has space |
| Other channels, contacts, messages | Deleted | Deleted, then re-synced from the new radio |
| Waypoints | Kept | Kept |

## 11. Phases

Each phase can ship to beta on its own.

| Phase | Scope | Main files |
|---|---|---|
| **0** ✅ | Hashtag tracking guard; exact-name matching | done (`2263fea`) |
| **1** ✅ | Port `_reconcileSchema`, v12 migration, `Peers` / `PeerLocations` / `PeerPositionHistory`, `PeerDirectory`, handlers resolve to peers, forwarding keyed by radio key, display via `displayName` (no alias yet, so it shows the radio name), retention pruning. Done in `d3d5426`; also restricted the discovery self-advert to the tracking channel and team attribution to private channels, and fixed the forwarding debug screen's key-case mismatch | `database/`, new `services/peer_directory.dart`, `message_repository.dart`, `forwarding/*`, `map_screen.dart`, `contacts_screen.dart`, `channel_chat_screen.dart`, `direct_message_screen.dart`, `message_notification_service.dart` |
| **2** ✅ | CAP v2 + request; per-sender discovery state; 0x8A software add; new add-contact frame builder; auto-add handling with `SELF_INFO` fields; new-radio sequence; periodic CAP. Done in `7a387b8` + `3496977`. Deviations: chat auto-add is turned off while tracking with no setting yet (the toggle belongs with the Phase 4 UI), and the contact push fills at most 75% of the radio's table | `capability_message.dart`, `capability_publisher.dart`, `message_repository.dart`, `ble_commands.dart`, `ble_responses.dart`, `connection_viewmodel.dart` |
| **3** ✅ | Channel types, `isTeam`, hybrid sync, not-on-radio UI and prompt, delete rules, team-only filter, persistence across radio switches. Schema 14. Deviations: team channels are offered to a new radio on use rather than pushed on connect (Tom: pushing is optional), and `_addColumnIfMissing` makes column additions tolerant of a database that already has them | `channel_repository.dart`, `channels_screen.dart`, `channel_chat_screen.dart`, `connection_viewmodel.dart` (`_clearCompanionSessionData`), `team_config_service.dart`, `settings_screen.dart` |
| **4** ✅ | Alias setting, first-launch and upgrade prompt, radio-name wording, team badges, collision suffix, l10n ×7, `README.md`. Deviation: the auto-add toggle discussed here was dropped entirely (see §6.5) | `main.dart`, `main_navigation_screen.dart`, `connection_screen.dart`, `settings_screen.dart`, `settings_service.dart`, `l10n/*.arb` |

## 12. Testing

**Unit tests**
- CAP v1/v2/request parse and encode: colons in names, UTF-8 byte limit, and confirming that older-style parsing rejects v2 and requests.
- `PeerDirectory` resolution order, collisions and merge.
- Migration from a v9 database with display states: last known positions kept.
- Retention pruning.
- Converting a 0x8A frame into an add-contact command.
- Byte layout of the new add-contact frame.

**Manual, multiple devices**
1. A new group where nobody has anyone as a contact, radios in auto-add mode **and** in manual-add mode.
2. A new member joins an active group.
3. Someone switches radio but keeps the same radio name.
4. Someone renames their radio.
5. Contact table full.
6. Mixed app versions in one group (old clients must not show `#CAP:` text).
7. A team channel deleted while offline comes back as an ordinary channel.
8. Radio switch keeps team history and last known positions.
9. A reply in a public channel uses the radio name, never the alias.

## 13. Risks

- **Discovery traffic.** Unlimited retries plus requests could collide in dense groups. Watch it with the debug log; the random 0–3 s delay is the main mitigation.
- **Aliases can be spoofed** by anyone who has the channel key; that is within the trust model. Signed alias claims (Link app key) are possible later.
- **Auto-add changes** affect other MeshCore apps using the same radio. Restore the setting on disable, and say so in the UI.
- **Breaking migration.** Up to 24 hours of position history is lost; last known positions are kept.
- **Contact table capacity** varies by firmware; handled by the §6.4 prompt.

---

# Part B — Team Link (`D0sockets`) update spec

Link ships as a separate app in a private test group. Changes flow **dev → D0sockets only**, and breaking changes to Link's own formats are acceptable.

**B1. Envelope IDs stay as they are.**
- `CloudEnvelope.computeEnvelopeId` hashes the sender name, timestamp and full plaintext.
- Every mesh listener must be able to compute the same value from what it heard, and a mesh listener only has the sender name.
- Anything based on a resolved peer would differ between phones and break duplicate removal. Identity improvements apply only **after** duplicate removal (attribution and display).

**B2. Replace the `CLOUD:` keys with `Peers`.**
- **Flagged (off-mesh) envelopes:** `usableSenderUploaderId` → `PeerDirectory.byAppId`, creating a peer with `appIdentityId` if needed.
- **Unflagged mesh mirrors:** `resolveChannelSender(senderName)`.
- **Delete:** `cloudPeerKeyFromUploader`, `cloudPeerKeyFromName`, `kCloudPeerKeyPrefix`, and the `CLOUD:%` filters in `message_repository.dart` and `forwarding_policy_service.dart`.
- **Forwarding** excludes peers with `radioPublicKey == null`, instead of matching the string prefix.
- **Tests:** rewrite `test/database/cloud_peer_display_state_test.dart` against `PeerLocations`.

**B3. Names**
- **`localDisplayName` is replaced by `teamAlias`,** so radio-less users and radio users have one setting.
- **Keep `lastKnownRadioName` / `effectiveSelfName`** for sender-name stability on the wire (B1).
  - For a phone with no radio, the effective name is the alias.
  - Changing the alias only affects messages sent afterwards, which is fine.
- `team_link_prompt.dart` uses the alias prompt from Phase 4 instead of its own name prompt.

**B4. `#LINK:` entries carry the origin's app ID**
- Add an origin app ID field (16 hex characters) to each entry whose origin is off-mesh. Bump the container version; the test group updates together.
- Mesh-only receivers use it to link the entry to a peer through `byAppId`. A radio-less origin has no radio name to resolve, and its alias isn't unique.
- Keep `0x1E`/`0x1F` reserved as today.

**B5. CAP over Link**
- Radio-less phones send CAP v2 over Link, with the key prefix field set to `-`.
- Gateways inject it onto the mesh inside `#LINK:`, like other tracking-channel traffic.
- When a CAP arrives in a **flagged** envelope from a phone that has a radio, link `appIdentityId` ↔ `radioKeyPrefix` and merge the peers. This is how one person seen through both Link and mesh becomes one peer, **without putting the app ID in CAP**.

**B6. Channels**
- `isLocalOnly` / `firmwareConfirmed` / the sentinel index pool now come from `dev` (§3.2, §7.3). Remove Link's separate reconciliation code where it duplicates them.
- A local-only channel is a team channel that has never been on a radio.
- The "Add to radio" prompt (§7.4) needs Link wording: with Link active, messages can be sent without the radio; the radio is only needed to reach mesh-only members.

**B7. Schema.** Once `dev` is at v12 with `_reconcileSchema`, merging into `D0sockets` needs no renumbering. Keep D0sockets' duplicate v8→v9 blocks as they are.
