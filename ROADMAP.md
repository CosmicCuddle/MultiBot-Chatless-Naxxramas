# MultiBot Chatless — Naxxramas Development Roadmap

Repository: https://github.com/CosmicCuddle/N-MultiBot-Chatless  
Client: World of Warcraft 3.3.5a (Interface 30300, Lua 5.1)  
Development branch: feature/nt1-bot-talents-paste-button  
Development version: MultiBot 4.0.1 — NOT a published production release  
Last maintained: 10 October 2026  
Public suite baseline: N Addon Collection v2.0.0, which still includes approved MultiBot 4.0  
Author and credit lineage: Nico Löbbert, Wishmaster117/TheWarlock, CosmicCuddle

This is the current handover for the Naxxramas fork. Also preserve docs/ROADMAP.md, which is the detailed historical upstream bridge-migration audit. That document includes older August 2026 baseline SHAs and should not be mistaken for the current Naxxramas fork version. Update this root file with every meaningful change, including the new exact next task.

## Current baseline and separation of responsibilities

MultiBot is a bridge-first client addon for AzerothCore Playerbots. Its UI, rosters, commands, inventory and strategies rely on the existing MultiBot bridge for most structured operations. The MultiBot 4.0 fork already includes custom Naxxramas consumables integration in UI/MultiBotConsumablesUI.lua.

The new **NT1 Talents** control is a deliberate server-specific exception that calls the already-existing Naxxramas Core CommandScript command. It is **not** a new general chat command executor, a change to mod-playerbots, or an alteration of the upstream bridge's TALENT_APPLY_V1 protocol.

Server command source: https://github.com/CosmicCuddle/Mod-Naxxramas-Core/blob/main/src/Systems/BotTalentImport.cpp  
Server requirements and experimental test history: https://github.com/CosmicCuddle/Mod-Naxxramas-Core/blob/main/docs/PLAYERBOT-NT1-TALENT-IMPORT.md  
Talent code producer: https://github.com/CosmicCuddle/N-Talent-Calculator-  
Website-compatible codes: https://github.com/CosmicCuddle/Naxxramas-Resource-Hub/tree/main/talents

The v2.0.0 Addon Collection release is already published and must remain unchanged. Its source pin for MultiBot 4.0 is d1606832a083ebf660d67b629b07207b184590dd. The new button is not in that release and must not be imported into it retroactively. An approved future suite version and explicit import PR are required.

## Current work: NT1 Talents button (MultiBot 4.0.1)

The request is one new Talents button, adjacent to MultiBot's existing right-side quest/group/consumables controls. A player targets an online Playerbot and opens the button. The new window shows:

- Name and detected class of the character that was targeted when opened.
- Clear instructions to paste an NT1 build code from N Talent Calculator or the Resource Hub.
- A genuinely formatted example: NT1:vanilla:warrior:3g-1 (this is a single-point illustrative code, not a raid build).
- One paste box, plus Preview, Apply talents and Cancel.
- Preview sends a read-only server command, leaves the dialog open and relies on server chat for results.
- Apply talents, or Enter in the edit box, sends the exact server apply command and closes the box on dispatch. Server chat determines if application actually succeeded.
- Escape and Cancel close without changing talents.

The constructed commands are:

    .naxxbot talents preview <online-botname> <NT1-code>
    .naxxbot talents apply <online-botname> <NT1-code>

Client protections: capture the selected target's name and GUID at dialog opening; refuse apply/preview after a target change, including a changed GUID with the same displayed name. Require an actual player-type game target distinct from the user's character. Reject empty codes, malformed NT1 sections, unknown era/class, duplicated entries and a known mismatch between the code class and targeted character class.

The input may hold up to 2048 characters for validation, matching the server code format maximum, but the complete single SAY chat command must not exceed **255 characters**. The client does not split or truncate a longer code. Longer codes need a future dedicated server-supported transfer; this UI explicitly refuses them. Treat this as a known limitation, not a silent success. No clipboard-reading API is required: players paste manually.

### Exact files in this change

