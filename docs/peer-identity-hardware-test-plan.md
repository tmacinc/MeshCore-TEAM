# Hardware Test Plan — Team Alias & Peer Identity

Branch `PeerIdentity`. Everything below has passed the analyzer and 97 automated tests, and **none of it has run on real hardware**. This plan is what turns that into a beta.

Design detail: [alias-peer-identity-plan.md](alias-peer-identity-plan.md). User-facing behaviour: README §2b, §3, §9.

---

## 1. What is under test

| Phase | Change | Risk if wrong |
|---|---|---|
| 0 | Tracking can't use a hashtag channel; senders matched by exact name | Position shared with strangers; wrong contact overwritten |
| 1 | `Peers` table, schema **9 → 14**, map reads peer locations | Upgrade loses positions, or the map goes empty |
| 2 | CAP v2 with the team name, advert requests, contacts added in software, radio auto-add changed | The team can't find each other; a radio setting changed for the worse |
| 3 | Team channels owned by the phone | A channel or its history disappears |
| 4 | Team name shown everywhere | The wrong name shown, or a team name leaked outside the team |

**Not covered here:** Team Link (`D0sockets`). It takes this work later, per Part B of the plan.

## 2. What you need

- **Three phones** if possible, two at minimum. At least one Android and one iOS.
- **Three radios**: two on [custom firmware](https://github.com/tmacinc/MeshCore), one on stock. A spare radio is needed for the radio-switch tests.
- **One radio put into manual-add mode** before testing (from the official MeshCore app: contact settings → turn off automatic adding). This is the case that was silently broken before.
- **A repeater** in range, if you have one, for §6.4.
- **One phone with an existing install and real data** (contacts, channels, map history) for the upgrade test in §5.1. Do that test **first**, before installing anything else on it.
- A build with the debug tooling:
  ```bash
  flutter run --release --dart-define=BETA=true
  ```

### Before you start
- **Back up the phone used for the upgrade test.** The database migrates 9 → 14 in one direction. Once upgraded, an **older build cannot open it** and you would have to clear app data to go back.
- Note each radio's current contact settings, so you can compare afterwards (§6.4).
- Open **Settings → Debug log** (BETA builds) on each phone. The tags that matter:

| Tag | What it tells you |
|---|---|
| `[Migration]` `[Schema]` | Database upgrade |
| `[TELREC]` | Telemetry received and attributed |
| `[Peers]` | Peer created, bound to a key, renamed, merged |
| `[Discovery]` | Adverts and identify requests |
| `[CapabilityPublisher]` | CAP sent, including the team name |
| `[TeamRadio]` | Contacts copied to a radio, auto-add changed |
| `[ChannelSync]` | Channels synced, team channels kept |
| `[Retention]` | Old data pruned |

### Recording results
For each case: **pass / fail / not run**, the phone and radio used, and the relevant log lines. A failure needs the log around it — most of these paths only log, they don't show errors on screen.

---

## 3. Smoke test (do this first, 10 minutes)

If any of this fails, stop: something basic is broken and the rest will waste your time.

1. App starts, permission screen behaves as before.
2. The **team name prompt** appears once (§8.1).
3. Connect a radio: contacts and channels sync, contact count matches the radio.
4. Send a channel message and a DM; both arrive.
5. Turn on tracking: your own marker appears, and a second phone's marker appears within two telemetry intervals.
6. Map, waypoints and offline maps open as before.

---

## 4. Regression checks

These have nothing to do with the new work, but the changes sit underneath them.

| # | Check | Expected |
|---|---|---|
| 4.1 | Channel chat, both directions | Unchanged |
| 4.2 | DMs, including delivery ticks and retries | Unchanged |
| 4.3 | Waypoints and routes shared over the mesh | Unchanged |
| 4.4 | Offline maps, KMZ/MBTiles overlays | Unchanged |
| 4.5 | Team Config export and import | Unchanged; an imported tracking channel is marked as a team channel |
| 4.6 | Forwarding / camp mode with three or more members | Same behaviour as before; `[ForwardingPolicy]` still applies a policy |
| 4.7 | Android background: screen off 30 min while tracking | Positions keep flowing; foreground notification stays |
| 4.8 | iOS background and reconnect after being out of range | Reconnects as before |
| 4.9 | Autonomous mode device, if you have one | Still appears with the GPS icon |

---

## 5. Phase 1 — peers and the database upgrade

### 5.1 Upgrade with real data (do this first, once)
1. On the phone with an existing install and real data, note: number of contacts, number of channels, and which members show on the map with their last positions.
2. Install the new build **over** the old one (don't uninstall).
3. Open the app and check the log for `[Migration] v11->v12: peers created, N last known positions kept`, then `v12->v13`, then `v13->v14`.

**Expected:** N matches roughly the number of members you had on the map. Contacts and channels are unchanged. The map shows the same people in the same places. Map trails may be empty — that is expected, only the trail is dropped.

### 5.2 Fresh install
Install on a phone with no previous data. Expected: no migration lines, `[Schema]` creates the tables, everything works from empty.

### 5.3 Map and group list
With two phones tracking on the same channel: both appear on the map and in the group panel, with correct hop counts, battery and last-heard times. Tapping a marker opens the details, and **Direct message** works from there.

### 5.4 Remove from group
"Remove from group" on a marker hides that member. They reappear only if you clear the hidden flag (they stay hidden across restarts).

### 5.5 Last known position is kept
1. Have a member send a few positions, then switch their radio off.
2. Wait 12 hours (or change the phone clock forward 13 hours).

**Expected:** the marker disappears from the map after 12 hours, but their entry still exists — turning the clock back brings the same last position back. It is never deleted.

---

## 6. Phase 2 — discovery, CAP and contacts

This is the section with the most risk. Work through it with the debug log open.

### 6.1 A brand-new group (nobody knows anybody)
1. Factory-reset or clear contacts on two radios so they don't know each other.
2. Set up the same private tracking channel on both phones and turn tracking on.

**Expected:** within two or three telemetry intervals each phone shows the other on the map. The log shows `[TELREC] 📍 Sender ... not on radio`, then `[Discovery] 📤 Advertising ourselves` and `[Discovery] 📣 Asking "X" to advertise` alternating, stopping once resolved.

**Watch for:** a storm of adverts. Each *received* telemetry packet should produce at most one outgoing packet, delayed by up to 3 seconds.

### 6.2 A third member joins an active group
With 6.1 running, bring in a third phone and radio. Expected: everyone sees the newcomer, and the newcomer sees everyone, within a few intervals.

### 6.3 A radio in manual-add mode (was silently broken)
1. Put one radio into manual-add mode from the official MeshCore app.
2. Join the tracking channel from that phone.

**Expected:** team members are still added. The log shows `[Discovery] ➕ Adding "X" from an unstored advert`. Before this branch, discovery on such a radio never completed.

### 6.4 The radio's own contact setting
1. Note a radio's contact settings before connecting (official app → contact settings).
2. Connect it to TEAM and watch for `[TeamRadio] 🚫 Radio auto-add for people is now off`.
3. Look at the radio's settings again in the official app.

**Expected:** automatic adding of **people** is off; repeaters, room servers and sensors are **still** added. Have a repeater advertise (or wait for one) and confirm it still lands in contacts by itself. Reconnect the phone: the log must **not** repeat the change (it is idempotent).

**This is the one change that persists on the radio.** The app does not undo it — that is deliberate, and documented in README §9.

### 6.5 Heard nearby
1. With a stranger's device advertising nearby (any MeshCore node not on your tracking channel), open the Contacts tab.

**Expected:** a **Heard nearby** section lists it. **Add** puts it in contacts and the row disappears. **Dismiss** hides it; it comes back only when that node advertises again. Team members never appear in this list.

### 6.6 Someone switches radio, keeping the same name
1. Member B pairs a different radio and keeps the same radio name.
2. Member B turns tracking on.

**Expected:** phone A notices the key changed — `[Discovery] 🔑 "B" is using a different radio than we have` — asks B to advertise, and ends up with B's new key. A can then DM B successfully (proving the new key is in use, not the old one). B's peer, alias and history stay as one person, not two.

### 6.7 Someone renames their radio
Member B renames their radio (which reboots it). Expected: A picks up the new name after B's next advert; `[Peers] ✏️ Radio renamed` appears, and B stays one peer with their history intact.

### 6.8 Contact table full
Fill a radio's contact table (or use one already near its limit), then join a team. Expected: a one-time prompt about the table being full, no crash, and no silent eviction of existing contacts.

### 6.9 Mixed app versions
Have one phone on the **previous release** in the same tracking channel.

**Expected:** the old app shows **no junk text** in the channel — no `#CAP:` or `#CAP:R:` lines in chat. Positions still flow both ways. The old app simply doesn't show team names.

### 6.10 Periodic CAP
Leave a group running for over an hour. Expected: one `[CapabilityPublisher] ✅ Published #CAP (periodic)` per hour per phone, give or take five minutes of jitter — not a burst.

---

## 7. Phase 3 — team channels

### 7.1 Marking
Long-press a private channel → **Mark as team channel**. Expected: a group icon and *Team channel* appear in its subtitle. The option is absent on the public channel and on hashtag channels.

### 7.2 The tracking channel marks itself
Choose a channel for tracking in Settings. Expected: it becomes a team channel without being asked.

### 7.3 Switching radio keeps the team
1. On a phone with a team channel, some chat history in it, and members on the map, pair a **different radio**.
2. Let the sync finish.

**Expected:** the team channel is still listed, greyed out, marked *Not on this radio*, and its history opens. Other channels are replaced by the new radio's. Team contacts are copied to the new radio (`[TeamRadio] ➕ Adding N team contacts`), followed by one advert. Everyone's last known positions are still on the map.

### 7.4 Adding it back
Tap the message box in that channel (or pick it for tracking). Expected: *Add to radio?* explaining the radio must hold it. Accept, and the channel loses the greyed-out state, gets a real slot number, and messages send normally.

### 7.5 No free slots
Fill the radio's channel slots, then try 7.4. Expected: a clear message that the slots are full, no crash, nothing silently overwritten.

### 7.6 Deleting with no radio connected
Disconnect the radio, delete a team channel. Expected: it goes from the phone with its history. Reconnect the radio: because the radio still holds the slot, the channel returns as an **ordinary** channel with **no history**.

### 7.7 Deleting while connected
Delete a team channel with the radio connected. Expected: it goes from both, and does not come back after a sync.

### 7.8 Team only
Toggle **Team only** on the Channels tab and the Contacts tab. Expected: one shared toggle; the lists show only team channels and team members; toggling back restores everything.

### 7.9 Retention
Team channel history is kept for 30 days, map trails for 24 hours. Fastest check: move the phone clock forward 31 days, restart the app, look for `[Retention] 🧹`. Expected: old team messages and old trail points go; **last known positions and peers stay**.

---

## 8. Phase 4 — the team name

### 8.1 First launch
Fresh install. Expected: the prompt appears once, after permissions and **before** a radio is needed. The field is **empty**, with the radio name (if known) as grey placeholder text. It explains what Save and Skip each mean, and where to change it later.

### 8.2 Skip keeps today's behaviour
Skip it. Expected: it never reappears, and you appear to your team under your radio name, exactly as before this branch.

### 8.3 Setting a name
Set a team name on phone A, with phone B watching.

**Expected on B, within a few minutes** (on CAP, not on every position): A's marker, contact row, chat messages and notifications all switch to the team name, with A's radio name underneath in the contact list and a group icon. `[Capability]` on B shows the alias arriving.

### 8.4 The radio name stays private to the mesh
1. On B, long-press one of A's messages → **Reply**.
2. Look at what is inserted.

**Expected:** `@[A's radio name]`, never the team name. Check the same in a public channel: nothing that reaches the mesh should contain a team name.

### 8.5 A stock client's view
With a plain MeshCore app in the same channel, confirm it only ever sees radio names, and no capability messages appear as chat.

### 8.6 Changing and clearing
Change the team name in Settings and confirm B follows within a few minutes. Clear it (empty field) and confirm B falls back to your radio name.

### 8.7 Two people, one name
Give A and B the same team name. Expected: on C, both are shown with a short ID appended so they can be told apart. Change one, and the suffix goes away.

### 8.8 Anonymize the radio
Rename A's radio to something anonymous while a team name is set. Expected: A's team still sees the team name; anyone outside sees only the anonymous name. A's messages, history and map position stay attached to the same person.

### 8.9 Long and unusual names
Try a 24-character name, one with emoji, and one with a colon. Expected: no truncation halfway through a character, no broken parsing on the receiving phone, and the name still arrives.

---

## 9. Endurance

Worth running once the individual cases pass.

| # | Check | Expected |
|---|---|---|
| 9.1 | Three phones tracking for 4+ hours | No advert storms; the mesh stays usable; battery in line with before |
| 9.2 | Walk out of range and back, twice | Members go stale and come back; no duplicate peers |
| 9.3 | Airplane mode on a phone for 30 min | Recovers without duplicate contacts or channels |
| 9.4 | Restart both app and radio a few times | Peer count stays stable — a growing peer count means identity is being split |

**A good end-of-run check:** on each phone, the number of team members shown should equal the number of people actually in the group. More means peers are being duplicated; fewer means identity is being merged wrongly.

---

## 10. Known caveats (not bugs)

- **The radio's auto-add setting stays changed** after using TEAM (§6.4). Turn it back on from any MeshCore app if you stop using TEAM.
- **No downgrade.** A database at schema 14 cannot be opened by an older build; going back needs app data cleared.
- **Map trails are lost on upgrade.** Last known positions are not.
- **Team names take minutes, not seconds, to spread.** They ride CAP, which is event-driven plus hourly — that is what keeps them off the telemetry path.
- **Adverts heard while the phone is disconnected are lost**, as before; discovery resumes on reconnect.
