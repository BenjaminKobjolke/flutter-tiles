<!-- Managed by /coding-rules:apply — do not edit rule blocks by hand -->

# Version
12

Increase this version number whenever this rule file changes.

# Common Rules (All Languages)

These rules apply to all projects, regardless of language. Language-specific rules live in the
corresponding `*_RULES.md` files.

---

## Keep CODING_RULES.md in Sync

When working on a project, copy all relevant rules into the project's `CODING_RULES.md` file
(project root). The project's `CLAUDE.md` carries only a small versioned pointer block that
mandates reading `CODING_RULES.md` before code work — never the full rules, and never an
`@import` of `CODING_RULES.md` (imports auto-expand into context every turn).

- Always include all rules from `COMMON_RULES.md` and `IMPLEMENTATION_FLOW.md`.
  `COMMON_RULES.md` is copied into the project's `CODING_RULES.md`;
  `IMPLEMENTATION_FLOW.md` is copied into the project's own `IMPLEMENTATION_FLOW.md`
- Also include applicable language-specific, project-type, and supplemental rule files
  (see `PROJECT_TYPES.md` for the project-type overview)
- Include optional addon rule files only when the user has opted in to that addon
- If applicability is unclear, ask the user which rules to include
- Include each source file's `# Version` block with its copied rules
- If `CODING_RULES.md` already exists, compare each source file's version with the corresponding
  copied rule block and update only stale or unversioned blocks, keeping the result deduplicated
- If `CLAUDE.md` contains inlined rule blocks or coding-rule `@import` lines from an earlier run,
  migrate that content into `CODING_RULES.md` and leave only the pointer block in `CLAUDE.md`

---

## Use Objects for Related Values

When multiple related values must be passed between classes or methods, bundle them into a
dedicated object (e.g., DTO/Settings/Config) instead of passing many parameters. This improves
readability, reduces call-site churn, and makes changes safer.

---

## No Bag-of-Keys Returns at Module Boundaries

When a public method on a manager/repository/service returns data that crosses a module
boundary, the return type must be a typed object (DTO, value object, or domain model) — never
a raw associative array indexed by string keys. Plain `array` returns silently swallow shape
bugs: a missing key reads as `null`, a list-vs-single mix-up reads as "no data", and renames
go undetected by static analysis.

- **Anti-pattern.** `getSettingsValue(...)` returns `array|null`; callers do `$result['value']`,
  `$result['type']`. A consumer mis-indexes `$result[0]['value']` after a refactor; nothing
  flags the change. The function silently returns `null` and downstream defaults take over.
- **Correct pattern.** Return a class — `getSettingsElement(...): ?SettingsElement`. The class
  exposes `getValue()`, `getType()`, `exists()`. Typed, autocompleted, statically checked;
  renames propagate via the IDE.
- **Lists vs single must be obvious from the type and the name.** `getThing(): ?Thing`
  (zero or one) vs `getThings(): ThingList` or `iterable<Thing>`. Never overload the same
  return type to mean both.
- **Distinguish absent from empty.** `null` from a lookup means "not found"; an empty
  collection means "found, but had nothing". A typed return makes this contract explicit;
  a bag-of-keys array hides it.
- **JSON-decoded blobs are arrays too.** The rule applies equally to `json_decode($column, true)`
  results that cross a module boundary — wrap them in a value object before they leave the
  layer that owns the schema.
- **Internal helpers may stay arrays.** This rule targets *public* API on managers and the
  boundary where a domain abstraction starts. Pure-private array juggling inside a single
  method is fine.

---

## Reuse Existing Models Before Inventing Array Shapes

Before designing a new return type or DTO, search the codebase for an existing domain class
that already owns the same data. Most "should this be a DTO?" decisions are actually
"is there already a `Contest` / `User` / `Order` class that should absorb this method?"

- Grep for the table name, the primary key, and the most distinctive column.
- If a model already exists with a constructor that accepts the row shape, use it — don't
  invent a parallel array shape that mirrors the same columns.
- Adding a `getXxxObject()` alongside a legacy `getXxxData()` is acceptable as a migration
  step; keep both only until consumers are migrated, then delete the array-returning version.

---

## Tests Pin the Shape Before the Refactor

When converting a bag-of-keys return to a typed object, write a **characterization test
first** that locks the current behavior using the existing API, run it green against the
unrefactored code, and then refactor. The same test (or a renamed-but-equivalent one) must
remain green afterward.

This converts "I think the new object preserves behavior" into "the test proves it." Pair
with the "Test-Driven Development" rule below — characterization tests are TDD applied to
refactors instead of new features.

---

## Test-Driven Development for Features and Bug Fixes

Follow TDD when implementing features or fixing bugs:

1. Write tests first
2. Run the tests and confirm they fail
3. Implement the change or fix
4. Run the tests again and confirm they pass

---

## Integration Tests

Every project must include integration tests in addition to unit tests. Integration tests verify that
components work correctly together and catch issues that unit tests alone cannot detect.

---

## Test Runner Scripts

Every project must provide the following batch files in the `tools/` directory:

- `tools/run_tests.bat` — runs unit tests
- `tools/run_integration_tests.bat` — runs integration tests

These scripts ensure a consistent way to execute tests across environments.

Both scripts must show progress while tests run: report the current setup stage, suite, or test
before potentially slow work, and show results as execution proceeds. A start banner followed only
by a final summary is insufficient. Prefer the runner's verbose output and stream or flush it so
callers can see it during execution. Print one line per test: `flutter test --reporter expanded`,
`pytest -v`, `phpunit --debug` (`--testdox` lists the tests only after the run on PHPUnit 10+).
For a legitimate long wait without ordinary output, report the current stage or test and elapsed
time at least every 60 seconds. Elapsed-time updates must not imply that a test completed or
advanced. If output is captured for logs or filtering, keep progress visible during execution;
replaying it only after completion does not count.

