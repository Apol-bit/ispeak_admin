Post-login performance profile — 29 September 2026

The confirmed UI bottleneck is the Dashboard's eager 100-row, seven-column DataTable. Its default intrinsic column sizing measures cell contents before normal layout. In the live baseline, logs JSON decoding took 1.9 ms, row-widget construction took 4.4 ms, table layout took 422.6 ms, and the complete logs-response-to-content-frame gap was 781.1 ms. Table layout is a substantial part of the delay; the rest includes Flutter subtree construction, painting, and frame scheduling, which were not individually isolated.

The applied fix supplies explicit column widths, expands them proportionally to fill wider viewports, scales them for enlarged text, and retains horizontal scrolling on narrow screens. Header labels can wrap where needed. Every returned log, its hover state, and its session-detail action remain available. No backend, API, authentication, CORS, pagination, or resource behavior was changed in this task.

**Live baseline.** `flutter run -d chrome --release --dart-define=ADMIN_PERF=true`, visible Chrome at 1920 × 991, real authenticated account, 100 recent logs. Times below are relative to login submit, rounded to 0.1 ms. Frame markers indicate completion of Flutter build/layout/paint, not physical display presentation.

| Stage | Time after submit |
|---|---:|
| A: Login submit | 0.0 ms |
| B: Login response received | 264.8 ms |
| Login JSON decode | 0.2 ms duration |
| C: Auth persistence complete | 267.4 ms |
| Auth persistence alone | 1.0 ms duration |
| D: Navigation starts | 268.6 ms |
| Dashboard init | 323.5 ms |
| F: Stats start / response | 324.7 / 795.6 ms |
| G: Logs start / response | 326.2 / 798.9 ms |
| E: Dashboard shell frame | 392.4 ms |
| Logs JSON decoding | 1.9 ms duration |
| H: First stats/content frame | 1,579.6 ms |
| Logs content frame | 1,580.0 ms |
| I: Logs table frame | 1,580.1 ms |
| J: Fully interactive | Not independently timestamped; later navigation and row interaction succeeded |

The Dart request intervals were 470.9 ms for stats and 472.7 ms for logs. Chrome request-to-response-header intervals were approximately 293.8 and 294.3 ms respectively, including preflight/scheduling effects. These are browser observations, not isolated Node execution time. They were longer than the earlier connectivity task's 11–74 ms samples. JSON parsing and persistence are small; the measured rendering gap remains substantial after the response has arrived.

**Live before/after.** The after measurements used the existing authenticated session with the updated release bundle. A separate fresh-login window was provided, but no second fresh login was captured. Consequently, login-submit-to-shell/content speedup is not claimed.

| Measurement | Before | After |
|---|---:|---:|
| Login → shell frame | 392.4 ms | Fresh-login sample unavailable |
| Login → content frame | 1,580.0 ms | Fresh-login sample unavailable |
| Initial live table layout | 422.6 ms | 294.0 ms on session restoration; different entry path |
| Warm Dashboard table layout | 217.6–266.3 ms | 98.9–113.1 ms in final two navigation samples |
| Logs response → content frame on revisit | 413.6–614.0 ms | 336.0–369.9 ms in final two samples |
| K: Dashboard → Resources content | 188.8–251.0 ms | 162.0–244.1 ms in final two samples |
| L: Resources → Dashboard content | 551.4–831.7 ms | 490.1–507.4 ms in final two samples |
| Dashboard fully interactive | No exact timestamp | No exact timestamp; page and row interactions verified |

Additional warm after-change visits had 73–90 ms table layouts. One recorded navigation took 2,695 ms, with 2,311 ms between the navigation callback and Dashboard initialization. Browser focus/visibility changed during this shared interactive run; that outlier is retained in the raw trace and is not treated as table-render time. The restored session's initial load also encountered a hidden tab, so it is not a valid fresh-login comparison. Browser automation enabled accessibility for later functional checks, which can add work. These are practical local samples, not a noise-free performance guarantee.

**Controlled release comparison.** An ignored standalone harness exercised the actual MainLayout and Dashboard with synthetic sessions, a 20 ms mock response delay, isolated Chrome profiles, and a 1440 × 1000 viewport. It did not contact the backend or use real credentials. It compared the unchanged table with a temporary explicit-width variant before retaining the optimization. First entry and 0/1/10/100-row revisits were recorded. Each warm 100-row median below uses five entries.

| Controlled measurement | Intrinsic widths | Explicit widths |
|---|---:|---:|
| Run 1: first 100-row layout | 458.3 ms | 264.5 ms |
| Run 1: warm layout median | 263.1 ms | 166.5 ms |
| Run 1: response → content median | 522.7 ms | 489.3 ms |
| Run 2: first 100-row layout | 308.2 ms | 175.3 ms |
| Run 2: warm layout median | 164.4 ms | 78.7 ms |
| Run 2: response → content median | 329.9 ms | 233.5 ms |
| Run 2: Dashboard revisit median | 391.8 ms | 281.3 ms |
| Run 2: one-row layout | 4.8 ms | 3.7 ms |
| Run 2: ten-row layout | 22.7 ms | 10.0 ms |

