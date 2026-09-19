# Agent Instructions

## Rule Precedence

When rules conflict, apply this order (highest priority first):
1. An explicit, one-off instruction from the user in the current conversation.
2. Project-specific guidance in `.memory/README.md`, or the legacy `PROJECT_MEMORY.md` when the new format is absent.
3. The standing rules in this document.

If a conflict is non-obvious or high-stakes, flag it to the user instead of silently picking one side.

## 1. Basic Rules

1. When asked to propose a commit message, follow Conventional Commits format, limited to a single line.
2. Whenever feasible, apply the following principles:
   - SOLID principles
   - Database as Code (migration management)
   - Non-Destructive Migrations
   - End-to-End Type Safety
   - Strict Row Level Security (RLS)
   - Optimal Next.js Rendering Strategy (RSC)
   - Environment Variable Validation
   - Documentation is Key
   - Clean Code
   - State Feedback & Submission Prevention
   - Data Fetching Optimization
   - Internationalization (i18n)
   - First-Party Anti-Bot Protection
   - Responsive Web Design & Mobile-First Approach

## 2. Working Style

### 2.1 Use Relevant Examples
When explaining a concept, proposing an approach, or writing documentation, include a concrete, relevant example whenever one would clarify the point (e.g. a sample query, a snippet of code, a sample file/folder structure). Skip examples only when they would be redundant or when the request is purely mechanical (e.g. a one-line commit message).

### 2.2 Think Critically Before Proposing
For every idea, recommendation, or proposal the agent puts forward:
- Actively look for gaps, edge cases, or failure modes before presenting it as final.
- Include at least one counter-argument, risk, or limitation alongside the proposal — don't present only the upside.
- If a proposal is genuinely half-baked or unverified, say so explicitly rather than presenting it with false confidence.
- This applies to plans, architecture suggestions, code designs, and migration strategies alike.
- Keep this proportional to the stakes: trivial or purely mechanical outputs (e.g. a one-line commit message, a formatting fix) don't need a counter-argument — reserve critical pushback for ideas, designs, and proposals that actually carry risk or trade-offs.

### 2.3 Diagram Styling
When generating diagrams (flowcharts, ER diagrams, architecture diagrams, sequence diagrams, etc.), use the default theme/styling of the tool or library being used. Do not apply custom skins, custom color palettes, or custom themes unless the user explicitly asks for one.

## 3. Architecture & Domain Standards

- **Telecom/utility rating (usage-based charging), billing, and payment systems:** use **Oracle Customer to Meter (C2M)** and **TM Forum ODA** as the primary reference for domain models, process flows, and API design. Any deviation from these standards must be explicitly justified in the plan's `## Notes` section (see Section 7).
- **Other projects:** use **TOGAF**, or another standard appropriate to the project, as the benchmark. Apply it proportionally to project scope — e.g. reference relevant ADM phases or architecture views for genuinely enterprise-scale work, but don't impose full enterprise-governance ceremony on a small feature, a single microservice, or a routine bugfix.
- These standards guide **design and documentation**. If applying them implies schema or structural changes to a live database, the changes must be captured in a plan file (Section 7) rather than executed directly — see the read-only constraint in Section 6.

## 4. Flutter Development

- When asked to build/add a feature: bump the **minor** version in `pubspec.yaml` by 1, reset **patch/revision** to 0, and bump the **build number** by 1.
- When asked to fix a bug: bump the **patch/revision** version in `pubspec.yaml` by 1, and bump the **build number** by 1.
- Before considering the project safe/done, always verify with:
  ```
  flutter pub get
  flutter analyze
  flutter test
  flutter build apk --split-per-abi
  ```

## 5. Project Memory

### Discovery and Precedence

- Before starting a task, look for `.memory/README.md` at the project root.
- If it exists, read it first and treat `.memory/` as the active memory source. Read only entries relevant to the current task, using index links, filenames, and keyword search instead of loading full history.
- If `.memory/README.md` does not exist, read legacy `PROJECT_MEMORY.md` when present.
- If both exist, `.memory/` is active and `PROJECT_MEMORY.md` is a read-only historical archive unless project-specific instructions explicitly say otherwise.

### Active Format

- Store each significant task in `.memory/YYYY-MM-DD/HHmmss-kebab-case-topic.md`, using the project's local timezone.
- Use one entry per task, not one file per day. Add a short unique suffix if concurrent agents could produce the same filename.
- Each entry must record the task or problem, key files changed, technical or business decisions, assumptions or risks, blockers or unresolved items, verification performed or recommended, a one-line Conventional Commit proposal, and related plans/specs/issues when relevant.
- Do not create entries for trivial reads, explanations, formatting-only changes, or work that produced no durable project knowledge.

### Memory Index

- `.memory/README.md` is a concise current-state summary and navigation index, not a duplicate activity log.
- Maintain its last-updated timestamp, format version, current state, active decisions, open items/blockers, legacy archive link, and at most 20 recent entry links.
- Preserve entry files after they leave `Recent Entries`; never delete history merely to bound the index.

### Post-Task Update

- After a significant change, create one timestamped entry and update `.memory/README.md` only when current state, active decisions, open items, or recent links changed.
- Re-read target files immediately before editing when concurrent agents may be active. Preserve memory written by users or other agents.
- Once `.memory/` is initialized, do not append new entries to `PROJECT_MEMORY.md`.

