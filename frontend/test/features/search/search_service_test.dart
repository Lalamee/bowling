import 'package:flutter_test/flutter_test.dart';

import 'package:bowling_market/core/services/search_service.dart';
import 'package:bowling_market/core/repositories/maintenance_repository.dart';
import 'package:bowling_market/core/repositories/parts_repository.dart';
import 'package:bowling_market/core/repositories/clubs_repository.dart';
import 'package:bowling_market/features/knowledge_base/data/knowledge_base_repository.dart';
import 'package:bowling_market/core/repositories/club_staff_repository.dart';
import 'package:bowling_market/models/maintenance_request_response_dto.dart';
import 'package:bowling_market/models/parts_catalog_response_dto.dart';
import 'package:bowling_market/models/club_summary_dto.dart';
import 'package:bowling_market/features/knowledge_base/domain/kb_pdf.dart';
import 'package:bowling_market/core/repositories/service_history_repository.dart';

void main() {
  late SearchServiceImpl service;

  setUp(() {
    service = SearchServiceImpl(
      maintenanceRepository: _MaintenanceStub(),
      partsRepository: _PartsStub(),
      clubsRepository: _ClubsStub(),
      knowledgeBaseRepository: _KnowledgeStub(),
      clubStaffRepository: _StaffStub(),
    );
  });

  test('searchByDomain filters orders', () async {
    final result = await service.searchByDomain(SearchDomain.orders, 'Город', page: 1);
    expect(result.items, hasLength(1));
    expect(result.items.first.title, contains('Заявка'));
  });

  test('searchAll aggregates totals', () async {
    final result = await service.searchAll('');
    expect(result.totalCount, 6); // two orders, one part, one club, one doc, one user
    expect(result.items, isNotEmpty);
  });

  test('lookup helpers return cached entities', () async {
    await service.searchByDomain(SearchDomain.orders, '');
    final order = await service.getOrderById('1');
    expect(order, isNotNull);

    await service.searchByDomain(SearchDomain.parts, 'подшипник');
    final part = await service.getPartById('PN-1');
    expect(part?.catalogNumber, 'PN-1');

    await service.searchByDomain(SearchDomain.clubs, '');
    final club = await service.getClubById('10');
    expect(club?.name, 'Bowling City');

    await service.searchByDomain(SearchDomain.knowledge, '');
    final doc = await service.getDocumentById('https://example.com/doc.pdf');
    expect(doc?.title, 'Service Manual');

    await service.searchByDomain(SearchDomain.users, '');
    final user = await service.getUserById('10-101-MECHANIC');
    expect(user?.name, 'Иван');
  });
}

class _MaintenanceStub extends MaintenanceRepository {
  @override
  Future<List<MaintenanceRequestResponseDto>> getAllRequests() async {
    return [
      MaintenanceRequestResponseDto(
        requestId: 1,
        clubId: 10,
        clubName: 'Bowling City',
        laneNumber: 1,
        mechanicId: 5,
        mechanicName: 'Иван',
        requestDate: DateTime(2024, 1, 1),
        completionDate: null,
        status: 'NEW',
        managerNotes: null,
        managerDecisionDate: null,
        verificationStatus: null,
        requestedParts: const [],
      ),
      MaintenanceRequestResponseDto(
        requestId: 2,
        clubId: 11,
        clubName: 'Strike Club',
        laneNumber: 2,
        mechanicId: 6,
        mechanicName: 'Пётр',
        requestDate: DateTime(2024, 1, 2),
        completionDate: null,
        status: 'IN_PROGRESS',
        managerNotes: null,
        managerDecisionDate: null,
        verificationStatus: null,
        requestedParts: const [],
      ),
    ];
  }
}

class _PartsStub extends PartsRepository {
  @override
  Future<List<PartsCatalogResponseDto>> search(String query, {cancelToken}) async {
    return [
      PartsCatalogResponseDto(
        catalogId: 1,
        catalogNumber: 'PN-1',
        manufacturerId: 1,
        manufacturerName: 'ACME',
        officialNameEn: 'Bearing',
        officialNameRu: 'Подшипник',
        commonName: 'Основной подшипник',
        description: 'Запчасть',
        normalServiceLife: 12,
        unit: 'шт',
        isUnique: false,
        availableQuantity: 4,
        availabilityStatus: 'IN_STOCK',
      ),
    ];
  }
}

class _ClubsStub extends ClubsRepository {
  @override
  Future<List<ClubSummaryDto>> getClubs() async {
    return [
      ClubSummaryDto(
        id: 10,
        name: 'Bowling City',
        address: 'Город, ул. Ленина 1',
        city: 'Город',
        contactPhone: '+79990001122',
        description: null,
        openingHours: null,
        rating: null,
        imageUrl: null,
      ),
    ];
  }
}

class _KnowledgeStub extends KnowledgeBaseRepository {
  _KnowledgeStub()
      : super(
          maintenanceRepository: _MaintenanceStub(),
          serviceHistoryRepository: _ServiceHistoryStub(),
        );

  @override
  Future<List<KbPdf>> load() async {
    return [
      KbPdf(title: 'Service Manual', url: 'https://example.com/doc.pdf', clubId: 10, serviceId: 1),
    ];
  }
}

class _ServiceHistoryStub extends ServiceHistoryRepository {}

class _StaffStub extends ClubStaffRepository {
  @override
  Future<List<dynamic>> getClubStaff(int clubId) async {
    return [
      {
        'id': 101,
        'fullName': 'Иван',
        'phone': '+79990000000',
        'role': 'MECHANIC',
      },
    ];
  }
}
