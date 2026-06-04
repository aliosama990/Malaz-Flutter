import 'package:flutter_test/flutter_test.dart';
import 'package:malaz_app/models/safe_zone_model.dart';
import 'package:malaz_app/providers/safezone_provider.dart';
import 'package:malaz_app/services/api_service.dart';

void main() {
  group('SafeZoneProvider.addZone', () {
    test('sends required request fields and resolves null add data by refresh',
        () async {
      final apiService = _FakeSafeZoneApiService(
        addResponseData: null,
        fetchedZones: const [
          {
            'id': '394fd6e4-ecad-4e00-a1f2-e188ee8ec0e2',
            'name': 'School',
            'latitude': 30.03837,
            'longitude': 31.24508,
            'radiusInMeters': 200,
            'type': 1,
            'typeDisplayName': 'Home',
            'createdAt': '2026-03-03T13:57:43.8453859Z',
          },
        ],
      );
      final provider = SafeZoneProvider(apiService: apiService);

      final zone = await provider.addZone(
        childId: '39e89959-bf23-4cd1-b0b8-d1f5985a78d6',
        name: 'School',
        latitude: 30.03837,
        longitude: 31.24508,
        radiusInMeters: 200,
        type: 1,
      );

      expect(apiService.lastPostPath, '/api/SafeZone/add');
      expect(apiService.lastPostBody, {
        'childId': '39e89959-bf23-4cd1-b0b8-d1f5985a78d6',
        'name': 'School',
        'latitude': 30.03837,
        'longitude': 31.24508,
        'radiusInMeters': 200,
        'type': 1,
      });
      expect(apiService.lastGetPath,
          '/api/SafeZone/child/39e89959-bf23-4cd1-b0b8-d1f5985a78d6');
      expect(zone.name, 'School');
      expect(zone.type, 1);
      expect(provider.zones, hasLength(1));
    });
  });

  group('SafeZoneModel.fromJson', () {
    test('parses the real add response with Arabic type text', () {
      final zone = SafeZoneModel.fromJson(
        const {
          'id': '29da61a1-2f16-44dc-b848-8bf90fe4ff04',
          'name': 'CodexRuntimeDebug',
          'latitude': 30.038372360888726,
          'longitude': 31.245084156146554,
          'radiusInMeters': 200,
          'type': 'البيت',
          'typeDisplayName': 'البيت',
          'createdAt': '2026-04-27T07:45:29.7487864Z',
        },
      );

      expect(zone.name, 'CodexRuntimeDebug');
      expect(zone.type, 1);
      expect(zone.typeDisplayName, 'البيت');
    });

    test('parses PascalCase response keys and optional display metadata', () {
      final zone = SafeZoneModel.fromJson(
        const {
          'Id': '394fd6e4-ecad-4e00-a1f2-e188ee8ec0e2',
          'Name': 'School',
          'Latitude': '30.03837',
          'Longitude': '31.24508',
          'RadiusInMeters': '200',
          'Type': '1',
        },
      );

      expect(zone.id, '394fd6e4-ecad-4e00-a1f2-e188ee8ec0e2');
      expect(zone.name, 'School');
      expect(zone.latitude, 30.03837);
      expect(zone.longitude, 31.24508);
      expect(zone.radiusInMeters, 200);
      expect(zone.type, 1);
      expect(zone.typeDisplayName, 'Home');
      expect(zone.createdAt, isEmpty);
    });
  });
}

class _FakeSafeZoneApiService extends ApiService {
  _FakeSafeZoneApiService({
    required this.addResponseData,
    required this.fetchedZones,
  });

  final dynamic addResponseData;
  final List<Map<String, dynamic>> fetchedZones;

  String? lastPostPath;
  Object? lastPostBody;
  String? lastGetPath;

  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool handleUnauthorized = true,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    return ApiResponse(
      statusCode: 200,
      success: true,
      hasEnvelope: true,
      errorMessages: const [],
      data: addResponseData,
      rawBody: {
        'success': true,
        'errorMessages': const [],
        'data': addResponseData,
      },
      headers: const {},
    );
  }

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool handleUnauthorized = true,
  }) async {
    lastGetPath = path;
    return ApiResponse(
      statusCode: 200,
      success: true,
      hasEnvelope: true,
      errorMessages: const [],
      data: fetchedZones,
      rawBody: {
        'success': true,
        'errorMessages': const [],
        'data': fetchedZones,
      },
      headers: const {},
    );
  }
}