### Legacy Migration

- When only `PROJECT_MEMORY.md` exists, initialize `.memory/README.md`, retain the legacy file in place, link it as historical memory, and extract only still-active decisions, blockers, and current state.
- Do not split or rewrite complete legacy history unless the user explicitly requests full migration.
- Write all subsequent significant-task entries in the active format.

## 6. MCP Database (Read-Only)

The agent is connected to the database via MCP in **READ ONLY** mode. Its purpose is limited to:
- Reading data
- Analyzing database structure
- Helping construct `SELECT` queries
- Explaining data and relationships between tables

**Allowed statements:** `SELECT`, `WITH` (CTE), `DESCRIBE`/`DESC`, `EXPLAIN PLAN`, `DBMS_METADATA`

**Forbidden statements:** `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, `DROP`, `ALTER`, `CREATE`, `RENAME`, `GRANT`, `REVOKE`, `COMMIT`, `ROLLBACK`, `BEGIN...END`, `DECLARE`, `EXECUTE`, any call to a PROCEDURE/FUNCTION that can modify data, or any other SQL/PL-SQL statement that could potentially modify the database.

**Execution rules:**
1. Before running any SQL, confirm the statement starts with `SELECT` or `WITH`.
2. If a query contains a forbidden keyword, do not run it.
3. If the user requests a data change, do not create or run a modification query.
4. Explain that this database environment is READ ONLY and only allows read operations.
5. If there is any doubt about whether a statement could modify data, treat it as UNSAFE and refuse to run it.
6. Never attempt to find workarounds to bypass the READ ONLY restriction.

**Standard refusal response:**
> "Operation denied. This database connection only allows read access (READ ONLY). Commands that could change the database structure or data are not permitted."

## 7. Persisting Plans to Markdown Files

Whenever the user requests any of the following (or any response containing a structured sequence of tasks, milestones, or steps):
- create/make/generate a plan
- project plan, implementation plan, migration plan
- roadmap, action plan, task breakdown, execution plan

The agent MUST:

1. Write every plan into a Markdown (`.md`) file.
2. Create exactly one file per plan — never append multiple unrelated plans into the same file.
3. Create the file immediately after generating the plan.
4. Include in the response both:
   - the generated plan content, and
   - the file path of the created Markdown file.
5. As work on the plan progresses, keep the plan file up to date — don't treat it as a write-once document. Whenever tasks are worked on, update the same plan file to reflect:
   - which tasks/items are **done** (check off `- [x]` in the `## Tasks` list)
   - which tasks are **still pending**
   - which tasks turned out to be **not possible / blocked**, along with the reason
   - any other development worth mentioning that isn't already covered by the template (e.g. scope changes, new risks discovered, decisions made mid-execution)
   
   Log each update as a dated entry under `## Progress Log`, and check off / annotate `## Tasks` accordingly, so the plan file stays the single source of truth for that plan's status — no separate file needed.

### File Naming Convention

```
plans/YYYY-MM-DD-<kebab-case-plan-name>.md
```

Examples:
```
plans/2026-06-25-bad-debt-collection-implementation-plan.md
plans/2026-06-25-api-migration-plan.md
plans/2026-06-25-mobile-app-roadmap.md
```

If multiple plans with the same name are created on the same day, append a numeric suffix:
```
plans/2026-06-25-api-migration-plan-2.md
plans/2026-06-25-api-migration-plan-3.md
```

### Markdown Template

```md
# <Plan Title>

Created: YYYY-MM-DD HH:mm:ss

## Objective
<plan objective>

## Scope
- item 1
- item 2

## Milestones
1. Phase 1
2. Phase 2
3. Phase 3

## Tasks
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Risks
- Risk 1
- Risk 2

## Progress Log
- YYYY-MM-DD HH:mm:ss — <what was done / what's pending / what's blocked / other notable update>

## Notes
Additional information.
```

### Constraints

- One file = one plan.
- Do not overwrite an existing plan file unless explicitly instructed.
- If the user modifies an existing plan, update the same file.
- If the user requests a new plan, create a new Markdown file.
- Plans must always remain in Markdown format (`.md`).

## 8. Supabase CLI Helper

- Untuk `supabase db push` / `supabase functions deploy <name>` SELALU pakai wrapper:
  `& "scripts/supabase-with-token.ps1" db push`
  `& "scripts/supabase-with-token.ps1" functions deploy surprise-me`
- Token `SUPABASE_ACCESS_TOKEN` (prefix `sbp_`) HANYA dari `.env.local`. Jangan pernah taruh di `.env` (`pubspec.yaml:62` membundle `.env` ke APK/AAB).
- Dilarang: `Get-Content .env.local`, `cat .env.local`, `echo $env:SUPABASE_ACCESS_TOKEN`, `grep -r sbp_|sb_secret`, atau mencetak token ke chat/log. Log hanya boleh `token loaded (N chars, redacted)`.
- Verifikasi aman: `& "scripts/supabase-with-token.ps1" --DryRun functions deploy surprise-me`.
- `.env*` sudah gitignored (`.gitignore:122-124`); `supabase/.env.local` juga ignored.