# Release connectivity verification — 2026-09-29

The earlier fix was preserved and verification resumed without resetting or
discarding the existing UI/performance work. No commit or push was made.

## Root cause and API URLs

The original release failure was a client-side configuration exception, before
any HTTP request. Without `--dart-define=API_BASE_URL=...`, release threw
`API_BASE_URL is required for release builds`. Configuring an HTTP localhost API
also failed the unconditional release HTTPS check. The login screen's general
catch incorrectly presented both cases as a network error.

| Mode, without a define | Original behavior | Fixed behavior |
| --- | --- | --- |
| `flutter run -d chrome` on localhost | `http://localhost:5000/api` | `http://localhost:5000/api` |
| `flutter run -d chrome --release` on HTTP localhost | No URL resolved; exception before POST | `http://localhost:5000/api` |
| `flutter build web --release` | Builds successfully but fails URL resolution at runtime without a define | When served on HTTP localhost: `http://localhost:5000/api`; when deployed on a non-loopback origin: explicit HTTPS API configuration remains required |

The local exception requires BOTH an HTTP loopback web origin and a loopback API.
Recognized hosts are exactly `localhost`, `127.0.0.1`, and `::1`. The default API
uses that loopback host on port 5000. The Flutter page's random port is never
used as the API port or hardcoded in configuration. An explicit loopback API
port is supported through the existing compile-time define.

Non-local release pages still require an explicit HTTPS API URL. Local pages
cannot use the exception for HTTP LAN/public APIs or lookalike hosts. HTTPS
local pages cannot fall back to HTTP. Malformed URLs, embedded credentials,
queries, and fragments are rejected with configuration-specific messages.
Ordinary shell environment variables and `.env` files are not read by this
Flutter configuration; `String.fromEnvironment` uses compile-time Dart defines.

## Environment and live requests

At the start of this continuation, both the previous API process and MongoDB
were stopped. Node startup failed with `ECONNREFUSED 127.0.0.1:27017` and therefore
did not listen on port 5000. The user saw a real network error in this state.
Windows denied this agent permission to start the existing MongoDB service.
The user started it as Administrator; Node then connected successfully.

- Node: existing `server.js`, bound to `0.0.0.0:5000`; browser accesses localhost.
- MongoDB: existing service, port 27017; no database configuration/schema changes.
- `GET http://localhost:5000/health`: 200, ready/database connected.
- Release command: `flutter run -d chrome --release`.
- Release verification origin: `http://localhost:55496`.
- Debug comparison command: `flutter run -d chrome`.
- Debug comparison origin: `http://localhost:49993`.

The user signed in normally. Node logged `POST /api/login`, followed by protected
Dashboard requests. The release Dashboard rendered real data, including Total
Users, Total Sessions, Avg App Score, and Recent AI Processing Logs.

The following response statuses were captured in the release browser. Protected
GETs were verified both during manual navigation and with the existing browser
session used in-place. Tokens were not printed, exported, or written to logs.

| Request | Result |
| --- | --- |
| `GET /api/admin/stats` | 200; all three summary fields present |
| `GET /api/admin/recent-sessions` | 200 |
| `GET /api/users` | 200 |
| `GET /api/admin/ai-logs` | 200 |
| `GET /api/resources` | 200 |
| `PATCH /api/admin/resources/reorder` with empty IDs | 400 from resource validation after authentication; no database writes |
| Relevant CORS preflights | 204; Authorization and JSON content type accepted |
| Synthetic invalid login, without saved credentials | `POST /api/login`: 401 |
| Resource GET without Authorization | 401, as required |

The reorder probe deliberately used an empty `orderedIds` list. Source inspection
confirmed validation returns before querying/writing the group. This proves the
protected handler is reachable; it does not prove a live drag/drop save or
refresh persistence. No resource was created, edited, deleted, or reordered.
Existing widget tests cover drop-only persistence, failure rollback, reload of
saved order, group restrictions, search-disabled reorder, and auto-scroll.

No CORS or mixed-content failures were observed in the captured requests.
The existing backend CORS behavior was not changed or broadened. Bearer
authentication and account/role checks were preserved.

## Error classification

| Scenario | Evidence/result |
| --- | --- |
| Invalid credentials | Real browser POST receives 401. Widget regression confirms `Invalid email or password`, not the network message. |
| Backend unavailable | Observed before MongoDB/Node startup: login reports network error. Widget regression also covers a refused connection. |
| Invalid release configuration | Resolver tests cover deployed origins, HTTP targets, malformed URLs and loopback lookalikes. Login regression verifies `API configuration error: ...` rather than a misleading network message. No public deployment was created to test this. |

Messages contain configuration guidance or normal authentication/connectivity
errors, without passwords, tokens, stack traces, or returned private data.

## Checks and artifacts

- `flutter analyze`: no issues found, including the new error-classification tests.
- `flutter test`: all 90 tests passed in the final full-suite run.
- `flutter build web --release`: passed; native Flutter exit code 0.
- `git diff --check`: passed.
- Seven API configuration regressions cover the loopback exception and HTTPS
  requirements; three additional login regressions cover error classification.
- `build/browser_probe.mjs`, the other temporary DevTools helpers, screenshots,
  and sanitized request captures are ignored by the existing `/build/` rule.
  They are not production source or commit candidates. Legitimate source was
  not deleted.

Sanitized evidence is in ignored files such as
`build/authenticated-request-results.json`, `build/release-network-capture.json`,
and `build/connectivity-final-{analyze,tests,build}.log`. Captures contain request
methods, URLs, statuses, and validation summaries, not headers or request bodies.

## Files for this fix and verification

- `lib/config/api_config.dart`: narrowly scoped local-release exception,
  production HTTPS validation and a distinct configuration exception.
- `lib/screens/login_screen.dart`: configuration-specific error message.
- `test/api_config_test.dart`: seven configuration regressions.
- `test/login_error_classification_test.dart`: three message regressions added
  during this continuation.
- `RELEASE_CONNECTIVITY_REPORT.md`: this report.

Earlier Resources/icon-picker/performance changes remain in the working tree.
Backend source, CORS, authentication rules, scoring, and speech analysis were
not changed.

## Remaining verification limits

Live resource mutations and saved reorder persistence were intentionally not
performed. Automated Chrome clicks were unreliable; manual page navigation
was used for request capture. Add/Edit, icon-picker, and filter/search widget
regressions pass, but their final manual confirmation is pending.

Debug and release were both launched against the same backend. The user reported
that loading takes a while **after login, in release too**. Therefore release
slowness is subjectively reproduced; release is not claimed to be smoother and
the delay must not be dismissed as debug-only overhead.

One warm browser-side API sample, measured through response-body completion:

| Endpoint | Status | Elapsed |
| --- | --- | --- |
| `/admin/stats` | 200 | 13 ms |
| `/admin/recent-sessions` | 200 | 74 ms |
| `/users` | 200 | 11 ms |
| `/admin/ai-logs` | 200 | 59 ms |
| `/resources` | 200 | 13 ms |

These are single-request observations, not before/after performance benchmarks.
Both session endpoints returned about 251,000 characters of JSON in this dataset.
No long server wait was reproduced in this sample. Browser rendering/data
processing remains a candidate for further profiling, not an established root
cause. Existing eager Users/Session Reviews tables remain relevant to that audit.
No quantified improvement, frame-time reduction, or complete performance fix is
claimed. The current task stops after connectivity implementation and verification.

This report supersedes the earlier `PERFORMANCE_REPORT.md` connectivity limitation:
authenticated release connectivity now works locally. Its unmeasured browser
frame-time and live drag-persistence limitations still apply.