| File | Responsibility |
| --- | --- |
| MultiBot.toc | Version 4.0.1, loads the new UI file after Consumables and before Core/MultiBotInit.lua |
| Core/MultiBotInit.lua | Calls the new single right-toolbar initializer |
| UI/MultiBotNT1TalentsUI.lua | Button, 3.3.5a paste frame, syntax check, target/GUID binding, optional preview and apply |
| tests/test_nt1_bot_talents.lua | Lua 5.1 frame mocks, code validation, selected target safeguards, preview/apply and Escape tests |
| .github/workflows/nt1-playerbot-talents.yml | Targeted Lua 5.1 regression and install-ready test ZIP artifact |
| README.md | Usage, command contract, prerequisites, warning and link to handover |
| ROADMAP.md | This authoritative Naxxramas fork handover |
| docs/ROADMAP.md | Previous fork/upstream bridge migration history, retained intact |

The UI module does not modify UI/MultiBotSpecUI.lua, which continues to provide premade Playerbots specs, nor the bridge, consumables, Playerbots, Individual Progression or core AzerothCore code. This separation is intentional.

## Server-side status and explicit precautions

Naxxramas Core's importer is experimental. Its AccessMode setting is disabled by default:

    NaxxramasCore.BotTalentImport.AccessMode = 0

Mode 0 disables both commands. Mode 1 enables GM access to preview and apply. Mode 2 permits GM and authorised non-GM player access; the server enforces same-account or actual Playerbots master/group conditions as appropriate. Mode 1/2 **both allow real talent mutation**; there is no safe preview-only active mode. The addon must never claim that showing the popup means the server feature is available or that command dispatch guarantees success.

The server has reported a successful grouped-random-bot NT1 application to disposable random Mage bot Zevon (51 spent, 0 unspent). This was an experimental happy-path screenshot, not proof that all classes, learned spells, full randomisation protection or crash recovery are safe. The server importer can reset/relearn talent ranks and performs only best-effort recovery, not an atomic SQL transaction. Random Playerbots can rerandomise and replace talents even during the same group session. Random bot NT1 profiles are intentionally not saved as persistent desired profiles.

**Before any Apply test**, back up the entire acore_characters database and the original talent data for a disposable controlled bot. Check the required optional characters SQL migration with the Naxxramas Core maintainer notes. Configure the server only in a controlled test environment. Disabling AccessMode later prevents new apply operations but does not undo any previously applied character talents.

The addon update alone does not require recompiling worldserver. The server C++ importer must already be compiled/restarted, enabled in config and have any required optional persistence table installed. Never copy the server command logic to the client or bypass its permission checks.

## Completed implementation ledger

| Milestone | Status / evidence |
| --- | --- |
| Original bridge-first UI work | Preserved upstream architecture and docs/ROADMAP.md migration records |
| Naxxramas consumables integration | Present in current standalone MultiBot 4.0, built against Naxxramas Core BotRaidConsumables.cpp |
| N Addon Collection v2.0.0 | Published; approved pin remains MultiBot 4.0 |
| Naxxramas Core NT1 command | Implemented separately; one experimental grouped random-bot application observed |
| New targeted NT1 Talents button | PR #1 implemented; [Lua 5.1 targeted tests](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38083632251) and [Luacheck](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38083632355) passed; **real client not yet tested** |
| Target-safe code entry and Preview/Apply dispatch | Implemented; Lua 5.1 target, GUID, grammar, no-send/preview/apply and Escape tests **passed** in Actions 38083632251 |
| Packaged MultiBot standalone test ZIP | GitHub Actions 38083632251 produced artifact multibot-nt1-talents-test; check ZIP locally and test in actual client |
| Permanent roadmap | This file, with next test and recovery instructions; keep updated with the PR |

## Immediate next task — validate feature in WoW, not only in a Lua mock

