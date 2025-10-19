# PR: Align frontend with backend contracts, add DTO models, improve token refresh, tests

## Summary
- Fixed invalid endpoints and aligned routes with backend controllers.
- Implemented robust token refresh (single-flight + auto-retry).
- Added typed Dart DTO models for Auth, Maintenance, Parts, WorkLogs, ServiceHistory, Pagination.
- Implemented workaround for missing GET /api/maintenance/requests/{id}.
- Added unit tests for DTO parsing and refresh flow.
- Added Endpoint → Screen → DTO mapping doc.

## Changes
- api:
  - Updated `lib/api/endpoints_service.dart` to remove non-existent routes.
  - Improved `lib/api/api_core.dart` refresh flow and retry logic.
- repositories:
  - `lib/core/repositories/maintenance_repository.dart` now fetches list and filters by id; sends valid bodies for close/unrepairable.
- models:
  - `lib/models/login_response_dto.dart`
  - `lib/models/user_info_dto.dart`
  - `lib/models/maintenance_request_response_dto.dart`
  - `lib/models/parts_catalog_response_dto.dart`
  - `lib/models/work_log_part_usage_dto.dart`
  - `lib/models/work_log_status_history_dto.dart`
  - `lib/models/work_log_dto.dart`
  - `lib/models/service_history_part_dto.dart`
  - `lib/models/service_history_dto.dart`
  - `lib/models/page_response.dart`
  - `lib/models/part_dto.dart`
  - `lib/models/reservation_request_dto.dart`
  - `lib/models/parts_search_dto.dart`
  - `lib/models/work_log_search_dto.dart`
- tests:
  - `test/dto_parsing_test.dart`
  - `test/api_core_refresh_test.dart`
- docs:
  - `docs/endpoint_screen_dto_mapping.md` (mapping)
  - this file

## How to run
1. cd frontend
2. flutter pub get
3. flutter test
4. flutter run -d chrome (or on device/emulator)

## Notes
- Backend does not expose GET `/api/maintenance/requests/{id}`; frontend uses list+filter workaround.
- Recommend adding that endpoint server-side in future.
