# Admin performance and interaction report

Implementation and verification: 2026-09-28, Flutter 3.41.2 / Dart 3.11.0, Windows.
The working tree was clean before editing. No commit or push was made. Changes
are limited to Admin UI, tests, and this report. Authentication, speech analysis,
scoring, resource access, MongoDB schema, and the legacy Python backend were not
changed.

## Performance classification

**Debug-only versus release lag remains unclassified.** No authenticated,
before/after browser frame trace was obtained. The release web build succeeds,
but compilation does not prove runtime smoothness. Normal Flutter Web debug
overhead has not been classified as a production defect.

An actual Chrome test run was attempted with:

```text
flutter test --platform chrome test/resource_performance_test.dart --reporter expanded
```

Chrome launched, but the Flutter test host returned 404 for
`/canvaskit/chromium/canvaskit.js` and `canvaskit.wasm`. This was confirmed through
Chrome's local debugging log; the SDK files exist. The installed Windows test
host converts the URL to a platform path, then checks for the literal forward
slash prefix `canvaskit/`. The run remained at suite loading and was stopped.
The SDK was not modified. Browser tests, manual browser checks, and real backend
refresh/persistence verification are **not claimed as passing**.

## Findings and changes

| Area | Before | After / evidence |
| --- | --- | --- |
| Resources rendering | Every card was constructed eagerly; each group used a shrink-wrapped, non-scrollable reorder list inside another list. | One `CustomScrollView`, lazy `SliverReorderableList` per group, and lazy `SliverList` during search/save. A fixture with 203 total resources mounts fewer than 20 cards initially at both 1024 and 600 px, in both themes. This is widget-count evidence, not a frame-time benchmark. |
| Resource transformations | Data maps copied and search, type/level scans, sorting, and ordering maps rebuilt during screen builds. | View collections cached by response identity, normalized search, and type. Optimistic reorder updates the affected group. A fresh GET or rollback invalidates derived state; rollback respects filters changed during an in-flight save. |
| Drag updates | Nested scrollables prevented the reorder list from driving the real viewport. | Built-in sliver reorder updates and scrolling share the real viewport. Pointer movement does not call screen `setState` or the backend. Visible cards retain ID keys. |
| Persistence | Drop-only PATCH already existed, including rollback. No-op moves could still send a request. | Exactly one PATCH for a changed drop; none during scrolling, cancellation, or a no-op. In-flight same-group requests are guarded. Existing payload and `displayOrder` compatibility retained. |
| Icon categories | A horizontal viewport existed, but default desktop behavior excluded mouse dragging and supplied no visible scrollbar. | Explicit controller, mouse/touch/trackpad drag support and an interactive visible horizontal scrollbar. Tests mouse-drag to General, verify its entire chip lies within the viewport, select General and Communication, and check search and actions. Horizontal pointer-wheel events also tested. |
| Icon filtering | Static registry and lazy grid already present; filtering reran on every dialog build, including icon selection. | Filtering recomputes only for search/category changes. Static registry, fallback handling, preview, explicit Select/Cancel and blue `#3D6BFF` selection remain. No tiles exist while the dialog is closed. |
| Skeletons | Static neutral placeholders, no animation controllers or shimmer timers. | Preserved. No per-frame page rebuild or offscreen shimmer activity found. Skeletons are removed when loaded/error content replaces them. |
| Sidebar | `AdminNavItem` uses local Material/InkWell hover effects; expansion uses bounded animation. | Preserved; no screen-wide hover `setState` found. Existing expansion overflow regression tests pass. |
| Dark Mode | Theme provider notifies only when its boolean changes; color getters are constant-time. | No rebuild loop or per-frame theme computation found. Both themes covered; switching theme adds no API calls. |
| Dashboard, Users, Session Reviews | Requests originate in initialization or explicit refresh/actions, not `build()`. Tables eagerly create their rows. | No duplicate request found in the navigation fixture. Tables remain unchanged; very large Users/Session Reviews datasets are still a potential scaling limitation, not a measured production regression. |

Cache hits skip data transformations, but this change does not claim that no
visible card ever rebuilds: filter/theme changes and persistence state can still
rebuild visible content. No blanket repaint boundaries, artificial search delay,
response cache, or additional animation controllers were introduced.

## Auto-scroll behavior

- Uses **Flutter's built-in** `SliverReorderableList` auto-scroll; no competing
  custom scrolling timer. The owned scroll controller is disposed with the page.
- Edge threshold is the **drag preview crossing the viewport edge**, as defined
  by Flutter, rather than a fixed 60–100 px pointer band. Effective pointer
  distance depends on card height and where its dedicated handle was grabbed.
  The installed API does not expose a pointer-zone threshold. Check the feel of
  unusually tall cards manually.
- Velocity scalar is **20**, down from Flutter's default 50. Flutter increases
  speed with preview overshoot, capped at 20 logical pixels per 50 ms segment
  (approximately 400 logical pixels/second). It uses short linear `animateTo`
  segments, not repeated large jumps.