Both must **exit with the test runner's own exit code** — capture it right after the run
(`set TESTRESULT=%ERRORLEVEL%`) and end with `exit /b %TESTRESULT%`. A bat that prints
"Some tests failed!" but exits 0 reports green to CI, to callers and to AI agents. Never pipe the
test command into a plain filter — the pipe's exit code is the *filter's*, not the runner's. Never
redirect the run into a temp file and print or filter that afterwards either: the script is then
silent for the whole run. Run the command directly so its output streams. If output has to be
filtered or logged, do it while it streams and return the runner's own code, e.g. `powershell
-NoProfile -Command "<test command> | Where-Object { $_ -notmatch '<noise>' }; exit $LASTEXITCODE"`,
or use the runner's own log-file option.

---

## No `pause` in Batch Files

Batch files must never contain a `pause` line. `pause` waits for a keypress, so any bat that has one
hangs forever when run by CI, another bat, or an AI agent. End with an explicit `exit /b <code>`
instead, and let the caller decide whether to keep the window open (`cmd /k`).

---

## Prefer Type-Safe Values

Use strong, explicit types instead of loosely typed or stringly typed values (e.g., typed DTOs,
enums, generics, typed settings). This ensures mistakes are caught at compile time or by tests
early in development.

---

## String Constants

Centralize string constants in a dedicated module/class. Do not scatter raw strings across
the codebase. Use language-appropriate patterns for constants and reuse them consistently.

---

## Reusable Tooling

Before building project-specific infrastructure scripts (audits, codemods,
build helpers, lint checks, etc.) for a project, check the matching
language's `*_setup_files/` folder under this `coding-rules` repo for an
existing equivalent. If found, copy or reference it. If not:

1. Build the script in the project and prove it on real data.
2. Copy the script into the right `*_setup_files/tools/` folder.
3. Document it in that language's `*_RULES.md` so the next project picks
   it up automatically.

This keeps cross-project tooling consistent and prevents the same script
from being re-invented in every new project.

---

## New Projects Start From a Template

Before creating a new project (an API, an app, a tool — anything that gets its own folder),
ask the user whether a template project exists for that kind of project. Never scaffold from
scratch without asking.

- Run `/coding-rules:new-project`: it suggests the template remembered for that project type
  in `~/.coding-rules/settings.json`, asks, and remembers a newly chosen template for next time.
- A remembered template is a suggestion — still ask, the user may want another one or none.

---

## README.md is Mandatory

Every project must have a `README.md` file in the root directory. It should include:

- Project name and description
- Installation/setup instructions
- Usage examples
- Dependencies and requirements

---

## Don't Repeat Yourself (DRY)

Avoid code duplication. If the same logic appears in multiple places, extract it into a
reusable function, class, module, or utility.

- Duplicate code is harder to maintain and leads to bugs
- Extract shared logic into helpers or base abstractions
- Use constants for repeated values

---

## Derive, Don't Duplicate — One Value Owns the Derivation

When one value strictly determines another, pass only the determinant and derive the rest —
never thread both side-by-side through call sites, constructors, and events. Two co-varying
parameters are a functional dependency in disguise; passing both lets them drift into illegal
combinations.

- **Anti-pattern.** `createLog(ActionCategory $cat, ActionType $type)` threaded through ~10
  sites. Nothing stops a caller passing `category: email, type: lead.created`.
- **Correct pattern.** The richer type owns the relationship: `ActionType::category()` returns
  its `ActionCategory` via a single exhaustive `match`. Call sites pass only `ActionType`;
  category is always derived, so a mismatch is unconstructable.
- **Apply when** one value *determines* the other (a true functional dependency).
- **Don't apply when** the relationship is many-to-many or genuinely independent — forcing a
  derivation that doesn't exist couples things that should stay separate.
- **Keep derivation cheap and pure** — a getter/match, no DB or IO behind a call that looks free.
- **Keep the mapping exhaustive** (enum + exhaustive match) so a new case cannot silently skip
  its derived value.

This is Single Source of Truth applied to parameters, and a form of "make illegal states
unrepresentable." Pairs with "Prefer Type-Safe Values" and "Self-Describing Classes".

---

## Keep It Simple (KISS)

Prefer the simplest solution that actually works. Complicated logic for a simple result must be
kept to a minimum — a future maintainer (or you, at 3am) has to understand it.

- **YAGNI.** Don't build for a need that isn't here yet: no interface with a single
  implementation, no factory for one product, no config for a value that never changes.
- **Boring over clever.** Clever is what someone decodes later. The obvious solution wins.
- **Deletion over addition.** The shortest working change is usually the right one.
- Pairs with "Don't Repeat Yourself" and "No God Classes" — simplicity is what those rules
  are protecting.

---

## Confirm Dependency Versions

Before adding any new package or library, confirm the version with the user to ensure we use
up-to-date dependencies.

- Do not assume which version to use
- Ask the user to verify the latest stable version
- Avoid outdated packages that may have security vulnerabilities or missing features

---

## Error Handling & Logging Strategy

Every project must have a centralized error handler rather than ad-hoc try/catch blocks scattered
throughout the codebase.

- Use structured logging (not `print`/`console.log`/`echo`)
- Log at appropriate levels: debug, info, warning, error
- Include context in log messages (module name, operation, relevant IDs)

---

## Centralized Logger — Single Off Switch

Route all logging through one dedicated logger class/module. Never call the language's
built-in output directly for logging (`print`, `console.log`, `echo`, `Debug.Log`,
`System.out`). Code calls the project logger; the project logger wraps the underlying sink.

- **One toggle.** Because every log goes through one place, logging can be turned off,
  level-filtered, or redirected (file, console, remote) from a single config flag — without
  touching call sites. Example: a `logEnabled` / `logLevel` setting the logger checks once.
- **Levels live in the logger.** Callers pass a level (debug/info/warning/error); the logger
  decides what is emitted based on central config. Callers never branch on "should I log?".
- **Wrap, don't scatter.** Built-in calls (`print`, framework loggers, `Debug.Log`) appear
  in exactly one file — the logger implementation. Everywhere else imports the logger.
- **Language specifics** still apply (e.g. Unity `[Conditional]` stripping, Flutter `logger`
  package, Python `logging`) — but they are configured inside the central logger, not at
  call sites.

The logger's name is fixed per language so it is the same known type in every project (see each
`*_RULES.md` for details):

| Language      | Class / export     | File                |
|---------------|--------------------|---------------------|
| Python        | `AppLogger`        | `app_logger.py`     |
| PHP           | `Logger`           | `Logger.php`        |
| Dart/Flutter  | `AppLogger`        | `app_logger.dart`   |
| Kotlin        | `AppLogger`        | `AppLogger.kt`      |
| C# (plain)    | `AppLogger`        | `AppLogger.cs`      |
| Unity C#      | `GameLog` (static) | `GameLog.cs`        |
| Svelte/JS/TS  | `logger` (export)  | `logger.ts`         |
| Arduino       | `Log`              | `Log.h` / `Log.cpp` |

---

## Input Validation at Boundaries

Always validate data at system boundaries — API inputs, user input, file uploads, external service
responses.

- Never trust external data; validate before processing
- Use language-appropriate validation libraries (e.g., Pydantic, Zod, FluentValidation)
- Fail fast with clear error messages when validation fails

---

## API Clients: the API Sorts, Filters and Pages (BINDING)

Applies to every project that reads data from an API — app, SPA, desktop tool, script.

- **Show what the API returns, in the order it returns it.** Never download a whole collection
  to sort, filter, search, count, group or join it locally.
- **Read lists page by page.** Send the page size and position and load the next page when the
  user scrolls or asks for more. Never loop over all pages to rebuild the full list on start or
  on refresh.
- **A new order, filter or search is a new request** with that parameter, starting at the first
  page. Reordering the rows already held is wrong as soon as the list is paged: the client holds
  one page, not the list.
- **Do not download again what you already hold.** After a create, update or delete use the row
  the response returned, or re-request the visible page — not the whole collection.
- **A missing parameter is API work.** When an API you own lacks the sort, filter, search,
  paging or count a screen needs, request it from the API project (linked todo or
  `/feedback:write`) and plan against that. "The list is small or unpaged today, so the client
  can do it" is not a reason. For a third-party API that cannot change, use the paging and
  sorting it offers and mark any remaining local work with a comment naming the missing
  capability.

The server half is `project_type/REST_API.md` -> "List Endpoints: Paging, Sorting, Filtering".

---

## Shared Contract Repository for API and Clients (BINDING)

When two or more projects we own talk over the wire — an API plus an app, an API plus a desktop
app, or all three — keep their shared values in one contract repository. This does not apply to
third-party APIs.

- **Why:** each side keeps its own copy of every value that crosses the wire. When one side adds a
  value the other does not know, the other side can break (for example, the API added a todo type
  and the watcher rejected the whole todo list).
- **One separate repository** (`<system>-contract`) holds the contract: at minimum every shared
  enum in `enums.json`, shaped as `"<Name>": {"values": [sorted unique], "direction":
  "api_to_client" | "client_to_api", "description": "<where it appears>"}`, plus a `README.md`
  with the change rules and the list of consumers. Do not add version numbers; the submodule
  pointer is the version.
- **Every project includes it as a git submodule at `contract/`.** Pick up changes with
  `git submodule update --remote contract` and commit the pointer bump. Production code never
  reads `contract/`; it is test input only.
- **The API is the producer:** export the contract from its own constants (one map, one export
  script) and add a freshness test that fails when the committed file differs from the export.
- **Each client is a consumer:** test that every mapped enum matches the contract in its
  direction (`api_to_client` sets are equal so the client knows every value;
  `client_to_api` client values are a subset) and that every contract name is mapped.
- Both tests skip when `contract/` is not checked out.
- **Change order:** for an `api_to_client` value, update the contract, release clients that know
  it, then have the API emit it. For a `client_to_api` value, update the contract and API first,
  then have the client send it. To remove a value, stop it at the API, then remove it from the
  contract, then from clients. Never rename a value; renaming is an add plus a remove. Add a new
  shared enum to the contract in the same change that introduces it.
- Clients still tolerate an unknown value (skip the row; do not fail the whole response) as a
  last line of defence, not as permission to skip the order.
- **Setting it up** is work in each project: when one project of the system lacks the submodule
  or its test, request it there (linked todo or `/feedback:write`).

---

## Maximum File Length — 300 Lines

Split files when they exceed 300 lines to keep code navigable during fast iteration.

- Extract classes, functions, or components into separate modules
- Group related extractions logically (by domain, not by type)
- Exceptions: generated files, configuration files, test files with many similar cases

---

## Naming Conventions

Be consistent within a project. Follow these defaults unless the language or framework dictates
otherwise:

- Files: `snake_case` (or language convention, e.g., `PascalCase` for C# classes)
- Classes: `PascalCase`
- Functions/methods: language convention (`snake_case` for Python/PHP, `camelCase` for Dart/JS/C#)
- Constants: `UPPER_SNAKE_CASE`
- Variables: language convention (`snake_case` for Python/PHP, `camelCase` for Dart/JS/C#)

---

## Comments Explain Why, Not What

Comment intent and non-obvious reasoning — not a restatement of the code. Good names carry the
*what*; comments carry the *why*.

- **Anti-pattern.** `i++ // increment i`. Redundant comments add noise and rot the moment the
  code changes.
- **Correct pattern.** Document *why* a workaround exists, why a non-obvious algorithm was
  chosen, or a constraint that isn't visible locally (`// API rejects batches > 500`).
- Prefer self-documenting code (clear names, small functions) over a comment that compensates
  for unclear code — see "Naming Conventions" and "Keep It Simple".
- Document the purpose of each module/class at its top.
- Keep comments in sync with the code; delete stale ones rather than letting them mislead.

---

## Security Baseline

Every project must follow these minimum security practices:

- Never commit secrets (`.env`, API keys, credentials, private keys)
- Escape output to prevent XSS/injection attacks
- Use parameterized queries or ORM-provided methods — never concatenate user input into queries
- Validate and sanitize all user input at system boundaries
- Keep dependencies updated to avoid known vulnerabilities

---

## No Hardcoded Environment Values

Never hardcode environment-specific values in code — filesystem paths, hostnames, IP addresses,
ports, base URLs. They differ across machines and environments and make code non-portable.

- **Anti-pattern.** `connect("192.168.1.50:5432")`, `open("C:\\Users\\bob\\data\\out.json")`.
- **Correct pattern.** Read them from the project's central config (the config class each
  `*_RULES.md` already mandates), with a committed `.example` template documenting every key.
- Distinct from the secrets rule above: this is about **portability** (runs anywhere), not
  secrecy. A non-secret hostname still belongs in config, not in code.

---

## No God Classes

A class that handles too many responsibilities becomes fragile, hard to test, and impossible to
reuse. Keep each class focused on a single purpose.

- **Warning signs**: more than 5 public methods, more than 4 constructor dependencies, or methods that span unrelated domains (e.g., a class that validates input, queries the database, and sends emails)
- Split by responsibility: extract collaborators (e.g., a `Validator`, a `Repository`, a `Notifier`) rather than piling logic into one class
- If you struggle to name the class without using "Manager", "Handler", "Service", or "Helper" as a catch-all, it likely does too much
- This complements the 300-line file rule — a short class can still be a god class if it owns too many concerns

---

## Self-Describing Classes

When behavior depends on which fields or properties a class has — such as search, serialization,
display, validation, or auditing — the class itself must declare those fields through a contract
(interface, abstract method, attribute/annotation, or introspection pattern). Never hardcode field
lists in consuming code.

