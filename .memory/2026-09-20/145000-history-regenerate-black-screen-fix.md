# 2026-09-20 14:50 — history-regenerate-black-screen-fix

## Task
Fix blank-black screen after History → long-press sticker → Regenerate. Root cause: `_regenerate` in `history_screen.dart` called `Navigator.of(context).pop()` a second time after the modal sheet was already popped, removing the root route. Secondary defect: no tab-switch to Home existed.

## Key Files Changed
- `lib/presentation/blocs/shell_tab/shell_tab_cubit.dart` — new minimal cubit (index 0 = Home)
- `lib/app.dart` — registered `ShellTabCubit` provider alongside `HomePrefillCubit`
- `lib/presentation/screens/shell/main_shell_screen.dart` — rewired to use `BlocListener` + `BlocBuilder<ShellTabCubit, int>`; `_select()` preserved for lazy IndexedStack guard
- `lib/presentation/screens/history/history_screen.dart:404-410` — removed `Navigator.of(context).pop()`, added `context.read<ShellTabCubit>().goHome()`
- `test/history_regenerate_test.dart` — regression test (Plus-path: HomePrefill set + tab switches to 0; Non-Plus-path: snackbar shown + stays on History)
- `pubspec.yaml` — version bumped `0.26.8+90` → `0.26.9+91`

## Decisions
- Chose `ShellTabCubit` over `GlobalKey`/`findAncestorStateOfType` — testable, unidirectional, no fragile ancestor lookup.
- `goHome()` is `emit(0)` (not a dedicated event) — safe because caller is always History tab (index 3), so 3→0 always changes. Documented in code comment.
- Kept `_maxVisited` locally in shell for lazy `IndexedStack` semantics (Missions/Packs/History need auth user).

## Risks / Open Items
- `goHome()` no-op if called while already on Home tab (future risk if flow changes). Mitigated by code comment.
- Full-shell widget test was too heavy for mocks (HomeScreen needs AuthBloc, StickerGenBloc, etc.) — used fallback: pump `HistoryScreen` directly and assert cubit interactions + no Navigator pop.
- Manual device verification still pending.

## Verification
- `flutter analyze` → 0 issues
- `flutter test` → 208/208 passing (2 new tests)

## Conventional Commit
fix(history): remove spurious pop in _regenerate, switch to ShellTabCubit
