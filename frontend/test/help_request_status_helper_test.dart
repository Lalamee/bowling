import 'package:flutter_test/flutter_test.dart';
import 'package:bowling_market/models/notification_event_dto.dart';
import 'package:bowling_market/core/utils/help_request_status_helper.dart';

NotificationEventDto _event(String type, {String? payload, int? requestId, List<int>? partIds, String? created}) {
  return NotificationEventDto.fromJson({
    'id': '1',
    'type': type,
    'message': 'msg',
    'payload': payload,
    'requestId': requestId ?? 10,
    'partIds': partIds ?? const [1, 2],
    'createdAt': created ?? '2024-01-01T12:00:00Z',
  });
}

void main() {
  test('deriveHelpRequestStatus resolves awaiting state', () {
    final status = deriveHelpRequestStatus(
      events: [_event('MECHANIC_HELP_REQUESTED', payload: 'нужна помощь')],
      requestId: 10,
    );
    expect(status.resolution, HelpRequestResolution.awaiting);
    expect(status.comment, 'нужна помощь');
    expect(status.partIds, [1, 2]);
  });

  test('deriveHelpRequestStatus prefers latest decision', () {
    final status = deriveHelpRequestStatus(
      events: [
        _event('MECHANIC_HELP_REQUESTED', created: '2024-01-01T12:00:00Z'),
        _event('MECHANIC_HELP_DECLINED', payload: 'нет доступа', created: '2024-01-02T12:00:00Z'),
      ],
      requestId: 10,
    );
    expect(status.resolution, HelpRequestResolution.declined);
    expect(status.comment, 'нет доступа');
  });

  test('deriveHelpRequestStatus ignores unrelated requests', () {
    final status = deriveHelpRequestStatus(
      events: [_event('MECHANIC_HELP_DECLINED', requestId: 99)],
      requestId: 10,
    );
    expect(status.resolution, HelpRequestResolution.none);
  });
}
