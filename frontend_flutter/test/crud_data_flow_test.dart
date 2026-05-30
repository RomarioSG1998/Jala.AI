import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:frontend_flutter/features/tanks/data/tank_repository.dart';
import 'package:frontend_flutter/features/water_quality/data/water_quality_repository.dart';
import 'package:frontend_flutter/features/feeding_records/data/feeding_record_repository.dart';
import 'package:frontend_flutter/features/harvests/data/harvest_repository.dart';
import 'package:frontend_flutter/features/maintenance/data/maintenance_repository.dart';
import 'package:frontend_flutter/features/employees/data/employee_repository.dart';
import 'package:frontend_flutter/features/inventory/data/inventory_repository.dart';
import 'package:frontend_flutter/features/finances/data/transaction_repository.dart';
import 'package:frontend_flutter/features/suppliers/data/supplier_repository.dart';

class MockDio implements Dio {
  final Future<Response<dynamic>> Function(String path, {dynamic data, Map<String, dynamic>? queryParameters}) onRequest;

  MockDio(this.onRequest);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #get) {
      final path = invocation.positionalArguments[0] as String;
      final queryParams = invocation.namedArguments[#queryParameters] as Map<String, dynamic>?;
      return onRequest(path, queryParameters: queryParams);
    }
    if (name == #post) {
      final path = invocation.positionalArguments[0] as String;
      final data = invocation.namedArguments[#data];
      return onRequest(path, data: data);
    }
    if (name == #put) {
      final path = invocation.positionalArguments[0] as String;
      final data = invocation.namedArguments[#data];
      return onRequest(path, data: data);
    }
    if (name == #delete) {
      final path = invocation.positionalArguments[0] as String;
      return onRequest(path);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('TankRepository Tests', () {
    test('getTanks parses paginated content correctly', () async {
      final dio = MockDio((path, {data, queryParameters}) async {
        expect(path, '/api/tanks/farm/55555555-5555-5555-5555-555555555555');
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {
            'content': [
              {
                'id': 't1',
                'name': 'Tank 1',
                'fishSpecies': 'Tilapia',
                'fishCapacity': 100,
                'averageWeightG': 50.0,
                'mortalityCount': 2,
                'status': 'ACTIVE'
              }
            ]
          },
        );
      });

      final repo = TankRepository(dio);
      final list = await repo.getTanks();
      expect(list.length, 1);
      expect(list[0].id, 't1');
      expect(list[0].name, 'Tank 1');
      expect(list[0].fishSpecies, 'Tilapia');
    });

    test('createTank sends payload and returns model', () async {
      final dio = MockDio((path, {data, queryParameters}) async {
        expect(path, '/api/tanks');
        expect(data['farmId'], '55555555-5555-5555-5555-555555555555');
        expect(data['name'], 'New Tank');
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {
            'id': 't2',
            'name': 'New Tank',
            'fishSpecies': 'Tilapia',
            'fishCapacity': 120,
            'averageWeightG': 0.0,
            'mortalityCount': 0,
            'status': 'ACTIVE'
          },
        );
      });

      final repo = TankRepository(dio);
      final tank = await repo.createTank({'name': 'New Tank'});
      expect(tank.id, 't2');
      expect(tank.name, 'New Tank');
    });
  });

  group('WaterQualityRepository Tests', () {
    test('getRecords parses list correctly', () async {
      final dio = MockDio((path, {data, queryParameters}) async {
        expect(path, '/api/water-quality/farm/55555555-5555-5555-5555-555555555555');
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: [
            {
              'id': 'wq1',
              'tankId': 't1',
              'ph': 7.2,
              'temperature': 25.5,
              'dissolvedOxygen': 6.0,
              'createdAt': '2026-05-30T00:00:00'
            }
          ],
        );
      });

      final repo = WaterQualityRepository(dio);
      final list = await repo.getRecords();
      expect(list.length, 1);
      expect(list[0].id, 'wq1');
      expect(list[0].ph, 7.2);
    });
  });