- **Anti-pattern**: A search service contains a hardcoded list of fields to index for each entity;
  adding a new field requires updating every consumer manually
- **Correct pattern**: Each class implements a contract (e.g., `GetSearchableFields()`,
  `GetDisplayColumns()`) that returns its own relevant fields, so adding a field in one place
  automatically propagates everywhere
- This applies to any cross-cutting concern that operates over class fields: search, filtering,
  export, form generation, diffing, logging, etc.
- Combine with compile-time checks where the language supports them (e.g., sealed interfaces,
  exhaustive matching) to ensure new fields cannot be silently ignored

---

## Search Across Partial Words

When implementing user-facing search, split the query on whitespace and match every term as a
case-insensitive substring of the searchable text, regardless of term order. For example,
`release bat` should find `release_build.bat`. Preserve the project's existing searchable fields.

---

## Inject Collaborators, Don't Fold Dependencies In

Composition reuse comes in two shapes, and they differ sharply in how much coupling they add to
the reusing class. **Folding** a helper into a class (mixin, trait, multiple inheritance, copy-in
include) merges *all of the helper's own dependencies* into that class — reuse five such helpers
and every one of their imports is now the host's coupling. **Injecting** a collaborator adds a
single dependency: the collaborator, which is built once and shared as a hub.

Prefer injected collaborators. Reserve fold-in reuse for helpers that are stateless and carry no
dependencies of their own.

- **Anti-pattern**: A controller reuses five behavior mixins/traits; each brings its own service,
  DTO, and constant imports, so the controller transitively depends on a few dozen things and is
  hard to test in isolation.
- **Correct pattern**: Extract that behavior into a collaborator object injected via the
  constructor. The controller depends on the collaborator; the collaborator is reused across many
  controllers as a shared, well-tested hub.

### Inject services; never instantiate one inside a method

Constructing a service with `new` (or the language equivalent) inside a method hides the
dependency from the class's public contract and makes it impossible to substitute in a test. Pass
collaborators in through the constructor.

- **Anti-pattern**: A method does `helper = new EmailPreparer(); helper.prepare(...)`. Nothing in
  the class signature reveals the dependency, and no test can replace it.
- **Correct pattern**: Inject `EmailPreparer` once; the method calls the injected instance.

### Collapse config-callback swarms into one value object

When a base class pulls its configuration from the subclass through many small overridable getters
that the subclass fills in one-line-each, each getter is a separate touch-point and the wiring is
spread across dozens of methods. Bundle the related values into a single config object built once
and handed to the base (see **Use Objects for Related Values**). This also keeps such classes off
the wrong side of **No God Classes**.

- **Anti-pattern**: A subclass implements `getSendEndpoint()`, `getSendSuccessKey()`,
  `getSendFailureRedirect()`, and a dozen more one-line getters, each naming one constant.
- **Correct pattern**: The subclass builds one `SendConfig` value object once; the base reads its
  fields.

# Version
13

Increase this version number whenever this rule file changes.

# Flutter Rules (FVM + Mobile)

See `COMMON_RULES.md` for rules that apply to all languages.

## Core principles

1. Flutter's core principle: Composition over inheritance - small, focused widgets
2. Testability: Each widget can be tested in isolation
3. Single Responsibility: One widget = one job
4. Reusability: Components can be used elsewhere
5. Readability: Smaller files (~100-200 lines) are easier to maintain
6. Follow SOLID principles (Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion)

## Documentation Comments

Use `///` doc comments on all public classes, methods, and properties:

```dart
/// Service responsible for user authentication.
class AuthService {
  /// Attempts to log in with the given [email] and [password].
  ///
  /// Returns the authenticated [User] on success.
  /// Throws [AuthException] if credentials are invalid.
  Future<User> login(String email, String password) async {
    // ...
  }
}
```

Rules:
- Every public class, method, and property must have a `///` comment
- Use `[paramName]` to reference parameters in doc comments
- Keep descriptions concise; one sentence for simple members
- Do not use `//` block comments for documentation

---

## When to Use `part` / `part of`

Prefer normal `import` / `export` for all hand-written code. Do **not** use `part`
to split large classes, organize features into folders, or share utilities — it
hides dependencies, weakens encapsulation (all `part` files share one private
scope), and makes refactoring harder.

Use `part` only when:

1. **Code generation requires it** — the common modern case. Generators emit into
   `*.g.dart` / `*.freezed.dart` files included via `part`:

   ```dart
   import 'package:json_annotation/json_annotation.dart';

   part 'user.g.dart';

   @JsonSerializable()
   class User {
     final String name;
     User(this.name);
     factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
     Map<String, dynamic> toJson() => _$UserToJson(this);
   }
   ```

   Applies to `freezed`, `json_serializable`, `objectbox` (`objectbox.g.dart`), and
   similar — see the JSON Serialization and Database (ObjectBox) sections.

2. **One tightly-coupled library** (rare) — several files that genuinely form a
   single library and must share library-private (`_`) members.

| Scenario                                   | Use `part`? |
| ------------------------------------------ | ----------- |
| Application / widget code                  | No          |
| Splitting a large class across files       | No          |
| Organizing features or modules             | No          |
| Generated files (`freezed`, `*.g.dart`)    | Yes         |
| One tightly-coupled library impl           | Sometimes   |

Rule of thumb: **if you write the code, use imports/exports; if a generator
requires it, use `part`.**

---

## Mixins

Mixins share behavior across classes that do **not** share an inheritance chain.
Reach for a mixin only when composition (a plain helper class injected via `GetIt`,
or a field) does not fit — Flutter favors composition over inheritance, and a
mixin is a form of inheritance.

### Rules

1. **Use the `mixin` keyword, never a `class` as a mixin.** A `mixin` cannot be
   instantiated or extended, which documents intent and prevents misuse. Use
   `mixin class` only in the rare case a type must serve as both — never by default.

2. **Constrain with `on` whenever the mixin depends on a host type.** This both
   restricts where the mixin can be applied and grants typed access to the host's
   members. Prefer `mixin AnalyticsLogging on State` over an unconstrained mixin
   that assumes a `context`.

3. **Keep mixins stateless.** All `part`/mixin members live in the host's scope, so
   a mutable field in a mixin silently couples to — and can collide with — the
   host's fields. If state is unavoidable, prefix fields with `_`, document the
   ownership, and keep it to one field.

4. **One capability per mixin (single responsibility).** A mixin named for a
   behavior (`Disposable`, `Validatable`) is good; a `UtilsMixin` grab-bag is not.

5. **Name by capability**, ending in `-able` or with a `Mixin` suffix, matching the
   existing `SearchableMixin` convention. Be consistent within a project.

6. **Only call `super.method()` when the `on` constraint guarantees it exists.**
   Mixins are linearized left-to-right; later mixins override earlier ones. Know the
   apply order when overriding lifecycle methods (e.g. `initState`/`dispose`).

7. **Mark host-only members `@protected`** and give every public member a `///`
   doc comment, per the Documentation Comments rules.

8. **Do not use a mixin to share code that could be a standalone service.** If the
   behavior owns state or has dependencies, make it a class and inject it with
   `GetIt` — see Dependency Injection.

Legit Flutter framework mixins — `TickerProviderStateMixin`,
`AutomaticKeepAliveClientMixin`, `WidgetsBindingObserver` — model all of the above:
host-constrained, behavior-focused, named by capability.

### When to use a mixin vs. the alternative

| Need                                                    | Use                          |
| ------------------------------------------------------- | ---------------------------- |
| Share stateless behavior across unrelated classes       | `mixin`                      |
| Add behavior that needs a specific host (`State`, etc.) | `mixin ... on HostType`      |
| Share behavior that owns state or dependencies          | Class + `GetIt` (composition)|
| Define a contract only (no implementation)              | `abstract interface class`   |
| Reuse one widget's look/structure                       | Compose widgets, not a mixin |

Rule of thumb: **a mixin adds behavior, not state.** If you find yourself storing
data in a mixin, it should probably be a class you inject instead.

---

## Flutter Version Management

Use FVM (Flutter Version Manager) for all projects. Create `.fvmrc` in the project root:

```json
{
  "flutter": "3.44.0"
}
```

Latest verified stable as of 2026-05-26. Confirm with `fvm releases --channel stable` for new projects.

All Flutter commands should be prefixed with `fvm`:

```bash
fvm flutter pub get
fvm flutter run
fvm flutter build apk
```

---

## Localization

Use the `flutter_i18n_translations` library for multi-language support:
https://github.com/BenjaminKobjolke/flutter-i18n-translations

### Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_i18n_translations:
    git:
      url: https://github.com/BenjaminKobjolke/flutter-i18n-translations.git
```

Then run:

```bash
fvm flutter pub get
```

### Directory Structure

```
project/
├── assets/
│   └── i18n/
│       ├── en.json         # English (default)
│       ├── de.json         # German
│       └── languages.json  # Language metadata
├── lib/
│   ├── config/
│   │   ├── constants.dart
│   │   └── translation_keys.dart
│   └── main.dart
└── pubspec.yaml
```

### Configure Assets

In `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/i18n/
```

### Translation File Format

Create `assets/i18n/en.json`:

```json
{
  "app": {
    "name": "My Application",
    "welcome": "Welcome, {name}!"
  },
  "nav": {
    "dashboard": "Dashboard",
    "settings": "Settings",
    "logout": "Logout"
  },
  "auth": {
    "login_title": "Login",
    "signin_subtitle": "Sign in to access your dashboard",
    "error": {
      "auth_failed": "Authentication failed. Please try again.",
      "rate_limited": "Too many attempts. Please try again later."
    }
  },
  "common": {
    "cancel": "Cancel",
    "save": "Save",
    "delete": "Delete",
    "edit": "Edit"
  }
}
```

Create `assets/i18n/languages.json`:

```json
{
  "en": "English",
  "de": "Deutsch"
}
```

### Initialization

In `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_i18n_translations/flutter_i18n_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize localization
  final localizationService = LocalizationService();
  final languageCode = await determineSystemLanguage();
  await localizationService.load(languageCode);
  AppLocalizations.init(localizationService);

  runApp(const MyApp());
}
```

### Usage in Widgets

```dart
import 'package:flutter_i18n_translations/flutter_i18n_translations.dart';
import 'package:myapp/config/translation_keys.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple translation
        Text(AppLocalizations.tr(TK.appName)),

        // With parameters
        Text(AppLocalizations.tr(TK.appWelcome,
          params: {'name': 'John'}
        )),

        // Get current language
        Text('Current: ${AppLocalizations.currentLanguage}'),
      ],
    );
  }
}
```

---

## Translation Key Naming Convention

Use dot notation with logical grouping:

```
section.subsection.key