1. **CI completed:** NT1 Lua 5.1 regression and test ZIP build passed in [Actions 38083632251](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38083632251); repository-wide lint passed in [38083632355](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38083632355). Pull request: [#1](https://github.com/CosmicCuddle/N-MultiBot-Chatless/pull/1). Confirm the extracted ZIP in client before marking installation validated.
2. Before replacing the addon, close WoW and back up Interface/AddOns/MultiBot and the account/character WTF SavedVariables. Keep the previous 4.0 build available for rollback.
3. Launch WoW 3.3.5a at the usual UI scale and target a disposable online Playerbot. Click the new NT1 Talents control in the right-hand MultiBot bar. Screenshot the dialog and check layout, example, button placement, focus and error labels.
4. With the importer disabled (AccessMode 0), use Preview and verify Naxxramas Core refuses the command. Check that merely opening the popup never sends a command.
5. If a tested SQL and characters backup is ready, enable mode 1 as GM (or mode 2 for authorised normal players) on a controlled test server. Preview a valid code; confirm the server's read-only talent/point breakdown.
6. Change target before clicking Apply. Verify the popup refuses and sends no command. Retarget the original bot and reopen.
7. Explicitly agree to a disposable-bot application, then press Enter or Apply. Verify server chat response and inspect the bot's actual talents, points, learned spells and behaviour. A "command sent" UI message is *not* proof of a successful server mutation.
8. Verify no incorrect target is affected. Test no target, own player, wrong class, empty and invalid codes, malformed entries, overlength chat commands and Escape/Cancel.
9. Try a real full 51-point exported Vanilla code and a 71-point Wrath code. If too long, ensure the UI displays the safe failure instead of sending truncated data.
10. Repeat at different UI scales and confirm prior premade spec selection, consumables and bridge UI still work. Record failures, screenshots and server logs here.

Exit criteria: client screenshot, accurate Preview result, command dispatch correctness and independently inspected bot talents. Leave the server mutation feature experimental until all permissions, persistence and rollback paths are verified.

## Next tasks after acceptance

P1 — fix UI positioning or localized text if client evidence shows clipping or unreadability. Keep only one right bar button, not duplicated spec buttons.

P2 — investigate reliable long-NT1 transmission only if realistic builds exceed the 255-character SAY envelope. This would require a separately audited addon-message protocol / bridge feature with proper server permission and chunking, not a cosmetic client workaround. No generic arbitrary command sender.

P3 — test alt bots versus grouped random bots for GM and ordinary players. Verify foreign-master and unrelated grouped bots cannot be modified. Test Playerbots rerandomisation, relog and combat/death rejection.

P4 — update version and publish standalone MultiBot only after user approval and real tests; do not replace the N Addon Collection v2.0.0 release or silently add the new code. A subsequent collection release needs its own approved source pin, CI package tests and new tag.

P5 — continue the remaining upstream Chatless follow/attack/stay audit from docs/ROADMAP.md, keeping the bridge first and the Playerbots source untouched.

## Development, test and rollback instructions

Offline: install Lua 5.1 and run

    luac5.1 -p UI/MultiBotNT1TalentsUI.lua
    luac5.1 -p Core/MultiBotInit.lua
    lua5.1 tests/test_nt1_bot_talents.lua

The GitHub Actions workflow creates multibot-nt1-talents-test, with an install-ready ZIP containing one MultiBot/ folder. Unpack that ZIP **directly** into WoW 3.3.5a Interface/AddOns. Do not add an extra repository-named wrapper directory. Use backup copies when replacing original files; do not delete the old working build permanently. No server SQL or DBC changes are bundled in this addon.

Client rollback: exit WoW, restore the old MultiBot directory and WTF SavedVariables as needed, then restart. Server talent rollback after Apply is a different procedure: restore the disposable bot's talent data using the verified characters database backup or the documented core recovery method; disabling the command is not a rollback of completed talent changes.

## Documentation rule — every change

Update this roadmap in the same GitHub PR/commit as changes to source, server command assumptions, addon loading, test scripts or builds. Record changed files, exact version/SHA, what is CI-only versus client-tested, unresolved risks and the concrete next task. Preserve upstream author and licence notices and the independently maintained bridge-migration history. Do not claim success without tests. A chat reset must not prevent the next maintainer from continuing at the next numbered test above.