  group('FeedingRecordRepository Tests', () {
    test('getRecords parses page content correctly', () async {
      final dio = MockDio((path, {data, queryParameters}) async {
        expect(path, '/api/feeding-records/farm/55555555-5555-5555-5555-555555555555');
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {
            'content': [
              {
                'id': 'fr1',
                'tankId': 't1',
                'feedId': 'f1',
                'userId': 'u1',
                'quantity': 12.5,
                'feedingTime': '2026-05-30T00:00:00'
              }
            ]
          },
        );
      });

      final repo = FeedingRecordRepository(dio);
      final list = await repo.getRecords();
      expect(list.length, 1);
      expect(list[0].id, 'fr1');
      expect(list[0].quantity, 12.5);
    });
  });

  group('HarvestRepository Tests', () {
    test('getHarvests parses page content correctly', () async {
      final dio = MockDio((path, {data, queryParameters}) async {
        expect(path, '/api/harvests/farm/55555555-5555-5555-5555-555555555555');
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {
            'content': [
              {
                'id': 'h1',
                'tankId': 't1',
                'date': '2026-05-30',
                'quantityKg': 450.0,
                'destination': 'Supermarket'
              }
            ]
          },
        );
      });

      final repo = HarvestRepository(dio);
      final list = await repo.getHarvests();
      expect(list.length, 1);
      expect(list[0].id, 'h1');
      expect(list[0].quantityKg, 450.0);
    });
  });

  group('MaintenanceRepository Tests', () {
    test('getTasks parses list correctly', () async {
      final dio = MockDio((path, {data, queryParameters}) async {
        expect(path, '/api/maintenance/farm/55555555-5555-5555-5555-555555555555');
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: [
            {
              'id': 'm1',
              'tankId': 't1',
              'description': 'Clean filter',
              'status': 'PENDING',
              'scheduledDate': '2026-06-05'
            }
          ],
        );
      });

      final repo = MaintenanceRepository(dio);
      final list = await repo.getTasks();
      expect(list.length, 1);
      expect(list[0].id, 'm1');
      expect(list[0].description, 'Clean filter');
    });

    test('updateTask sends full payload including tankId', () async {
      final dio = MockDio((path, {data, queryParameters}) async {
        expect(path, '/api/maintenance/m1');
        expect(data['tankId'], 't1');
        expect(data['description'], 'Clean filter');
        expect(data['status'], 'COMPLETED');
        expect(data['scheduledDate'], '2026-06-05');
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {
            'id': 'm1',
            'farmId': '55555555-5555-5555-5555-555555555555',
            'tankId': 't1',
            'description': 'Clean filter',
            'status': 'COMPLETED',
            'scheduledDate': '2026-06-05'
          },
        );
      });

      final repo = MaintenanceRepository(dio);
      final task = await repo.updateTask('m1', {
        'tankId': 't1',
        'description': 'Clean filter',
        'status': 'COMPLETED',
        'scheduledDate': '2026-06-05'
      });
      expect(task.id, 'm1');
      expect(task.status, 'COMPLETED');
      expect(task.tankId, 't1');
    });
  });

  group('EmployeeRepository Tests', () {
    test('getEmployees parses list response correctly', () async {
      final dio = MockDio((path, {data, queryParameters}) async {
        expect(path, '/api/employees/farm/55555555-5555-5555-5555-555555555555');
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: [
            {
              'id': 'e1',
              'name': 'John Worker',
              'email': 'john.worker@testfarm.com',
              'accountType': 'FIELD_WORKER'
            }
          ],
        );
      });

      final repo = EmployeeRepository(dio);
      final list = await repo.getEmployees();
      expect(list.length, 1);
      expect(list[0].id, 'e1');
      expect(list[0].name, 'John Worker');
    });
  });

  group('InventoryRepository Tests', () {
    test('getItems parses page content correctly', () async {
      final dio = MockDio((path, {data, queryParameters}) async {
        expect(path, '/api/inventory/farm/55555555-5555-5555-5555-555555555555');
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {
            'content': [
              {
                'id': 'i1',
                'itemName': 'Super Feed 200',
                'quantity': 500.0,
                'unit': 'kg',
                'type': 'Feed'
              }
            ]
          },
        );
      });

      final repo = InventoryRepository(dio);
      final list = await repo.getItems();
      expect(list.length, 1);
      expect(list[0].id, 'i1');
      expect(list[0].itemName, 'Super Feed 200');
    });
  });

  group('TransactionRepository Tests', () {
    test('getTransactions parses list correctly', () async {
      final dio = MockDio((path, {data, queryParameters}) async {
        expect(path, '/api/finances/farm/55555555-5555-5555-5555-555555555555');
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: [
            {
              'id': 'tr1',
              'type': 'EXPENSE',
              'amount': 350.0,
              'createdAt': '2026-05-30T00:00:00'
            }
          ],
        );
      });

      final repo = TransactionRepository(dio);
      final list = await repo.getTransactions();
      expect(list.length, 1);
      expect(list[0].id, 'tr1');
      expect(list[0].amount, 350.0);
    });
  });

  group('SupplierRepository Tests', () {
    test('getSuppliers parses list correctly', () async {
      final dio = MockDio((path, {data, queryParameters}) async {
        expect(path, '/api/suppliers');
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: [
            {
              'id': 's1',
              'companyName': 'Supplier Co',
              'cnpj': '00.111.222/0001-33',
              'supplyType': 'Fish Feed',
              'isApproved': true
            }
          ],
        );
      });

      final repo = SupplierRepository(dio);
      final list = await repo.getSuppliers();
      expect(list.length, 1);
      expect(list[0].id, 's1');
      expect(list[0].companyName, 'Supplier Co');
    });
  });
}