app.name               - Application info
nav.dashboard          - Navigation items
auth.login_title       - Authentication related
auth.error.auth_failed - Nested error messages
common.save            - Reusable UI elements
```

---

## Translation Keys as Constants

Using raw strings like `AppLocalizations.tr('nav.dashboard')` is error-prone. Create a `TK` class with all keys as constants for IDE autocomplete and compile-time checking.

Create `lib/config/translation_keys.dart`:

```dart
// lib/config/translation_keys.dart
class TK {
  TK._();

  // App
  static const String appName = 'app.name';
  static const String appWelcome = 'app.welcome';

  // Navigation
  static const String navDashboard = 'nav.dashboard';
  static const String navSettings = 'nav.settings';
  static const String navLogout = 'nav.logout';

  // Auth
  static const String authLoginTitle = 'auth.login_title';
  static const String authSigninSubtitle = 'auth.signin_subtitle';
  static const String authErrorAuthFailed = 'auth.error.auth_failed';
  static const String authErrorRateLimited = 'auth.error.rate_limited';

  // Common
  static const String commonCancel = 'common.cancel';
  static const String commonSave = 'common.save';
  static const String commonDelete = 'common.delete';
  static const String commonEdit = 'common.edit';
}
```

Usage:

```dart
import 'package:myapp/config/translation_keys.dart';

// Instead of:
AppLocalizations.tr('nav.dashboard');

// Use:
AppLocalizations.tr(TK.navDashboard);
```

### Benefits

- IDE autocomplete for all translation keys
- Compile-time error if constant doesn't exist
- Easy to find all usages of a key
- Refactoring support

### Detecting unused or missing keys

Every Flutter project that uses the `TK` pattern **must** ship tooling that
detects all of the following:

1. TK constants whose i18n path does not exist (broken at runtime).
2. TK constants with no callers (dead Dart code).
3. i18n leaves with no TK constant pointing at them (orphan translations).
4. Raw `AppLocalizations.tr('literal')` calls that bypass the TK class.

Reference implementation: `tools/check_translation_keys.dart` +
`tools/check_translation_keys.bat`, shipped in `flutter_setup_files/tools/`.
Run the audit whenever a TK constant or i18n key is added or removed, and
do not consider the change complete while the audit reports any issue. The
`--fix` flag auto-substitutes matchable raw literals **and** auto-creates
TK constants for raw literals that already have a matching i18n leaf;
remaining "broken" entries (raw literal whose i18n leaf is missing too)
must be resolved by hand.

Copy the whole set — the three scripts below plus `translation_key_audit.dart`
and the `.bat` wrappers. Only two constants in `check_translation_keys.dart`
are per-project: `_topKeyToClass` (top-level i18n key → owning `TK*` class)
and `_packageName`.

Companion tooling lives next to the audit script:

- `translation_key_audit.dart` — the shared detector every script imports.
  Layout, TK parsing, and the caller scan live here so a pruner can never
  drift from the audit and delete keys the audit considers live.
- `prune_unused_translation_keys.dart` — deletes dead TK constants from
  `lib/config/translation_keys/tk_*.dart`. Safe because the audit
  guarantees zero references. Drops only the declaration lines, leaving the
  rest of the file byte-identical.
- `prune_orphan_i18n_leaves.dart` — removes i18n leaves no caller
  references (TK or raw literal). When `tools/attributes_to_remove.json`
  exists, removed paths are merged into it so a translator batch can strip
  them from locale files the script does not own; projects without that
  batch never create the file.
- `split_translation_keys.dart` — when the project's `TK` class grows past
  ~500 lines, split it into one `TKModule` class per top-level i18n key
  group with a barrel re-export. The split keeps every existing
  `TK.foo`-style call site valid after a one-shot codemod.

Two detection rules exist because a naive audit reports false positives on
both, and a pruner acting on them destroys working code:

- **`...Prefix` constants.** A constant whose name ends in `Prefix` holds a
  partial path completed at runtime — `tr('${TKStats.weekStatusPrefix}$s')`.
  It is treated as matching any leaf below its value, so it is not "missing"
  and the leaves it reaches are not orphans.
- **The `_tr` wrapper.** Widgets commonly define
  `String _tr(String key) => AppLocalizations.tr(key);` and call `_tr(...)`.
  The raw-literal scan matches both spellings; matching only
  `AppLocalizations.tr` makes category 4 blind to most of the codebase.

Both i18n layouts are auto-detected at startup — modular
(`assets/i18n/modules.json` + `assets/i18n/<module>/<locale>.json`) and
single-file (`assets/i18n/<locale>.json`). Locales come from
`assets/i18n/languages.json`.

---

## Language Switching

```dart
// Get available languages
final languages = AppLocalizations.getAvailableLanguages(); // ['de', 'en']

// Get language display name
final displayName = AppLocalizations.getLanguageName('de'); // "Deutsch"

// Switch language
await localizationService.load('de');
// Rebuild UI (e.g., restart app or use state management)
```

### Persisting Language Choice

```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> changeLanguage(String languageCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', languageCode);
  await localizationService.load(languageCode);
}

// On app start
final prefs = await SharedPreferences.getInstance();
final savedLanguage = prefs.getString('language');
final languageCode = savedLanguage ?? await determineSystemLanguage();
```

---

## Adding New Languages

1. Copy `assets/i18n/en.json` to `assets/i18n/de.json`
2. Translate all values (keep keys identical)
3. Update `assets/i18n/languages.json`:

```json
{
  "en": "English",
  "de": "Deutsch"
}
```

---

## Project Structure

Standard Flutter mobile project structure:

```
project/
├── android/                    # Android platform files
├── ios/                        # iOS platform files
├── assets/
│   ├── i18n/                   # Translation files
│   └── images/                 # Image assets
├── lib/
│   ├── config/
│   │   ├── app_config.dart     # API URLs, timeouts
│   │   ├── constants.dart      # App constants
│   │   └── translation_keys.dart
│   ├── models/                 # Data models & ObjectBox entities
│   ├── repositories/           # Data access (ObjectBox CRUD)
│   ├── services/
│   │   ├── api_client.dart     # Dio HTTP client singleton
│   │   └── objectbox_service.dart  # ObjectBox initialization
│   ├── screens/                # Full-screen widgets
│   ├── widgets/                # Reusable widgets
│   ├── objectbox.g.dart        # Generated ObjectBox code
│   ├── objectbox-model.json    # Generated ObjectBox model
│   └── main.dart
├── test/                       # Unit and widget tests
├── tools/                      # Build scripts
│   ├── run_tests.bat
│   ├── build_debug.bat
│   └── build_release.bat
├── .fvmrc                      # FVM Flutter version
├── pubspec.yaml
├── install.bat
├── update.bat
└── README.md
```

---

## Project Setup Scripts

For projects that ship a Windows desktop installer, follow the optional
[Windows release guide](flutter_setup_files/WINDOWS_RELEASES.md). It is not a
requirement for mobile-only projects.

Copy the setup batch files from the `flutter_setup_files/` folder bundled with the
coding-rules plugin (next to this rules file).

### install.bat

Initial project setup:

- Checks if FVM is installed
- Runs `fvm install` to install Flutter version
- Runs `fvm flutter pub get` to install dependencies
- Runs tests to verify setup

### update.bat

Update all dependencies:

- Updates dependencies with `fvm flutter pub upgrade`
- Runs `fvm flutter analyze` for linting
- Runs tests to verify compatibility

### tools/run_tests.bat

Run the test suite:

- Runs `fvm flutter test --reporter expanded` directly, so one line per test
  appears while the tests run and the script captures flutter test's own exit code
- Shows pass/fail summary based on that captured exit code, then `exit /b`s with it
- Never redirect the run into a temp file and print it afterwards: the script is
  then silent for the whole run and a hanging test looks like a slow suite
- If you add noise filtering for third-party log spam, filter live with the
  PowerShell line from the comment in the bat (it ends in `exit $LASTEXITCODE`) -
  never pipe `fvm flutter test` straight into `findstr`. The pipe's exit code
  becomes the filter's exit code, not flutter test's, so a real failure can
  silently read as a pass (or vice versa). `findstr` also has a ~8191-char
  line-length limit and errors on long lines.

### tools/build_debug.bat

Build debug APK:

- Runs `fvm flutter build apk --debug`
- Shows output location

### tools/build_release.bat

Build release APK:

- Runs `fvm flutter build apk --release`
- Shows output location

### Usage

```bash
# First time setup
install.bat

# Run tests
tools\run_tests.bat

# Build debug APK
tools\build_debug.bat

# Build release APK
tools\build_release.bat