The 0-row run had no table. This demonstrates both row-count dependence and a material intrinsic-sizing cost. Cold entry is slower, but the problem also occurs on revisits. Layout medians improved by approximately 37% and 52% in the two controlled runs; total content-render gains were smaller and varied. Mock request timers include event-loop scheduling delays, so their observed duration is not network latency. No permanent row cap or pagination was introduced. Lazy rendering was not implemented as part of this smaller verified fix.

**Request counts and other suspects.** Fresh login produced one POST `/api/login`, one GET `/api/admin/stats`, and one GET `/api/admin/recent-sessions`, all HTTP 200. The corresponding OPTIONS requests returned 204 and are preflights, not duplicate data loads. There was no `/auth/me` call on fresh login and no Users, Session Reviews, or Resources fetch until navigation. Each Dashboard remount fetched its two endpoints once. Session restoration correctly performs `/auth/me`; that is a separate flow. Tests also verify that changing theme does not issue another data request.

Only the selected page is mounted. Stats and logs fetch independently. Skeletons have no minimum duration or shimmer delay. However, when both responses arrive close together, the expensive logs table can occupy the frame that also displays the summary cards. Separate loading flags do not remove that shared main-thread cost.

All rows are constructed eagerly. Dates, score strings, and status labels are recalculated during row construction, but this took only about 1–4 ms on warm entries, so display-string caching was not added. The row-widget timer does not measure all subsequent Flutter element construction. Dashboard state updates rebuild both its summary section and table; the standard row hover implementation does not call Dashboard setState. Hover overhead was not independently isolated, and hover behavior was preserved.

Inter font downloads took 36–49 ms in the baseline startup, and the fallback Roboto font took 180 ms. CanvasKit Wasm took 360 ms. These completed during application startup, before the measured login; there were no new font downloads at Dashboard entry in that trace. No branding or assets were removed. A GPU raster trace was not collected.

**Files and diagnostic cleanup.** The lasting changes from this profiling task are:

- `lib/screens/dashboard_screen.dart`: explicit responsive table column widths and flexible header labels.
- `test/admin_ui_test.dart`: 100-row fixture and light/dark enlarged-text tests that scroll to the last row and verify its exact session details and request counts.
- `POST_LOGIN_PERFORMANCE_REPORT.md`: this report.

All previous working-tree changes and existing reports/tests were preserved. Temporary instrumentation was removed from Dashboard, Login, MainLayout, and Resources. `lib/diagnostics/admin_performance.dart` was archived and removed from production source. There are no remaining `AdminPerformance`, `ADMIN_PERF`, or `ADMIN_TABLE_FIXED` references in `lib/` or `test/`.

The instrumented source snapshots and fixture are retained as `.dart.txt` files under `build/post-login-diagnostics/`. Browser helpers, including `build/profile_browser.mjs`, and timing JSON remain under ignored `build/`; `git check-ignore` confirmed this. They are excluded from commit candidates. No legitimate test or report files were removed.

**Verification.** Final `flutter analyze`: no issues. Final `flutter test`: 92 passed. Final `flutter build web --release`: exit 0, built successfully in 79.0 seconds, with profiling hooks removed. `git diff --check` reported no whitespace errors. Logs are under `build/post-login-final-{analyze,tests,build}.log`.

The baseline fresh release login succeeded. The updated release bundle restored the authenticated session, loaded Dashboard, and returned HTTP 200 for Users, Session Reviews, and Resources. Clicking a Dashboard row opened the matching session details; its ID was checked without putting it in this report. Dark mode and the dialog were visually inspected. Widget tests cover row hover/click behavior, skeleton states, page navigation, narrow layouts, enlarged text, and existing resource CRUD/reorder interactions. No real resource data was changed for this profiling task. No overflow remained in the passing tests. An initial fallback-font header overflow was fixed by allowing header labels to wrap.

Raw measurements: `build/post-login-live-baseline.json` (network plus timing events), `build/post-login-live-baseline-complete.json`, `build/post-login-final-after.json`, and `build/fixture-{baseline,fixed,baseline-repeat,fixed-repeat}.json`. Browser UI checks and screenshots are ignored local artifacts. Some text-label accessibility probes returned false despite visible labels; the dialog screenshot and ID match, rather than those label probes alone, establish the session-detail result.

Remaining limitations: fresh-login after timings and an exact fully-interactive timestamp are unavailable; the DataTable still eagerly constructs 100 rows; larger datasets would need a separately measured lazy-rendering change. The measured fix reduces layout cost but does not eliminate all post-login loading time. No commit or push was performed.
