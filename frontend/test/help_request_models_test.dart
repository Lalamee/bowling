import 'package:flutter_test/flutter_test.dart';
import 'package:bowling_market/models/help_request_dto.dart';
import 'package:bowling_market/models/admin_help_request_dto.dart';

void main() {
  test('HelpRequestDto serializes part ids and reason', () {
    final dto = HelpRequestDto(partIds: [1, 2, 3], reason: 'Нужна поддержка');
    final json = dto.toJson();
    expect(json['partIds'], [1, 2, 3]);
    expect(json['reason'], 'Нужна поддержка');
    final parsed = HelpRequestDto.fromJson(json);
    expect(parsed.partIds, [1, 2, 3]);
    expect(parsed.reason, 'Нужна поддержка');
  });

  test('HelpResponseDto converts decision values', () {
    final dto = HelpResponseDto(
      partIds: [5],
      decision: HelpResponseDecision.reassigned,
      reassignedMechanicId: 99,
      comment: 'Передаем другому мастеру',
    );
    final json = dto.toJson();
    expect(json['decision'], 'REASSIGNED');
    final parsed = HelpResponseDto.fromJson({
      'partIds': [5],
      'decision': 'DECLINED',
      'comment': 'Нет доступа',
    });
    expect(parsed.decision, HelpResponseDecision.declined);
    expect(parsed.partIds, [5]);
    expect(parsed.comment, 'Нет доступа');
  });

  test('AdminHelpRequestDto maps primitive fields', () {
    final dto = AdminHelpRequestDto.fromJson({
      'requestId': 10,
      'partId': 20,
      'mechanicProfileId': 30,
      'clubId': 40,
      'laneNumber': 5,
      'helpRequested': true,
      'partStatus': 'PENDING',
      'managerNotes': 'Уточнить детали',
    });
    expect(dto.requestId, 10);
    expect(dto.partId, 20);
    expect(dto.mechanicProfileId, 30);
    expect(dto.clubId, 40);
    expect(dto.laneNumber, 5);
    expect(dto.helpRequested, true);
    expect(dto.partStatus, 'PENDING');
    expect(dto.managerNotes, 'Уточнить детали');
  });
}
