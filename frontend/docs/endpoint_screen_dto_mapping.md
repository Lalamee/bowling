# Endpoint → Screen → DTO mapping

- **Auth screens**
  - Login screen → POST `/api/auth/login` → Request: `UserLoginDTO` | Response: `LoginResponseDTO` → Dart: `LoginResponseDto`
  - Profile (me) → GET `/api/auth/me` → Response: `UserInfoDTO` → Dart: `UserInfoDto`
  - Change password → POST `/api/auth/change-password` → Request: `PasswordChangeRequest`
  - Refresh (automatic) → POST `/api/auth/refresh` → Request: `RefreshTokenRequestDTO` | Response: `LoginResponseDTO`

- **Registration screens**
  - Register owner/mechanic → POST `/api/auth/register` → Request: `RegisterRequestDTO` (with `RegisterUserDTO`, `OwnerProfileDTO` or `MechanicProfileDTO`)

- **Maintenance (Requests) screens**
  - List → GET `/api/maintenance/requests` → Response: `List<MaintenanceRequestResponseDTO>` → Dart: `MaintenanceRequestResponseDto`
  - By mechanic → GET `/api/maintenance/requests/mechanic/{mechanicId}` → same as above
  - By status → GET `/api/maintenance/requests/status/{status}` → same as above
  - Create → POST `/api/maintenance/requests` → Request: `PartRequestDTO`
  - Approve → PUT `/api/maintenance/requests/{requestId}/approve` → Request: `ApproveRejectRequestDTO`
  - Reject → PUT `/api/maintenance/requests/{requestId}/reject` → Request: `ApproveRejectRequestDTO`
  - Publish/Assign/Deliver/Issue/Close/Unrepairable → PUT `/api/maintenance/requests/{id}/...` → Request: `Map` or dedicated DTO (`ApproveRejectRequestDTO` for unrepairable)
  - Note: Backend does not expose GET `/api/maintenance/requests/{id}`. Frontend uses list+filter workaround.

- **WorkLogs screens**
  - Create → POST `/api/worklogs` → Request: `WorkLogDTO` → Dart: `WorkLogDto`
  - Get by id → GET `/api/worklogs/{id}` → Response: `WorkLogDTO`
  - Update → PUT `/api/worklogs/{id}` → Request: `WorkLogDTO`
  - Delete → DELETE `/api/worklogs/{id}`
  - Search → POST `/api/worklogs/search` → Request: `WorkLogSearchDTO` | Response: `Page<WorkLogDTO>` → Dart: `PageResponse<WorkLogDto>`
  - Nested DTOs: `WorkLogPartUsageDTO` → Dart: `WorkLogPartUsageDto`, `WorkLogStatusHistoryDTO` → Dart: `WorkLogStatusHistoryDto`

- **Service History screens**
  - Create → POST `/api/service-history` → Request: `ServiceHistoryDTO` → Dart: `ServiceHistoryDto`
  - Get by id → GET `/api/service-history/{id}` → Response: `ServiceHistoryDTO`
  - By club → GET `/api/service-history/club/{clubId}` → `List<ServiceHistoryDTO>`
  - Nested DTO: `ServiceHistoryPartDTO` → Dart: `ServiceHistoryPartDto`

- **Parts screens**
  - Search (catalog) → POST `/api/parts/search` → Request: `PartsSearchDTO` | Response: `List<PartsCatalogResponseDTO>` → Dart: `PartsCatalogResponseDto`
  - Unique → GET `/api/parts/unique` → `List<PartsCatalogResponseDTO>`
  - All → GET `/api/parts/all` → `List<PartsCatalogResponseDTO>`
  - Detail by catalog number → GET `/api/parts/catalog/{catalogNumber}` → `PartsCatalogResponseDTO`

- **Inventory screens**
  - Search → GET `/inventory/search?query=...&clubId=...` → `List<PartDto>` (Dart model можно добавить при необходимости)
  - Get by id → GET `/inventory/{id}` → `PartDto`
  - Reserve → POST `/inventory/reserve` → `ReservationRequestDto`
  - Release → POST `/inventory/release` → `ReservationRequestDto`

- **Admin screens**
  - Verify → PUT `/api/admin/users/{userId}/verify`
  - Activate/Deactivate → PUT `/api/admin/users/{userId}/activate|deactivate`
  - Reject registration → DELETE `/api/admin/users/{userId}/reject`

## Notes
- Authorization: everything except `/api/auth/**`, swagger and OPTIONS requires Bearer JWT.
- Dates are ISO-8601 strings; parsed to `DateTime` in Dart.
- Pagination: Spring `Page<T>` mapped to Dart `PageResponse<T>` with basic fields.
