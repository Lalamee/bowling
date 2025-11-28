import '../../api/api_service.dart';
import '../../models/admin_account_update_dto.dart';
import '../../models/admin_complaint_dto.dart';
import '../../models/admin_help_request_dto.dart';
import '../../models/admin_registration_application_dto.dart';
import '../../models/mechanic_club_link_request_dto.dart';

class AdminCabinetRepository {
  final ApiService _api = ApiService();

  Future<List<AdminRegistrationApplicationDto>> getRegistrations() {
    return _api.getAdminRegistrations();
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

  Future<List<AdminHelpRequestDto>> listHelpRequests() {
    return _api.getAdminHelpRequests();
  }
}
