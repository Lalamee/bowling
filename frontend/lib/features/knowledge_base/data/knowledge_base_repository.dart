import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../api/api_core.dart';
import '../domain/kb_pdf.dart';
import '../../../models/knowledge_base_document_create_dto.dart';

class KnowledgeBaseRepository {
  KnowledgeBaseRepository({Dio? dio}) : _dio = dio ?? ApiCore().dio;

  final Dio _dio;

  Future<List<KbPdf>> load() async {
    try {
      final response = await _dio.get('/api/knowledge-base/documents');
      final data = response.data;
      if (data is List) {
        final documents = <KbPdf>[];
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            documents.add(KbPdf.fromJson(item));
          } else if (item is Map) {
            documents.add(
              KbPdf.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            );
          }
        }
        return documents.where((doc) => doc.downloadUrl.isNotEmpty).toList();
      }
      throw ApiException('Не удалось загрузить документы');
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) {
        throw error;
      }
      throw ApiException('Не удалось загрузить документы');
    }
  }

  Future<Uint8List> fetchDocument(int documentId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/knowledge-base/documents/$documentId/content',
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null) {
        throw ApiException('Документ не содержит данных');
      }
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) {
        throw error;
      }
      throw ApiException('Не удалось загрузить документ');
    }
  }

  Future<Map<String, dynamic>> createDocument(KnowledgeBaseDocumentCreateDto payload) async {
    try {
      final response = await _dio.post('/api/knowledge-base/documents', data: payload.toJson());
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) {
        throw error;
      }
      throw ApiException('Не удалось загрузить документ');
    }
  }
}
