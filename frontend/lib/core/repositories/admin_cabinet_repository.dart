import '../../api/api_service.dart';
import '../../models/admin_account_update_dto.dart';
import '../../models/admin_complaint_dto.dart';
import '../../models/admin_help_request_dto.dart';
import '../../models/admin_registration_application_dto.dart';
import '../../models/admin_appeal_dto.dart';
import '../../models/admin_mechanic_account_change_dto.dart';
import '../../models/admin_mechanic_status_change_dto.dart';
import '../../models/admin_staff_status_update_dto.dart';
import '../../models/mechanic_club_link_request_dto.dart';
import '../../models/free_mechanic_application_response_dto.dart';

class AdminCabinetRepository {
  final ApiService _api = ApiService();

  Future<List<AdminRegistrationApplicationDto>> getRegistrations({int page = 0, int size = 50}) {
    return _api.getAdminRegistrations(page: page, size: size);
  }

  Future<List<AdminAppealDto>> listAppeals() {
    return _api.listAdminAppeals();
  }

  Future<void> replyToAppeal({required String appealId, required String message}) async {
    await _api.replyToAppeal(appealId: appealId, message: message);
  }

  Future<AdminRegistrationApplicationDto> approveRegistration(int userId) {
    return _api.approveRegistration(userId);
  }

  Future<AdminRegistrationApplicationDto> rejectRegistration(int userId, {String? reason}) {
    return _api.rejectRegistration(userId, reason: reason);
  }

  Future<AdminRegistrationApplicationDto> updateFreeMechanicAccount(
    int userId,
    AdminAccountUpdateDto update,
  ) {
    return _api.updateFreeMechanicAccount(userId, update);
  }

  Future<AdminRegistrationApplicationDto> convertMechanicAccount(
    int userId,
    AdminMechanicAccountChangeDto change,
  ) {
    return _api.convertMechanicAccount(userId, change);
  }

  Future<AdminRegistrationApplicationDto> changeMechanicClubLink(
    int profileId,
    MechanicClubLinkRequestDto request,
  ) {
    return _api.changeMechanicClubLink(profileId, request);
  }

  Future<List<AdminComplaintDto>> listComplaints() {
    return _api.getSupplierComplaints();
  }

  Future<AdminComplaintDto> updateComplaint({
    required int reviewId,
    String? status,
    bool? resolved,
    String? notes,
  }) {
    return _api.updateSupplierComplaint(reviewId: reviewId, status: status, resolved: resolved, notes: notes);
  }

  Future<List<AdminMechanicStatusChangeDto>> listMechanicStatusChanges() {
    return _api.listMechanicStatusChanges();
  }

  Future<AdminMechanicStatusChangeDto> updateMechanicStatus({required int staffId, required AdminStaffStatusUpdateDto update}) {
    return _api.updateMechanicStatus(staffId: staffId, update: update);
  }

  Future<List<AdminHelpRequestDto>> listHelpRequests() {
    return _api.getAdminHelpRequests();
  }

  Future<List<FreeMechanicApplicationResponseDto>> listFreeMechanicApplications() {
    return _api.listFreeMechanicApplications();
  }
}
