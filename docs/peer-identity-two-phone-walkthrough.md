# Two-Phone Walkthrough — Peer Identity

A session-by-session script for testing the `PeerIdentity` branch with **two phones and two radios**, logging one phone at a time. The full reference is [peer-identity-hardware-test-plan.md](peer-identity-hardware-test-plan.md); this is the order to actually do things in.

---

## Setup

### Names used below

| | Phone A | Phone B |
|---|---|---|
| Radio | **R1** | **R2** |
| Radio name (set on the radio) | `R1-radio` | `R2-radio` |
| Your name (set in the app) | `Anna` | `Ben` |

Radio names and app names are deliberately different, so you can always tell which one is on screen. Rename the radios before starting if needed (Connection → device name).

### Logging
- **Phone A is the logged phone**, on USB:
  ```bash
  flutter run --release --dart-define=BETA=true
  # or, with a build already installed:
  adb logcat -s flutter
  ```
- **Phone B** runs a BETA build too. Its log is readable on the phone: **Connection tab → document icon, top right**. Use it whenever a step says *"B's log"*.
- Each session says which phone's log matters.

### Before you start
- If Phone A has an **existing install with real data**, keep it — session 1 tests the upgrade. **Back it up first**: the upgrade can't be undone, and an older build can't open the upgraded database.
- Phone B should be a **fresh install**, so both paths get tested.
- Keep the phones a few metres apart, radios in direct range of each other (no repeater needed).

### Recording results
For each step, note **pass / fail**, plus the relevant log lines for any failure. Section numbers in brackets point to the full test plan.

---

## Session 1 — Install and upgrade (log A) · 10 min

1. **Phone A (existing install):** note your contact count, channel list, and who is on the map. Install the new build **over** the old one.
2. Open the app on A. In the log look for:
   ```
   [Migration] v11->v12: peers created, N last known positions kept
   [Migration] v12->v13: heard_adverts
   [Migration] v13->v14: channels isTeam, firmwareConfirmed
   ```
   ✅ N is about the number of people you had on the map. Contacts and channels unchanged. Same people in the same places on the map (their trails may be gone — expected).
3. **Phone B (fresh install):** open the app. ✅ No migration lines in B's log; everything starts empty.

## Session 2 — The name prompt (either phone) · 5 min

4. **On both phones**, after the permission screen, the name prompt appears **once**. Check:
   - ✅ Titled *Set your name*.
   - ✅ Field is **empty**; the radio name shows as grey placeholder text if a radio is known.
   - ✅ It explains what Save does, what happens *if you skip this*, and that you can change it later in Settings.
5. **Phone A:** type `Anna`, **Save**.
6. **Phone B:** tap **Skip**.
7. Restart both apps. ✅ The prompt does **not** come back on either.
8. **Settings → General** on each:
   - A: ✅ *Name (hidden outside your team)* shows `Anna`.
   - B: ✅ shows *Using radio name (…)*.

## Session 3 — Connecting the radios (log A) · 10 min

9. **A → R1**, **B → R2**. Let each sync finish.
10. A's log: ✅ `[TeamRadio] 🚫 Radio auto-add for people off (config 0x1c)` (or similar, with bits for repeaters, room servers and sensors). ✅ On a **second** connect it does **not** repeat.
11. B's log: same line once. [6.4]
12. **If you have the official MeshCore app**, look at R1's contact settings: ✅ auto-add is off for people/companions, **on** for repeaters, room servers and sensors.
13. **Channels tab, both phones:** ✅ *Public* shows normally — **no** *Not on this radio*.

## Session 4 — A shared team channel (log A) · 10 min