# Update dependencies
update.bat
```

---

## Approved Libraries

Before implementing any new feature, **check
[`flutter_setup_files/LIBRARIES.md`](flutter_setup_files/LIBRARIES.md)** — it lists the approved
third-party libraries, their confirmed versions, and a reference implementation for each.

- If a listed library already covers the job, use it. Do not hand-roll an equivalent and do not
  introduce a competing package for the same concern.
- If nothing listed covers it, confirm the version with the user (see `COMMON_RULES.md` →
  "Confirm Dependency Versions"), then add the library to `LIBRARIES.md` with a pointer to the
  first real implementation, so the next project picks it up automatically.

This is the same "check before you build" rule as `COMMON_RULES.md` → "Reusable Tooling",
applied to dependencies instead of scripts.

---

## App Icons

Whenever icons are involved — setting up a new project's launcher icon, replacing
existing art, adding a notification icon, or debugging one that renders wrong —
**read [`flutter_setup_files/ICONS.md`](flutter_setup_files/ICONS.md) first.**

Every Android app ships an **adaptive icon**: the launcher chooses its mask shape,
the app controls the foreground and background colour, and a legacy-only icon may
get a launcher-drawn plate — often a white circle.

House style is a **solid black background with simple white line art**. The guide
covers why (an adaptive icon's background layer must be opaque, so transparent is
not an option), the source-art layout, the `flutter_launcher_icons` config, and
the separate white-on-transparent notification icon Android needs — pointing a
notification at the launcher icon renders a featureless white blob in the status
bar.

Each project records its own paths and wiring in `docs/ICONS.md`.

---

## Pin Android Dependencies Declared as Version Ranges

Some plugins' Android SDKs declare dependencies as **version ranges** (seen: OneSignal Android
SDK 5.10.0 via `onesignal_flutter` 5.6.10). For a range Gradle must list the available versions
on Google Maven (`dl.google.com`) and caches that list for only 24 hours; an exact version
resolves from the local Gradle cache with no network. A build with range-declared dependencies
therefore needs Google Maven to answer about once a day. When it does not, the release build
fails in `:app:mergeReleaseNativeLibs` with `Could not resolve ...{require [...]}` and
`Repository Google is disabled due to earlier error below` — with no code change and every
artifact already cached.

**The app's Gradle build forces every range-declared Android module to the version it already
resolves to.**

Find the ranges, from `android/`:

```bash
gradlew :app:dependencies --configuration releaseRuntimeClasspath --console=plain
```

- Every `{require [...]}` line is a range (a bare `[1.0, 2.0)` or `1.+` request is the same
  thing); the version after `->` is the one to pin.
- The command exits 0 even when resolution fails. `FAILED` lines are the signal, never the
  exit code.
- Add `--offline` to read the report from the Gradle cache while Google Maven does not answer.

Pin them in `android/build.gradle.kts`, as its own block after the `allprojects { repositories
{ ... } }` block:

```kotlin
// OneSignal 5.10.0 declares these as version ranges. Gradle re-lists a range on Google Maven
// once its 24-hour cache expires, so the build failed whenever dl.google.com did not answer,
// although every artifact was already cached. Forcing the versions the ranges resolved to
// removes that request. force also holds a module down, so after upgrading onesignal_flutter
// or any plugin that needs one of these: remove this block, run
// `gradlew :app:dependencies --configuration releaseRuntimeClasspath`, and pin what each
// `{require [...]}` line resolves to.
allprojects {
    configurations.configureEach {
        resolutionStrategy.force(
            "com.google.firebase:firebase-messaging:24.0.0",
            "androidx.work:work-runtime:2.8.1",
        )
    }
}
```

A Groovy `android/build.gradle` takes the same block with single-quoted strings and no
trailing comma.

Rules:

- **Pin what the range resolves to in this app, never a version copied from another app.**
  Other plugins can raise a module above the declaring plugin's range (seen: `androidx.browser`
  at 1.9.0 through `url_launcher_android`, above OneSignal's `[1.0.0, 1.3.99]`).
- **Use `resolutionStrategy.force`, not `eachDependency`.** Replacing only the range requests
  through `eachDependency` still sends a request to `dl.google.com`.
- **The pins carry a comment** naming the declaring plugin and version, why the pins exist, and
  how to re-derive them, as in the example.
- **Re-derive after upgrading** the declaring plugin or any plugin that needs a pinned module:
  a forced version also holds the module down. Remove the block, run the report, pin again.
- The pins remove only the daily version lookup. A library that was never downloaded (after a
  package or Flutter upgrade) still needs Google Maven once.

---

# Essential Rules

## 1) Use `pubspec.yaml` as the single source of truth

Keep all dependencies and configuration in `pubspec.yaml`.

Recommended baseline:

- Flutter/Dart SDK version constraints
- Dependencies managed via `fvm flutter pub add ...`
- Lock file committed: `pubspec.lock`

### Standard Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Localization
  flutter_i18n_translations:
    git:
      url: https://github.com/BenjaminKobjolke/flutter-i18n-translations.git

  # HTTP
  dio: ^5.9.0

  # Database
  objectbox: ^5.1.0

  # Utilities
  path_provider: ^2.1.0
  path: ^1.9.0
  shared_preferences: ^2.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

  # ObjectBox code generation
  objectbox_generator: ^5.1.0
  build_runner: ^2.4.0
```

---

## 2) Enforce linting and formatting

Use the standard Flutter analyzer:

```bash
fvm flutter analyze
fvm dart format lib/
```

Configure `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_print: true
```

---

## 3) Centralize configuration

No "magic values" in code. Use a config class:

```dart
// lib/config/app_config.dart
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = 'https://api.example.com';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const bool debugMode = true;
}
```

### Sensitive Data

Never commit API keys, secrets, or credentials to version control. Use `.env` files for sensitive values:

1. Add `flutter_dotenv` to `pubspec.yaml`:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. Create a `.env` file in the project root:

```
API_KEY=your_secret_key_here
API_SECRET=your_secret_here
```

3. Add `.env` to `.gitignore`:

```
.env
```

4. Load in `main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  // Access values: dotenv.env['API_KEY']
  runApp(const MyApp());
}
```

5. Provide a `.env.example` file (committed) with placeholder values so other developers know which keys are required.

---

## 4) Logging & Error Handling

### Logging

Never use `print()` for logging. Use `dart:developer` or the `logger` package:

```dart
import 'dart:developer' as developer;

// Simple log
developer.log('User loaded successfully', name: 'UserService');

// Log with error
developer.log('Failed to load user', name: 'UserService', error: e, stackTrace: stackTrace);
```

Or with the `logger` package:

```yaml
dependencies:
  logger: ^2.0.0
```

```dart
import 'package:logger/logger.dart';

final logger = Logger();

logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message', error: e, stackTrace: stackTrace);
```

#### Central Logger Class

Route all logging through one class named **`AppLogger`** (`app_logger.dart`). Never call
`print()`, `developer.log`, or the `logger` package directly from feature code — only
`AppLogger` wraps them. This gives a single enable/level toggle (e.g. `AppConfig.logLevel`)
without touching call sites.

```dart
AppLogger.d('Debug message');
AppLogger.i('User loaded', name: 'UserService');
AppLogger.e('Failed to load user', error: e, stackTrace: stackTrace);
```

### Error Handling

- Use try-catch for all async and critical operations
- Display user-friendly error messages in the UI (never show raw exceptions)
- Log errors with context (class name, method name, relevant parameters)

```dart
Future<void> loadUser(int userId) async {
  try {
    final user = await _userService.getUser(userId);
    emit(state.copyWith(user: user));
  } on DioException catch (e) {
    developer.log('Failed to load user $userId', name: 'UserCubit', error: e);
    emit(state.copyWith(errorMessage: AppLocalizations.tr(TK.errorLoadFailed)));
  }
}
```

---

## 5) Tests are mandatory

Use Flutter test framework:

```bash
fvm flutter test
```

Rules:

- Unit tests for services and business logic
- Widget tests for UI components
- No network in unit tests (use mocks)
- Run tests in CI on every push

---

## 6) Required Batch Files

Every project must include these batch files:

- `install.bat` - In the root directory, initial project setup
- `update.bat` - In the root directory, update dependencies
- `tools/run_tests.bat` - Runs the test suite
- `tools/build_debug.bat` - Builds debug APK
- `tools/build_release.bat` - Builds release APK

---

## 7) State Management (Cubit)

Use **Cubit** from the `flutter_bloc` package for state management. Cubit is the recommended approach for all Flutter projects.

### Why Cubit?

- **Simpler than BLoC**: No events, just methods that emit states
- **Predictable**: Clear separation between UI and business logic
- **Testable**: Easy to unit test state changes
- **Scalable**: Works for simple screens and complex apps alike
- **Less boilerplate**: Compared to full BLoC pattern

### Installation

```yaml
dependencies:
  flutter_bloc: ^8.1.0
  equatable: ^2.0.5  # For state comparison
```

```bash
fvm flutter pub get
```

### Basic Example

**State class** (`lib/cubits/counter_state.dart`):

```dart
import 'package:equatable/equatable.dart';

class CounterState extends Equatable {
  final int count;
  final bool isLoading;

  const CounterState({
    this.count = 0,
    this.isLoading = false,
  });

  CounterState copyWith({int? count, bool? isLoading}) {
    return CounterState(
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [count, isLoading];
}
```

**Cubit class** (`lib/cubits/counter_cubit.dart`):

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'counter_state.dart';

class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(const CounterState());

  void increment() {
    emit(state.copyWith(count: state.count + 1));
  }

  void decrement() {
    emit(state.copyWith(count: state.count - 1));
  }

  Future<void> loadFromApi() async {
    emit(state.copyWith(isLoading: true));
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    emit(state.copyWith(count: 42, isLoading: false));
  }
}
```

**Usage in Widget**:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/counter_cubit.dart';
import '../cubits/counter_state.dart';

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(),
      child: const CounterView(),
    );
  }
}

class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: BlocBuilder<CounterCubit, CounterState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Text('Count: ${state.count}'),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => context.read<CounterCubit>().increment(),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => context.read<CounterCubit>().decrement(),
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
```