- Moving the preview into the viewport ends the built-in loop; the current
  segment can finish within about 50 ms. Bounds stop further scrolling.
- Drop and pointer cancellation explicitly stop the current scroll activity and
  cancel the active reorder state. A changed drop is committed once from the
  captured final index. This avoids Flutter's default 250 ms drop animation
  continuing to edge-scroll. Tests check the scroll offset is unchanged on the
  first frame after drop/cancel, and remains unchanged afterwards.
- Cancellation and disposal remove the drag overlay/animation without saving;
  tests verify no remaining transient callbacks after disposal while dragging.
- Scripts/Challenges remain independent type + difficulty slivers. Guided Tasks
  remain one All Levels sliver, regardless of stored difficulty. A drag cannot
  transfer an item between these groups. It may scroll past another group, but
  its drop indices and persistence payload belong exclusively to its source.
- Search removes reorder handles and reorder slivers. Type filters retain whole
  groups. Edit/Delete actions remain separate from the grab handle; the preview
  has a grabbing cursor and a small elevation.

## Before/after workflow observations

These are source inspection and widget-test observations; **no measured browser
latency, FPS, build/raster duration, or percentage speedup is available**.

| Workflow | Observation |
| --- | --- |
| Initial Dashboard load | Loading/error/data regressions pass; one stats and one recent-sessions request. Latency not measured. |
| Dashboard → Resources / opening Resources | One resources GET; eager nested cards replaced by lazy rendering. Navigation latency not measured. |
| Resource filtering / typing search | Local-only, derived data recalculated on input changes; no extra GET. Search disables reordering. |
| Opening icon picker | Lazy grid and static registry retained; opening latency not measured. |
| Icon search | Search still works after category scrolling; no selection-triggered refiltering. |
| Category scrolling / final category | Previously hard to reach with mouse; now mouse drag and horizontal wheel reach General with full chip bounds visible. |
| Dragging / auto-scrolling | Scrolls down and up across a 200-item group; middle stops scrolling; zero PATCHes while moving. |
| Drop / persistence | One PATCH, correct group and unique full ID list; saved order reload and failure rollback covered by existing fixture tests. |
| Add/Edit Resource | Existing responsive form and submission tests pass, including icon picker and Guided Task behavior. No timing measurement. |
| Light/Dark switch | Both themes pass; no extra request from theme switching. No frame-time measurement. |
| Session Reviews / Users | Existing data, error, skeleton and action tests pass. No large-table browser benchmark. |

## Verification

- `flutter analyze`: **no issues found**.
- `flutter test --reporter expanded`: **80 tests passed**.
- `flutter build web --release`: **passed**; output in `build/web`.
- `git diff --check`: **passed**.
- Chrome-specific test attempt: **blocked by test-host CanvasKit 404s**, as above.
- Category matrix: 1366, 1024, 768, 600, 390 and 320 logical pixels, 650 px high,
  both Light/Dark. All categories exist, mouse drag/horizontal wheel reach the
  final category, selection uses blue, search and Select/Cancel work, no layout
  exception. Native trackpad/shift-wheel and keyboard traversal still need a
  manual browser check.
- Drag matrix: 1024 and 600 px, both themes, 200-item group plus other groups.
  Down/up, middle stop, immediate drop/cancel stop, single persistence request,
  group payload, search-disabled reorder, and lazy card count pass. Additional
  Guided Task test covers top/bottom bounds and disposal during active scrolling.
- Existing suite covers Dashboard interactions, Users, Session Reviews,
  skeleton loading, sidebar expansion, filters, Add/Edit dialogs, icon fallback,
  saved ordering reload, and failed reorder rollback.

Logs are in the ignored build directory: `full-test-results.log`,
`analyze-results.log`, `release-build-results.log`, and
`chrome-performance-tests.log`.

The release build command verifies compilation only. The existing application
requires a real HTTPS `API_BASE_URL` for release operation; the task did not
provide a deployment endpoint or authenticated browser session. For the manual
comparison, run debug and release with the **same** authorized HTTPS endpoint
using `--dart-define=API_BASE_URL=...`, the same data and viewport. Record frame
timings after warm-up while following the requested browser interaction checks.
No credentials or auth bypass were added to obtain measurements.

## Files changed

- `lib/screens/resources_screen.dart`: cached view data, lazy grouped slivers,
  shared scrolling, drop/cancel lifecycle and no-op/in-flight reorder guards.
- `lib/widgets/resource_icon_picker.dart`: desktop category scrolling and cached
  filtered icon options.
- `test/resource_management_test.dart`: rollback drag targets rendered card
  dimensions rather than a fixed distance that no longer crossed the destination.
- `test/resource_performance_test.dart`: category width/theme matrix, long-list
  rendering and drag checks, lifecycle/bounds checks, navigation request counts.
- `PERFORMANCE_REPORT.md`: findings, verification and remaining limitations.

Manual inspection remains: authenticated debug/release comparison, native
mouse/trackpad feel (including tall-card edge activation), actual backend reload
after a drop, and a full browser pass in both themes. Automated widget evidence
does not establish production performance or replace those checks.
