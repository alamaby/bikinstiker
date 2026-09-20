# History Regenerate Black-Screen Fix Plan

Created: 2026-09-20 12:15:00

## Objective

Fix blank-black screen after History → long-press sticker → Regenerate: remove the spurious root-route `pop()` and navigate the user to the Home tab with prompt + preset prefilled via existing `HomePrefillCubit`.

## Scope

- In scope:
  - `lib/presentation/screens/history/history_screen.dart` `_HistoryTile._regenerate` (remove second `pop`, add go-home).
  - New minimal `ShellTabCubit` for tab switching (Home = index 0).
  - Wiring in `lib/app.dart` (provider) + `lib/presentation/screens/shell/main_shell_screen.dart` (listen/select).
  - Regression widget test for regenerate flow.
  - Patch version bump (`pubspec.yaml`).
- Out of scope:
  - Changing `HomePrefillCubit` / `HomeScreen` prefill logic (`lib/presentation/screens/home/home_screen.dart:410-444` — works as-is).
  - Changing Plus-gating (`_showContextMenu` non-Plus snackbar path stays).
  - Backend / Supabase changes.

## Milestones

1. Repro & root-cause lock (no code change, confirm double-pop).
2. `ShellTabCubit` + shell wiring.
3. History `_regenerate` fix.
4. Regression test + analyze/test green + version bump.

## Tasks
- [x] Task 1 — Confirm RCA (read-only, no edit): double-pop confirmed at `history_screen.dart:386` (sheet pop, correct) + `:409` (second pop, fatal); no tab-switch exists (`_select` private, `:31`).
- [x] Task 2 — Create `lib/presentation/blocs/shell_tab/shell_tab_cubit.dart`
- [x] Task 3 — Register provider in `lib/app.dart`
- [x] Task 4 — Rewire `lib/presentation/screens/shell/main_shell_screen.dart` with BlocListener/BlocBuilder
- [x] Task 5 — Fix `_regenerate` in `lib/presentation/screens/history/history_screen.dart`: removed second `pop()`, added `ShellTabCubit.goHome()`
- [x] Task 6 — Regression test (`test/history_regenerate_test.dart`): covers Plus-path regenerate → Home tab switch + non-Plus path stays on History with snackbar
- [x] Task 7 — Version bump (`pubspec.yaml` → 0.26.9+91)
- [x] Task 8 — Verify: analyze 0 issues; test 208/208 passing (incl. 2 new tests)

## Risks

- `goHome()` emit(0)-while-already-0 no-op: if a future flow calls regenerate from Home tab itself, listener won't fire. Mitigation: current caller is always History (index 3), so emit 3→0 always changes; add code comment. Counter-argument: a dedicated event cubit or `force` flag is cleaner but adds complexity a less-capable model may get wrong — accepted trade-off, documented here.
- `HomeScreen` prefill race: `HomeScreen` listener (`home_screen.dart:410-444`) applies + `clear()`s prefill even while offstage in `IndexedStack`. Since Home (index 0) is always built first (`_maxVisited` starts 0), prefill won't be lost; tab switch makes it visible. Risk only if shell lazy logic changes — don't change `_maxVisited` semantics.
- Over-mocking in widget test (History/Preset/Subscription blocs) may make test brittle. Mitigation: seed minimal states only, follow existing `history_bloc_test.dart` fixtures; prefer testing cubit interactions over pixel-perfect UI.

## Progress Log
- 2026-09-20 12:15:00 — Plan created (RCA locked: double-pop pops root route; missing tab-switch). No code changed yet.
- 2026-09-20 14:30:00 — Tasks 2–5 implemented: ShellTabCubit created, wired in app.dart, MainShellScreen rewired with BlocListener/BlocBuilder, History._regenerate fixed (removed second pop, added goHome). Version bumped to 0.26.9+91.
- 2026-09-20 14:50:00 — Task 6 done: regression test added (`test/history_regenerate_test.dart`), covers Plus-path regenerate → Home tab switch + non-Plus path stays on History with snackbar. Both tests pass. Analyze clean. Full suite 208/208 passing.

## Notes

- RCA evidence: `history_screen.dart:386` (sheet pop, correct) + `:409` (second pop, fatal); `app.dart:373` + `main_shell_screen.dart:42` (shell is root `home:`, no nested navigator → second pop empties stack → black).
- Design choice justification (vs alternatives): `ShellTabCubit` over `GlobalKey`/`findAncestorStateOfType` — testable, unidirectional, no fragile ancestor lookup; over direct `Navigator.push(HomeScreen)` — push would duplicate Home above shell and break bottom-nav state + `HomePrefillCubit.clear()` lifecycle.
- Telecom billing standards (C2M/TM Forum ODA) N/A — pure client navigation bug, no schema change.
- Env-guard: no secrets touched; no `.env*` reads.
