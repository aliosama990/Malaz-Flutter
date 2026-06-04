import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:malaz_app/models/child_mode.dart';
import 'package:malaz_app/services/api_service.dart';

void main() {
  group('AddChild response parsing', () {
    test('parses the documented wrapped response without condition', () {
      final response = http.Response(
        '''
        {
          "success": true,
          "errorMessages": [],
          "data": {
            "id": "2e292a81-ece4-456e-a7a8-7d82bc3ba376",
            "name": "mostafa",
            "gender": 0,
            "birthDate": "2010-04-10T00:00:00",
            "deviceId": "watch123",
            "safeZones": []
          }
        }
        ''',
        200,
        headers: const {'content-type': 'application/json'},
      );

      final apiResponse = ApiResponse.fromHttpResponse(response);
      final child = ChildModel.fromJson(
        Map<String, dynamic>.from(apiResponse.data as Map),
      );

      expect(apiResponse.hasEnvelope, isTrue);
      expect(child.id, '2e292a81-ece4-456e-a7a8-7d82bc3ba376');
      expect(child.name, 'mostafa');
      expect(child.gender, 0);
      expect(child.birthDate, '2010-04-10');
      expect(child.deviceId, 'watch123');
      expect(child.condition, isNull);
    });

    test('parses envelope and child keys when the backend changes casing', () {
      final response = http.Response(
        '''
        {
          "Success": true,
          "ErrorMessages": [],
          "Data": {
            "Id": "39e89959-bf23-4cd1-b0b8-d1f5985a78d6",
            "Name": "Ali",
            "Gender": 0,
            "BirthDate": "2018-05-10T00:00:00",
            "DeviceId": "watch123",
            "Condition": 1
          }
        }
        ''',
        200,
        headers: const {'content-type': 'application/json'},
      );

      final apiResponse = ApiResponse.fromHttpResponse(response);
      final child = ChildModel.fromJson(
        Map<String, dynamic>.from(apiResponse.data as Map),
      );

      expect(apiResponse.hasEnvelope, isTrue);
      expect(child.id, '39e89959-bf23-4cd1-b0b8-d1f5985a78d6');
      expect(child.name, 'Ali');
      expect(child.gender, 0);
      expect(child.birthDate, '2018-05-10');
      expect(child.deviceId, 'watch123');
      expect(child.condition, ChildCondition.autism);
    });

    test('parses gender when the backend returns it as a numeric string', () {
      final response = http.Response(
        '''
        {
          "success": true,
          "errorMessages": [],
          "data": {
            "id": "39e89959-bf23-4cd1-b0b8-d1f5985a78d6",
            "name": "Ali",
            "gender": "1",
            "birthDate": "2018-05-10T00:00:00",
            "deviceId": "watch123"
          }
        }
        ''',
        200,
        headers: const {'content-type': 'application/json'},
      );

      final apiResponse = ApiResponse.fromHttpResponse(response);
      final child = ChildModel.fromJson(
        Map<String, dynamic>.from(apiResponse.data as Map),
      );

      expect(child.gender, 1);
    });

    test('parses gender when the backend returns it as a label string', () {
      final response = http.Response(
        '''
        {
          "success": true,
          "errorMessages": [],
          "data": {
            "id": "39e89959-bf23-4cd1-b0b8-d1f5985a78d6",
            "name": "Ali",
            "gender": "Male",
            "birthDate": "2018-05-10T00:00:00",
            "deviceId": "watch123"
          }
        }
        ''',
        200,
        headers: const {'content-type': 'application/json'},
      );

      final apiResponse = ApiResponse.fromHttpResponse(response);
      final child = ChildModel.fromJson(
        Map<String, dynamic>.from(apiResponse.data as Map),
      );

      expect(child.gender, 0);
    });
  });
}