### Project Structure

```
lib/
├── cubits/
│   ├── counter_cubit.dart
│   ├── counter_state.dart
│   ├── auth_cubit.dart
│   └── auth_state.dart
├── screens/
│   └── counter_screen.dart
└── main.dart
```

### Key Patterns

- **One Cubit per feature/screen**: Keep cubits focused
- **Immutable states**: Always use `copyWith` pattern
- **Equatable**: Use for efficient state comparison
- **BlocProvider**: Provide cubits at the widget level
- **BlocBuilder**: Rebuild UI when state changes
- **BlocListener**: Handle side effects (navigation, snackbars)

---

## 8) HTTP Communication (Dio)

Use Dio for all HTTP communication.

### Installation

```bash
fvm flutter pub add dio
```

Add to `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.9.0
```

### API Client Singleton

Create `lib/services/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:myapp/config/app_config.dart';

class ApiClient {
  ApiClient._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.requestTimeout,
      receiveTimeout: AppConfig.requestTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static Dio get instance => _dio;
}
```

### Usage Example

```dart
import 'package:myapp/services/api_client.dart';

class UserService {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> getUser(int id) async {
    final response = await _dio.get('/users/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final response = await _dio.post('/users', data: data);
    return response.data;
  }
}
```

### Error Handling

```dart
import 'package:dio/dio.dart';

Future<void> fetchData() async {
  try {
    final response = await ApiClient.instance.get('/data');
    // Handle success
  } on DioException catch (e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        // Handle timeout
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        // Handle HTTP errors (400, 401, 404, 500, etc.)
        break;
      case DioExceptionType.connectionError:
        // Handle no internet
        break;
      default:
        // Handle other errors
        break;
    }
  }
}
```

### Mobile Data Budget (BINDING)

An app that polls keeps downloading on every tick even when the server answer did not change, and
holds its data in memory only. The server half of this contract is
`project_type/REST_API.md` -> "Response Size and Mobile Data"; these are the client half.

- **Ask the API for exactly what the screen shows.** Load a screen's initial API data with one
  call, reusing a list or detail operation when sufficient and requesting an overview endpoint
  when several datasets are needed. Never call a detail endpoint once per list item (N+1). Read
  slim lists (`fields=slim`), filter server-side, fetch full detail only when a detail screen
  opens, and send the last offset for growing logs and append. If the API lacks the required
  slim/overview/offset endpoint or a sort, filter or paging parameter, request it from the API
  project instead of filtering client-side.
- **Lists are paged and sorted by the API.** `COMMON_RULES.md` -> "API Clients: the API Sorts,
  Filters and Pages" is binding here. Build the list with `ListView.builder`, request the next
  page (`limit`/`offset`) when the last rows scroll into view, and start again at the first page
  when the sort order or a filter changes. A sort menu sends the `sort` parameter; it never
  reorders the rows held in memory. Page state lives in the provider, not in the widget.
  See `project_type/REST_API.md` -> "Screen Overview Endpoints" (an app-only project may not
  install `REST_API.md`, so the client rule stays here).
- **Conditional GET in the client.** A Dio interceptor in the `ApiClient` singleton — registered
  with `_dio.interceptors.add(EtagInterceptor(box))` the same way `flutter/IN_APP_DEBUGGER.md` adds
  the Logarte interceptor (switch the inline `_dio` above to its `_createDio()` form) — stores
  `ETag` + body per request URL in an ObjectBox entity (`etag`, `body`; section 9 is already a
  standard dependency, so no cache package is added), sends `If-None-Match` on the next `GET`, and
  treats `304` as "use the cached body". Echo the tag **verbatim**, including a `-gzip` suffix. A
  `304` must not trigger "new data" side effects (sounds, notifications, animations). On a network
  failure serve the cache but forget the tag. `validateStatus` must accept `304` — Dio's default
  accepts only `2xx`, so a `304` would otherwise surface as an error:

  ```dart
  class EtagInterceptor extends Interceptor {
    EtagInterceptor(this._box);
    final Box<CachedResponse> _box; // ObjectBox entity: id, url, etag, body

    CachedResponse? _cached(String url) {
      final query = _box.query(CachedResponse_.url.equals(url)).build();
      try {
        return query.findFirst();
      } finally {
        query.close();
      }
    }

    @override
    void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
      final tag = _cached(options.uri.toString())?.etag;
      if (tag != null && options.method == 'GET') {
        options.headers['If-None-Match'] = tag; // verbatim, -gzip suffix included
      }
      handler.next(options);
    }

    @override
    void onResponse(Response response, ResponseInterceptorHandler handler) {
      final url = response.requestOptions.uri.toString();
      if (response.statusCode == 304) {
        final cached = _cached(url)!;              // a 304 carries no body
        response.statusCode = 200;
        response.headers.value('etag', cached.etag); // restore the tag for the next call
        response.data = jsonDecode(cached.body);
      } else if (response.statusCode == 200 && response.headers.value('etag') != null) {
        _box.put(CachedResponse(
            url: url, etag: response.headers.value('etag')!, body: jsonEncode(response.data)));
      }
      handler.next(response);
    }

    @override
    void onError(DioException err, ErrorInterceptorHandler handler) {
      final cached = _cached(err.requestOptions.uri.toString());
      if (cached == null || err.response != null) {
        handler.next(err);
        return;
      }
      _box.remove(cached.id); // forget the tag: the next call fetches without If-None-Match
      handler.resolve(Response(
          requestOptions: err.requestOptions, statusCode: 200, data: jsonDecode(cached.body)));
    }
  }
  ```
- **gzip comes free.** `dart:io`'s `HttpClient` (Dio's default adapter on mobile) sends
  `Accept-Encoding: gzip` and decompresses the response; never disable it.
- **Polling is foreground-only and bounded.** Every timer/poll loop checks
  `WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed` before each fetch, stops on
  pause/dispose, and has an overall timeout. Inject `bool Function() isForeground` so a test can
  drive the lifecycle. User-settable refresh intervals live in `AppConfig` (section 3) with a
  data-safe minimum (15 s) and default (30 s); clamp stored values below the minimum. Screen-awake/
  kiosk modes still count as foreground, so the minimum matters.
- **Resume reloads only what is visible.** On `resumed`, reload the current tab plus any cheap
  overview; mark the other tabs stale and let them reload in their own `onSelected`.
- **Images: disk cache + thumbnails.** Cache image bytes on disk keyed by image id under
  `path_provider`'s cache directory (`path_provider` is already a standard dependency;
  `LIBRARIES.md` lists no image-cache package, so add none), size-capped — the bytes never change.
  Use a thumbnail for list/preview and fetch full size only when the image is opened. A
  memory-only cache refetches on every screen open.
- **Measure.** Android Settings -> Apps -> <app> -> Mobile data splits foreground and background
  usage; a high background share means a poller ignores the lifecycle.
- **Test it:** the interceptor (no tag on the first call, tag sent after `200`, `304` returns the
  cached body, a network failure serves the cache and clears the tag); a poller skips fetches while
  backgrounded and resumes; the interval clamp.

---

## 9) Database (ObjectBox)

Use ObjectBox for local persistence.

### Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  objectbox: ^5.1.0

dev_dependencies:
  objectbox_generator: ^5.1.0
  build_runner: ^2.4.0
```

Run:

```bash
fvm flutter pub get
fvm dart run build_runner build
```

### Entity Example

Create `lib/models/user.dart`:

```dart
import 'package:objectbox/objectbox.dart';

@Entity()
class User {
  @Id()
  int id = 0;

