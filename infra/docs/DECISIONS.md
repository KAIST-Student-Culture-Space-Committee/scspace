# Project Decisions

Updated: 2026-08-24

## Workflow

- Work is performed on the `resolve-all` branch in the root repository and all submodules.
- Do not push, commit, stage, open pull requests, add CI, or run remote tests without explicit approval.
- All changes are reviewed by the development director before integration.

## Deployment

- Production runs with Docker Compose. PM2 is not a production deployment path.
- GHCR and registry-based deployment are deferred until the test server is ready.
- Production MySQL runs in Docker Compose on `scspace.kws.sparcs.net`.
- Development and test databases must be isolated from production.
- Deployment checks the host clock before and after updating the source.
- The deployment host must report NTP synchronization through `timedatectl` and normal chrony synchronization.
- Deployment stops when the absolute chrony offset exceeds `MAX_CLOCK_OFFSET_SECONDS`, which defaults to one second.

## Time

- Business dates and schedules use `Asia/Seoul` explicitly. Host timezone is not a source of truth.
- Server and client use `@js-temporal/polyfill` while the supported Node runtime lacks a native Temporal implementation.
- The current custom bigint calendar encoding is legacy and must be migrated without an immediate destructive cutover.
- The target model stores concrete instants as UTC `DATETIME(3)` values and transfers them as ISO 8601 strings with `Z`.
- The target model uses `DATE` for calendar-only values and separate weekday/time fields with an explicit business timezone for recurring wall-clock rules.
- Calendar-only `DATE` values are stored without timezone conversion.
- Local date-time input is interpreted in `Asia/Seoul` and converted once to UTC. Output is converted once from UTC to `Asia/Seoul` for display.
- Do not implement timezone conversion with hard-coded `+9` or `-9` arithmetic.
- Queries for a Korean calendar day use the corresponding half-open UTC range.
- After legacy data migration, MySQL server, session, and client connections will use UTC. Redis will keep relative TTLs.
- The target model uses the database as the authority for critical deadline checks. Cron jobs will be timezone-explicit, idempotent, and able to recover missed executions.
- Current lottery and backup cron schedules declare `Asia/Seoul` explicitly; idempotency and missed-run recovery remain pending.
- Migration order is add columns, dual-write, backfill, verify, switch reads, and remove legacy columns only after approval.

## Authentication Sessions

- OAuth state and privacy-consent tokens currently expire after 10 minutes.
- Access tokens currently expire after 30 minutes. Refresh tokens currently expire after 14 days.
- OAuth state and privacy-consent tokens are consumed atomically in Redis.
- Planned corrections include verified SSO ID tokens, refresh-token rotation, and environment-specific key namespaces.
- SSO ID token signature verification is deferred until Pass-Ni issuer/JWKS configuration is available on the development server.

## Reservation Policy

- A business week is `[Monday 00:00, next Monday 00:00)` in `Asia/Seoul`.
- Normal reservations have no organization-only spaces; both individual and organization reservations are supported.
- Normal organization reservations are allowed for `REGISTERED`, `VERIFY_REQUEST`, and `VERIFIED` organizations.
- Any organization member may manage normal organization reservations. Lottery applications are restricted to the organization's delegator.
- Normal reservations for Mirae Hall and Sumi Jo Hall require manager approval instead of immediate grant.
- Approval uses `WAIT -> GRANT | REJECTED`; `RECEIVED` is retired.
- `WAIT` and `GRANT` reservations block conflicting time slots and count toward daily and weekly quotas. `REJECTED` reservations do neither.
- Approval revalidates conflicts and quotas before changing `WAIT` to `GRANT`.
- Reservations created by a manager and reservations applied from lottery results are granted immediately.
- A non-manager update to a granted Mirae Hall or Sumi Jo Hall reservation returns it to `WAIT` for approval.
- Seminar Room 1 and 2 share a combined daily limit of 3 hours and a combined weekly limit of 6 hours.

## Access Policy

- Article creation, update, state change, file change, and deletion are manager-only.
- Anonymous article reads expose `FOR_ALL`; authenticated KAIST users may read `FOR_KAIST` and `FOR_ALL`; managers may also read `HIDE`.
- Article visibility keeps `HIDE`, `FOR_KAIST`, and `FOR_ALL`.
- Reservation calendar and occupancy views require authentication; there is no anonymous public calendar.
- Physical rental handover and return confirmation are performed by a manager during committee duty hours.
- Committee duty hours are Monday through Wednesday 19:00–21:00 and Thursday 21:00–23:00 in `Asia/Seoul`.
- Users do not create rentals directly. A manager registers the rental during the on-site handover after selecting the borrower by student number.
- Managers can create, view, and edit all rental records. A user can view their own rental records.
- The lending manager is recorded as `approverId`; the return-confirming manager is recorded as `returnApproverId`.
- Rental records include borrower, organization, contact and emergency contact, purpose and location, deadline, goods, quantity, and operational status.
- Organization is stored as the existing free-text `groupName`, the manager selects the deadline, and the return checklist is a required UI confirmation rather than a persisted audit record.
- Overdue and overdue-contacted labels are derived from the active rental deadline and recorded contact time. Cancellation is a soft status transition.
- Inventory changes are manager-only.
- Lottery applications are created and deleted by the verified organization's delegator.
- Generic authenticated users cannot choose arbitrary recipients or templates through a mail API.
- Manager/Admin users may view current and historical PINs. PasspinMaster users may create and delete PINs.
- A `GRANT` reservation exposes its PIN from one hour before its start until one hour after its end. Organization reservations expose it to all current organization members.

## Seminar Lottery Policy

- Only verified organizations participate.
- Applications have first, second, and third preferences.
- Seminar Room 1 and 2 share those three preferences, and an organization can win at most one recurring slot across both rooms.
- When an organization wins, its other preference applications are removed.
- Draw priority is first preference without a room, first preference with a room, second preference without a room, second preference with a room, third preference without a room, then third preference with a room.
- Recurring reservations cover weeks 1 through 16 except weeks 7, 8, 15, and 16.
- Academic week 1 is the Monday-based week containing the configured `timeStart`.
- Applications are accepted from the configured opening date through the configured closing date, with one draw per day.
- Winners are retained and losing applications for the drawn slot are removed.

## Lottery Lifecycle

- The application interval is `[opening date 00:00, day after closing date 00:00)` in `Asia/Seoul`.
- The daily 18:00 draw remains available during the application period.
- A final idempotent draw runs after the application interval closes and can be retried manually after a missed or failed run.
- Applying lottery results must not mark the lottery complete when any reservation failed to materialize.

## Pending Decisions

- Define whether `hasRoom` is manager-owned or snapshotted for a lottery so it cannot change the draw priority during the application period.
- Define whether holidays or semester-specific duty-hour exceptions need configuration.
- Confirm which manager actions may override the normal actor and organization ownership rules.
- Confirm whether lottery results may be applied only before the event starts or until the event ends.
