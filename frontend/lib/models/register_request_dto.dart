import 'register_user_dto.dart';
import 'mechanic_profile_dto.dart';
import 'owner_profile_dto.dart';

class RegisterRequestDto {
  final RegisterUserDto user;
  final MechanicProfileDto? mechanicProfile;
  final OwnerProfileDto? ownerProfile;

  RegisterRequestDto({
    required this.user,
    this.mechanicProfile,
    this.ownerProfile,
  });

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'mechanicProfile': mechanicProfile?.toJson(),
        'ownerProfile': ownerProfile?.toJson(),
      };

  factory RegisterRequestDto.fromJson(Map<String, dynamic> json) {
    return RegisterRequestDto(
      user: RegisterUserDto.fromJson(json['user'] as Map<String, dynamic>),
      mechanicProfile: json['mechanicProfile'] != null
          ? MechanicProfileDto.fromJson(json['mechanicProfile'] as Map<String, dynamic>)
          : null,
      ownerProfile: json['ownerProfile'] != null
          ? OwnerProfileDto.fromJson(json['ownerProfile'] as Map<String, dynamic>)
          : null,
    );
  }
}