  String name;
  String email;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  User({
    this.id = 0,
    required this.name,
    required this.email,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
```

### ObjectBox Initialization

Create `lib/services/objectbox_service.dart`:

```dart
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../objectbox.g.dart';

class ObjectBoxService {
  ObjectBoxService._();

  static Store? _store;

  static Store get store {
    if (_store == null) {
      throw Exception('ObjectBox not initialized. Call init() first.');
    }
    return _store!;
  }

  static Future<void> init() async {
    if (_store != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'objectbox');
    _store = await openStore(directory: dbPath);
  }

  static void close() {
    _store?.close();
    _store = null;
  }
}
```

Initialize in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ObjectBox
  await ObjectBoxService.init();

  // Initialize localization
  // ...

  runApp(const MyApp());
}
```

### Basic CRUD Operations

```dart
import 'package:myapp/models/user.dart';
import 'package:myapp/services/objectbox_service.dart';
import '../objectbox.g.dart';

class UserRepository {
  final Box<User> _box = ObjectBoxService.store.box<User>();

  // Create or Update
  int put(User user) {
    return _box.put(user);
  }

  // Get by ID
  User? get(int id) {
    return _box.get(id);
  }

  // Get all
  List<User> getAll() {
    return _box.getAll();
  }

  // Delete
  bool delete(int id) {
    return _box.remove(id);
  }

  // Query
  List<User> findByName(String name) {
    final query = _box.query(User_.name.equals(name)).build();
    final results = query.find();
    query.close();
    return results;
  }
}
```

---

## 10) In-App Debugger (Logarte)

For debugging network requests and viewing logs directly on the device, use Logarte.

See the detailed integration guide: [In-App Debugger Documentation](flutter/IN_APP_DEBUGGER.md)

**Requirements:**
- Must be accessible from the Settings screen
- Must be enable/disable via `AppConfig.enableLogarte`

**Key features:**
- Network request logging (automatic with Dio interceptor)
- Navigation event logging
- Searchable log viewer
- Password protection for release builds
- Log sharing and export

---

## Dependency Injection

Use `GetIt` for service location and dependency injection. Register services at app startup and
retrieve them via `GetIt.instance`. This keeps services decoupled and testable.

---

## JSON Serialization

Use `freezed` + `json_serializable` for type-safe API models. This generates immutable data
classes with `fromJson`/`toJson` methods, `copyWith`, and equality out of the box.

---

## Widget Rebuild Optimization

Minimize unnecessary widget rebuilds to maintain smooth performance:

- Use `const` constructors wherever possible
- Extract subtrees into separate widgets to limit rebuild scope
- Avoid building large widget trees inside a single `build` method
- Use `BlocSelector` or `BlocBuilder` with `buildWhen` to rebuild only when relevant state changes

---

## Respect System Insets (SafeArea)

Screen-level content must never render underneath the system UI — the status bar,
the notch/cutout, or the bottom navigation/gesture bar. Otherwise bottom controls
(a Save button, an FAB, the last list item) sit partly behind the Android nav bar
and are hard or impossible to tap.

- **Wrap the `Scaffold` `body` in a `SafeArea`** for any screen whose content can
  reach a screen edge — especially scrollable bodies (`ListView`, `SingleChildScrollView`,
  `Column` with a bottom button). The `AppBar` already handles the top inset; the
  bottom inset is the one that bites.

  ```dart
  // Anti-pattern: bottom button scrolls under the nav bar
  body: ListView(padding: const EdgeInsets.all(16), children: [...]),

  // Correct: SafeArea insets the scroll view above the system bars
  body: SafeArea(
    child: ListView(padding: const EdgeInsets.all(16), children: [...]),
  ),
  ```

- `EdgeInsets` padding is **not** a substitute — a hardcoded padding value does not
  track the device's actual inset (varies by phone, gesture vs button nav, landscape).
- **Don't double-inset.** A `Scaffold` `appBar` already consumes the top inset; if you
  keep `SafeArea` defaults (`top: true`) under an `AppBar` it's harmless (inset is
  already zero there), but don't also add manual top padding on top of it.
- For a body behind a keyboard, `Scaffold.resizeToAvoidBottomInset` (default `true`)
  handles the keyboard; `SafeArea` handles the persistent system bars. They are
  separate concerns — keep both defaults on unless you have a reason not to.
- Full-bleed content (a background image, an edge-to-edge map) is the deliberate
  exception: opt out per-edge (`SafeArea(bottom: false, ...)`) rather than dropping
  `SafeArea` entirely, so only the intended edge bleeds.

---

## Never Let a Widget Take Infinite Height in a Scroll View

A scroll view hands its children **unbounded** constraints on the scroll axis
(`maxHeight: infinity`). Greedy widgets resolve that by taking everything they are
offered, so a widget that is correct inside a `Column` becomes an infinite-height
child inside a `ListView`.

The damage lands on a **different widget than the buggy one**: once a child reports
infinite height, the list stops laying out and *every sibling below it is never
built*. Those siblings produce no exception, no log, and no error widget — they
simply do not exist. You end up reading the missing widget's code, which is correct.

The greedy widgets, and what they do under unbounded constraints:

| Inside a scroll view | Result |
|---|---|
| `Row(crossAxisAlignment: CrossAxisAlignment.stretch)` | children sized to `maxHeight` → **infinite** |
| `height: double.infinity`, `SizedBox.expand` | infinite |
| `Expanded` / `Flexible` / `Spacer` in a vertical parent | error |
| `ListView` / `GridView` without `shrinkWrap: true` | error |

```dart
// Anti-pattern: fine in a Column, fatal in a ListView — and it silently
// deletes every sibling below it.
Row(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [Expanded(child: _Card()), Expanded(child: _Card())],
)

// Correct: IntrinsicHeight bounds the row, equal-height children preserved
IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [Expanded(child: _Card()), Expanded(child: _Card())],
  ),
)
```

Rules:

- **Only a `Row` is at risk from `stretch`.** A `Column`'s cross axis is horizontal,
  which is bounded — `CrossAxisAlignment.stretch` on a `Column` is fine.
- **Bound it explicitly**: `IntrinsicHeight`, a fixed `SizedBox(height:)`, or
  `AspectRatio`. Prefer `IntrinsicHeight` when children must match heights.
- **Run every new screen once in a debug build before shipping a release APK.**
  Debug asserts on this by name — `BoxConstraints forces an infinite height` — and
  points at the offending widget. Release strips the assert and the failure goes
  completely silent, which is what makes this class of bug expensive.
- **Widget-test the composition, not just the widget.** Pump the widget in a
  `ListView` *with a sibling after it* and assert both a finite height and that the
  sibling was built. A widget tested alone passes while the screen is broken.

  ```dart
  await tester.pumpWidget(MaterialApp(home: Scaffold(
    body: ListView(children: const [MyRow(), Text('below')]),
  )));
  expect(tester.takeException(), isNull);
  expect(tester.getSize(find.byType(MyRow)).height.isFinite, isTrue);
  expect(find.text('below'), findsOneWidget); // never built if MyRow is infinite
  ```

- **Suspect the siblings' constraints before the missing widget's own code.** A
  widget that renders nothing and logs nothing is usually a victim, not the cause.
- The default `ErrorWidget` sizes to `constraints.biggest`, so a *crash* in a list
  child produces the same infinite blank block. A custom `ErrorWidget.builder` with a
  bounded height and the exception text turns that into a visible, readable failure.

---

## Self-Describing Classes

Implement the common "Self-Describing Classes" rule using an abstract class or mixin.

```dart
abstract class Searchable {
  /// Returns a map of field name to field value for all searchable fields.
  Map<String, String> getSearchableFields();
}

class Customer implements Searchable {
  final String name;
  final String email;
  final String phone;

  const Customer({required this.name, required this.email, required this.phone});

  @override
  Map<String, String> getSearchableFields() {
    return {'name': name, 'email': email, 'phone': phone};
  }
}
```

Alternatively, use a mixin when classes already have an inheritance hierarchy
(follow the [Mixins](#mixins) rules):

```dart
mixin SearchableMixin {
  Map<String, String> getSearchableFields();
}
```

---

## Mixins, Widgets, and Injected Services (Coupling)

Reinforces core principle #1 (Composition over inheritance) and
**Inject Collaborators, Don't Fold Dependencies In** in `COMMON_RULES.md`.

- **`with SomeMixin` folds the mixin's dependencies into the widget/class.** Stacking behavior
  mixins spreads their imports across the host. Prefer a child widget or an injected service
  (get_it / Provider / Riverpod) for anything that carries dependencies; keep mixins for small,
  dependency-free behavior.
- **A god `build()` method is a coupling sink.** A widget whose `build()` wires many services and
  passes values down through several constructor layers (prop-drilling) depends on everything it
  drills through. Extract child widgets, and pass a single config object or read shared state via
  `InheritedWidget` / a provider instead of threading many parameters.

```dart
// Anti-pattern: one widget builds everything and drills props through 3 layers
// Correct: extract InvoiceHeader / InvoiceActions child widgets; inject services via provider,
//          pass an InvoiceViewConfig value object instead of a dozen constructor params
```

# Version
1

Increase this version number whenever this rule file changes.

# Design Rules (All Languages)

See `COMMON_RULES.md` for rules that apply to all languages. These rules apply to
anything with a user interface — desktop app, web frontend, mobile app, CLI TUI.

They are about **decisions**, not about a framework. The per-stack implementation
guides are:

- `python_setup_files/MODERN_GUI.md` — PySide6 desktop apps
- `project_type/FRONTEND.md` — web SPAs (Vite, Tailwind, dark mode)

Default UI toolkits ship a *safe* look, not a good one: gradient buttons, boxed tabs,
every control the same size, no hierarchy. An interface built from defaults reads as a
debug tool no matter how good the code behind it is.

---

## Tokens, Not Values

Every color, spacing step, radius, and font size is a **named token defined once**.
Call sites reference the token; nothing hardcodes `#2B2B2B` or `13px`.

- **Anti-pattern.** A hex color appears on four screens. Changing the theme means
  finding all four, and the one you miss is the one the user sees.
- **Correct pattern.** One palette/theme module (a frozen dataclass, a CSS custom
  property block, a `ThemeData`) that every screen reads.
- This is "String Constants" and DRY applied to design. The moment a value appears
  twice, it is a token.

---

## One Accent Color

Pick **one** accent and use it only for: the selected navigation item, the focus ring,
the primary action, and progress. Everything else is a neutral.

- An interface where the accent frames the window, fills the title bar, and outlines
  every button has no accent — it has a background color.
- Semantic colors (success green, error red) are separate tokens and do **not** follow
  the accent. If a status color must match another app or a spec, comment the field
  saying so, so a theme change does not silently redefine it.
- Never encode information in color alone — pair it with a glyph, a label, or a
  position (colorblind users, grayscale printing, low-quality projectors).

---

## Neutral Ramp Before Color

A dark theme needs at least: window background, an elevated surface, a control fill,
its hover and pressed states, a border, primary text, and muted text. Most of a good
interface is that ramp; color is the exception on top of it.

Body text on the background must clear **4.5:1** contrast (3:1 for large text and for
UI borders that carry meaning). Muted text is muted, not unreadable — check it, don't
eyeball it.

---

## Hierarchy Is Type and Space, Not Boxes

Three levels are usually enough: a page heading, a muted one-line explanation, and body
or control text. Give each a token (size + weight), and build them with a **shared
factory** (`heading()` / `subheading()`), never by repeating the styling on each screen.

- Separate groups with whitespace before you separate them with a border, and with a
  border before you separate them with a filled box.
- A screen that is all boxes has no hierarchy — everything is equally important, which
  means nothing is.
- Use a consistent spacing scale (4/8/12/16/24…) rather than whatever number closed the
  gap on that one screen.

---

## Size Controls by Importance

Controls should not all be the same size, and the primary action should not be the same
weight as its neighbors. A grid of six identical giant buttons is as flat as a grid of
six identical tiny ones.

- Primary action: filled, accent.
- Secondary: outlined or flat with accent text.
- Rare actions (a custom value, an advanced group): folded away behind a toggle or a
  collapsed section — present, not prominent.

---

## Every Focusable Control Has a Visible Focus State

The moment you give a control a custom background, the toolkit's own focus ring
disappears. Re-add it explicitly, in the accent, on **every** focusable control —
buttons, fields, lists, tabs.

Keyboard users, accessibility tooling, and your own automated tests all navigate by
focus. This is not decoration; a UI with an invisible focus ring is unusable without a
mouse. Tab through the entire interface once before calling a restyle done.

---

## Never Set a Minimum Size to Fix a Layout

If content is too tall or too wide, make it **scroll or wrap** — do not pin the window.
A minimum size set to fix one screen becomes a floor every other screen inherits,
including screens the user is not looking at (tab and stack containers report their
largest child's minimum as their own).

- Wrap every page/route in a scrolling container.
- Word-wrap explanatory text; an unwrapped sentence sets the width floor.
- Then pin it with a test: assert the window resizes to something tiny, and assert the
  stylesheet contains no minimum-size rule.

---

## Own the Window Chrome

On desktop, the title bar and window frame belong to the OS and default to the user's
system accent color. A carefully themed dark app with a bright green caption bar looks
broken. Set the caption and border explicitly, and make the call a **silent no-op** on
platforms and OS versions that do not support it.

---

## Icons: Vendor a Subset, Recolor in Code

- Vendor the SVGs you actually use into the repo, with the upstream `LICENSE` and a
  header naming the set and version. Never fetch icon assets at runtime, and never add
  a whole icon-font dependency for six glyphs.
- Recolor from a palette token in code rather than committing one file per color.
- Cache by `(name, color)`.
- Keep icon sizes on the same scale as the type — an icon that is not aligned to the
  text baseline or optical center reads as a mistake.

---

## Design the Empty, Loading, and Error States

Every list has a first run. Every request fails sometimes. A screen designed only for
the happy path ships a blank rectangle to every new user.

- **Empty**: say what would be here and how to get one.
- **Loading**: keep the layout stable — never let content jump when it arrives.
- **Error**: say what failed and what to do next, in the interface, not only in a log.
- **Validation**: show it where the input is, not in a dialog. If the user can see the
  field, tell them there instead of silently falling back to a default.

---

## Follow the Platform, Then Be Consistent

Match the platform's conventions for window controls, menus, shortcuts, and dialogs
before inventing your own. Inside your app, be *ruthlessly* consistent: the same action
looks the same everywhere, the same spacing separates the same kinds of things, the
same word means the same thing on every screen.

If two of your own screens disagree, the screens are wrong — not the user.

---

## Localize From the Start

Every user-visible string goes through the translation layer with a key constant, never
a raw string at a call site. Layouts must survive a translation that is 40% longer:
wrap text, avoid fixed-width labels, and never build a sentence by concatenating
fragments — translate the whole sentence with placeholders.

---

## Verify Visually, and Automate It

A restyle is not done because the tests pass — tests do not look at the screen.

- Render each screen to an image (offscreen/headless is fine and deterministic) and
  actually look at all of them after a change.
- Check the app at its smallest supported size, not just the size it opens at.
- Automate what an image cannot assert: no minimum-size rule in the theme, a focus style
  on every control, a recolored icon that still has pixels.
- Never drive a real window with synthetic mouse clicks to capture screenshots — the
  moment focus moves, those clicks land in someone else's application.

---

## Checklist

- [ ] One token module; no color, size, or radius literal at a call site
- [ ] One accent, used for selection/focus/primary only
- [ ] Body text ≥ 4.5:1 contrast; information never carried by color alone
- [ ] Heading / subheading / body built by a shared factory
- [ ] Consistent spacing scale; whitespace before borders before boxes
- [ ] Visible focus state on every focusable control, verified by tabbing through
- [ ] Nothing sets a minimum size; content scrolls and wraps instead
- [ ] Window chrome themed, with a no-op fallback
- [ ] Icons vendored with license, recolored from tokens, cached
- [ ] Empty / loading / error / validation states designed
- [ ] All strings localized via key constants; layout survives longer translations
- [ ] Every screen rendered and looked at after the change

# Version
14

Increase this version number whenever this rule file changes.

# graphify Knowledge Graph (Optional Addon)

graphify turns a code folder into a queryable knowledge graph — god nodes, communities,
cross-file relationships, fan-in/fan-out. Use it to orient before grep and to spot god classes.

**Keep the build AST-only (no LLM, no API cost) by scoping to the code dir.** graphify runs a
free deterministic AST pass on *code* files, but a separate **LLM pass** on every *non-code*
file — docs, `.md`, `.txt`, config `.yaml`, images (vision), audio/video (whisper). That pass
needs an LLM (Gemini key or the host agent) and costs tokens. A build scoped to a pure-code dir
(`lib/`, `src/`, `app/`) has zero non-code files, so it skips the LLM pass entirely and rebuilds
need no AI. A repo-root build (`/graphify .`) sweeps in `docs/`, `README.md`, icons, and sound
assets — forcing the LLM pass. **Always scope to the code dir; never build the repo root.**

---

Setup instructions live in the coding-rules plugin at `graphify_setup_files/SETUP.md`.

## Folder layout (know which is which)

- `graphify-out/` at the **project root** = the **live graph** (`graph.json`, `GRAPH_REPORT.md`,
  `graph.html`). The only one queries read. Keep it `directed=True`.
- `graphify-out/cache/` at the project root = AST cache written by the CLI refresh (it runs
  with `GRAPHIFY_OUT` pointing at the root folder, see "Refreshing"). Scratch only.
- `<code-dir>/graphify-out/` = legacy AST cache from the skill build. Never the live graph
  under the documented flow; safe to delete. If a `graph.json` ever appears in there, a bare
  `graphify update` ran without `GRAPHIFY_OUT` — delete that `graph.json`, keep `cache/`.

## What the graph knows (and does not)

- Knows: code structure — classes, methods, calls, references, extends/implements, plus
  fan-in/fan-out and community / god-node structure.
- Does NOT know: business rules, API response shape, or rendered template/view output. It is a
  snapshot — stale until rebuilt. Constants referenced by string can appear as isolated nodes
  (AST limitation, not a missing dependency).

---

## Using the graph

- For codebase questions, run `graphify query "<question>"` first when `graphify-out/graph.json`
  exists. `graphify path "<A>" "<B>"` for relationships; `graphify explain "<concept>"` for a
  focused node. These return a small scoped subgraph vs. reading GRAPH_REPORT.md or raw grep.
- Judge coupling by direction: high **fan-in** + low fan-out (shared base / constants / DTO) is
  healthy; high **fan-out** (>~20 outgoing deps) is god-class risk and a refactor signal.
- Read `graphify-out/GRAPH_REPORT.md` only for broad architecture review, or when
  query/path/explain do not surface enough context.

## Manual refresh bat (`tools/graphify_update.bat`)

Copied from the `graphify_update.bat` template beside this addon, adjusted (`CODE_DIR`).
Run it from anywhere — it `pushd`es to the repo root itself.

- **Does:** (1) the live-graph CLI refresh from "Refreshing after a code change" in
  `IMPLEMENTATION_FLOW.md` (sets `GRAPHIFY_OUT` to the root
  `graphify-out\`, passes the absolute code dir); (2) smoke test — prints the root
  graph's `directed` flag + node count, `god-nodes`, a sample `query`.
- **Does NOT:** re-extract docs (see "Doc changes" in `IMPLEMENTATION_FLOW.md`) or build a first graph — that is the
  skill flow (`/graphify <code-dir> --directed`).
- **When to use:** after a code change outside an AI session, or as a "is graphify still
  wired up?" check after cloning, a dependency change, or a graphify upgrade.

## In-tree vendored code — exclude it, scoping alone won't

`--directed`-scoping the build to `<code-dir>` keeps external `vendor/`/`node_modules/` out
automatically, but a **committed** third-party library living *inside* `<code-dir>` (a bundled
SDK, a copied library folder) is not gitignored, so graphify scans it like first-party code.
Symptom: god-nodes / oversized communities in `GRAPH_REPORT.md` whose class names belong to a
library, not the app (e.g. hundreds of `Facebook*`/`GraphNode*` nodes from an in-tree Facebook
SDK).

Fix once per project:

1. Spot the vendored folder(s) under `<code-dir>` (e.g. `application/libs/`). Committed
   **asset/sprite dirs** are the same kind of noise — bundled UI images (jQuery-UI/colorbox
   sprites, e.g. `extensions/backend/assets/images/`) aren't code but graphify still scans them;
   exclude them the same way.
2. Drop a `.graphifyignore` at the scan root (gitignore syntax, honored by default):
   ```
   # Vendored / third-party code + bundled assets — not our architecture, noise in the graph
   libs/
   ```
3. Rebuild with the CLI refresh plus `--force` — a narrower corpus is a *smaller* graph,
   which trips the shrink guard (#479):
   `GRAPHIFY_OUT="$PWD/graphify-out" graphify update --force "$PWD/<code-dir>"`.
   Do NOT delete `graphify-out/graph.json` first (see "Refreshing after a code change" in
   `IMPLEMENTATION_FLOW.md`: the CLI would rebuild
   it undirected and drop the doc nodes).
4. Verify: grep the vendored library's distinctive class name in the new `graph.json` — it
   should return only first-party code that *uses* the library (e.g. your own `FacebookManager`),
   never the library's own classes.