14. **Phone A:** create a private channel `TeamTest`. Share it to B (QR or link). **Phone B:** join it. Do this with both radios **connected**, so the channel lands on each radio.
15. **Phone B — the quick toggle** (regression from the first run): with tracking off and no tracking channel chosen, turn tracking on from the **sensor icon at the top of the Channels tab**. ✅ With one private channel, it's picked for you. ✅ With several, the menu closes and *Share your location on* asks which one. ✅ Cancelling that leaves tracking **off** rather than on with *None*. ✅ Settings → Location Tracking shows the channel you chose. The Settings switch behaves the same way.
15a. **Phone A — the Settings picker:** Settings → Location Tracking → enable tracking and pick `TeamTest` from the list. ✅ No crash (the first run hit a framework assertion here). ✅ No popup opens.
15b. **Both, still in Settings:** ✅ **no** orange *Not on this radio* row under the picker. If there **is** one, the channel isn't on that phone's radio: tap **Add**, and note it in the results — it means step 14 didn't put the channel on the radio.
16. **Channels tab, both:** long-press `TeamTest`. ✅ The **Team channel** switch is **on** (tracking marked it). ✅ The subtitle shows the group icon and *Team channel*. ✅ The menu scrolls if it's taller than the screen — no overflow stripe.
17. Long-press **Public**: ✅ no Team channel switch (it can't be one).

## Session 5 — Discovery from zero (log A) · 15 min

This is the most important session. It exercises the new discovery end to end, including adding contacts in software (both radios are now in "don't auto-add people" mode from session 3).

18. **Make the phones strangers:** on A, **Contacts → long-press B's contact (`R2-radio`) → Delete**. On B, delete `R1-radio`. (This removes them from the radios too.) If either isn't there, fine.
19. Make sure tracking is on for both, on `TeamTest`. Move each phone a few metres so they send positions.
19a. **Check both phones are actually sending** — the first run failed here, silently. Each phone's own log should show its position going out every interval:
    ```
    [Native][I] [TELSEND] frame built {telemetryText: #TEL:…}
    ```
    On A in the USB log; on B in its in-app log. ✅ Both. If a phone isn't sending, look in its log for `[TelemetrySend] ⏭️ "TeamTest" is not on this radio; not sending` — then `TeamTest` isn't on that radio: add it (Settings → Location Tracking → **Add**, or tap the message box in the channel). ✅ Within a moment the log shows `[TelemetrySend] 🔄 Tracking channel is now on the radio` and `[TELSEND]` lines start.
20. **Watch A's log.** Within one or two telemetry intervals:
    ```
    [MessageSync] 📩 Channel message from 'R2-radio': '#TEL:…'   ← B's position arriving
    [TELREC] 📍 Sender 'R2-radio' not on radio (unresolved)
    [Discovery] 📤 Advertising ourselves for "R2-radio"      ← first packet
    [Discovery] 📣 Asking "R2-radio" to advertise: #CAP:R:…:R2-radio   ← next packet
    [Discovery] ➕ Adding "R2-radio" from an unstored advert
    [Peers] 🔗 Bound "R2-radio" to its radio key
    ```
    If A only ever sees `#CAP:R` from B and never `#TEL`, B isn't sending — go back to 19a on B.
    ✅ Advert and request **alternate**, one outgoing packet per received position, and **stop** once B is added.
21. **B's log** should show the mirror image, plus: `[Discovery] 📡 Advert request …` and `[CapabilityPublisher] 📣 Advert requested by a peer - replying in …ms` when A asks.
22. **Result, both phones:** ✅ The other appears on the map and in the group panel. ✅ In Contacts they show with the **group icon**. ✅ A **DM** from the map marker works.
22a. ✅ A's log shows B's capability message arriving at least once: `[MessageSync] 📩 Channel message from 'R2-radio': '#CAP:2:…'`. (In the first run it never did — the same silent-sender problem as 19a.)
23. **Watch for an advert storm:** if adverts keep going after both are resolved, that's a failure — capture the log.

## Session 6 — Names reach the team (log A) · 15 min

24. Within ~2 minutes of session 5, **on Phone B**, A should appear as **`Anna`**: on the map marker, the group panel, and in Contacts (with `R1-radio` in small text underneath). A's log shows `[CapabilityPublisher] ✅ Published #CAP (…): #CAP:2:…:Anna`.
25. **Phone B:** Settings → General → set name `Ben`. ✅ Within ~1–2 minutes **Phone A** shows `Ben` (map, contacts, group panel). A's log: `[Capability] ✅ Stored capability for "R2-radio": …alias="Ben"`.
26. **Chat:** B sends a message in `TeamTest`. On A, ✅ the sender shows as `Ben`. ✅ A's notification (app in background) says `Ben`.
27. **The privacy check:** on A, long-press B's message → **Reply**. ✅ The box is pre-filled with `@[R2-radio]` — the **radio** name, **not** `Ben`. [8.4]
28. On B, clear the name (Settings → General → empty → Save). ✅ A falls back to `R2-radio` within a couple of minutes. Set it back to `Ben` afterwards.
29. **Same name, two people** can't be shown with two phones, since you never see yourself. Session 11 produces it naturally (two `Ben`s), so it's checked there.

## Session 7 — Renaming a radio (log A) · 10 min

30. **Phone B:** rename R2 from `R2-radio` to `R2-renamed` (Connection → device name). The radio reboots and reconnects.
31. A's log, after B's next advert: ✅ `[Peers] ✏️ Radio renamed: "R2-radio" → "R2-renamed"`.
32. On A: ✅ B is still **one** person, still shown as `Ben`, same map history. ✅ Contacts shows `R2-renamed` under `Ben`.
33. Before B's advert arrives, A's log shows `[TELREC] 📍 Sender 'R2-renamed' not on radio` for a few packets — that's the rename window, and discovery kicks in. When the advert lands: ✅ `[Peers] ✏️ Radio renamed …` followed by `[Peers] 🔀 Merging placeholder "R2-renamed" into its renamed radio`. ✅ Afterwards there is **one** B on A's map, not a second stale marker.

## Session 8 — Team channels without a radio (log A) · 15 min

34. **Phone A:** disconnect from R1 (Connection → disconnect).
35. Channels tab: ✅ `TeamTest` still listed, **not** greyed out (the radio had it last time). ✅ *Public* still normal.
36. **Create a channel offline:** `Offline1` (private). ✅ It appears greyed out, *Not on this radio*, with the group icon and *Team channel*.
37. Long-press an **ordinary** channel the radio owns (not Public, not a team channel — create one earlier if you have none). ✅ **Delete** is greyed out with *This channel is stored on your radio. Connect to the radio to delete it.* No "Bad state" error anywhere.
38. Long-press `Offline1` → Delete. ✅ It goes, no error. Create `Offline1` again for the next steps.
39. **Reconnect A to R1.** A's log: ✅ `[ChannelSync]` lines — a manual reconnect runs a full sync. (After an **auto**-reconnect instead, you'd see `Channels marked not on this radio: re-checking the radio` first: that's the path that used to leave channels stuck.)
40. ✅ `Offline1` is **still** there and still *Not on this radio* (correct — it genuinely isn't on R1). ✅ `TeamTest` is normal.
41. Open `Offline1`, tap the message box. ✅ *Add to radio?* with the explanation. Tap **Add**. A's log:
    ```
    [Channel] ✅ Added "Offline1" to the radio at N
    ```
    and **before** that, no `Slot N is taken on the radio` warning unless R1 really had a channel there. ✅ The channel is no longer greyed out and shows a slot number.
42. Send a message in `Offline1`. ✅ It sends (B won't receive it — B doesn't have that channel; that's fine).

## Session 9 — Heard nearby (log A) · only if another MeshCore node is around

With only two radios, both team members are added automatically, so the list only fills if a **third** node advertises nearby (a repeater, a friend's radio, or a node on a public mesh).

43. Wait near such a node, or have it send an advert. ✅ A's **Contacts** tab shows **Heard nearby (1)** at the top. A's log: `[Discovery] 📇 Listing unstored advert from "…"`.
44. ✅ **Dismiss** hides it. ✅ **Add** puts it in Contacts and removes the row.
45. ✅ A **repeater** advertising should be added to Contacts **automatically**, not listed (repeater auto-add is kept on). [6.4]
46. ✅ Neither `Ben`/`R2-radio` ever appears in this list.

## Session 10 — Hide all but the team (either phone) · 2 min

47. Settings → General → turn on *Hide all but team channels and contacts*. ✅ Channels shows only team channels; Contacts shows only B (and anyone else seen on `TeamTest`). ✅ Neither tab has a filter button of its own. Turn it off again.

## Session 11 — Swapping radios (log A) · 20 min · do this last

The hardest case for identity: each phone ends up on the other's radio.

48. **Phone B:** disconnect from R2 and close the app (so it stops transmitting).
49. **Phone A:** disconnect from R1, connect to **R2**. The radio-name prompt appears (a new radio) — keep `R2-renamed`.
50. A's log: ✅ `[ChannelSync]` runs; `TeamTest` is on R2 already (B joined it with R2), so ✅ it shows normally with its **history intact**. ✅ `Offline1` shows *Not on this radio* (it's on R1, not R2). ✅ Everyone's last known positions are still on the map.
51. A's log: ✅ **no** `[TeamRadio] ➕ Adding … team contacts` entry for B's old radio — that radio is now A's own. (This was a bug, fixed in `e585d49`.)
52. **Phone B:** open the app, connect to **R1**. Turn tracking on (select `TeamTest` — R1 has it, since A created it there).
53. Now each phone is on the other's old radio. **Expected**, and worth understanding:
    - On the mesh, identity follows the **radio**. So A sees B's positions arriving from R1 as a **new person**, until B's capability message arrives and names it `Ben`.
    - A still has the **old** `Ben` (tied to R2 — now A's own radio), with a last position from before the swap. For up to 12 hours both may show, as two separate `Ben` markers, until the old one ages off the map (or hide it with **Remove from group**).
    - Discovery (session 5 lines) runs again between the phones, since neither radio has the other as a contact.
    - ✅ Pass if: discovery completes, the live marker is named `Ben` within a few minutes, and the only duplicate is the stale pre-swap one.
54. **Swap back:** B disconnects, A goes back to R1, B back to R2.

## Session 12 — Endurance (log A) · 1 hour+, leave running

55. Leave both phones tracking on `TeamTest`, screens off, for over an hour.
56. A's log afterwards: ✅ one `[CapabilityPublisher] ✅ Published #CAP (periodic)` per hour (±5 min), not bursts. ✅ No repeating `[Discovery]` lines once both are resolved. ✅ Both still on each other's maps.
57. Count people: ✅ each phone shows exactly **one** teammate on the map (except the stale entry from session 11, if within 12 hours). More means identity is being split — capture the log.

---

## Quick results sheet

| # | Session | Pass? | Notes / log |
|---|---|---|---|
| 1 | Install and upgrade | | |
| 2 | Name prompt | | |
| 3 | Connecting, auto-add | | |
| 4 | Shared team channel | | |
| 5 | Discovery from zero | | |
| 6 | Names reach the team; reply uses radio name | | |
| 7 | Radio rename | | |
| 8 | Team channels without a radio | | |
| 9 | Heard nearby (if a 3rd node) | | |
| 10 | Hide all but team | | |
| 11 | Radio swap | | |
| 12 | Endurance | | |

## If something fails
- Capture the log from **the phone where the failure appears**, from a minute before it to a minute after.
- Note the phone, the radio it was on, and the session/step number.
- For anything about names or identity, B's in-app log is often the other half of the story — screenshot the relevant lines.
