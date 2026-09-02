import 'package:contaplazo/main.dart';
import 'package:contaplazo/data/local_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra panel principal', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    expect(find.text('ContaPlazo'), findsOneWidget);
    expect(find.text('Resumen visual'), findsOneWidget);
    expect(find.text('Saldo por cobrar'), findsOneWidget);
  });
  testWidgets('navega a clientes', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clientes'));
    await tester.pumpAndSettle();
    expect(find.text('Buscar por nombre, cédula o NIT'), findsOneWidget);
    expect(find.text('Nuevo cliente'), findsOneWidget);
  });

  testWidgets('abre el detalle de declaraciones pendientes', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Declaraciones pendientes'));
    await tester.pumpAndSettle();
    expect(find.text('3 obligaciones requieren seguimiento'), findsOneWidget);
    expect(find.text('María Gómez'), findsOneWidget);
    expect(find.text('Carlos Rodríguez'), findsOneWidget);
  });

  testWidgets('muestra una acción visible para cargar documentos', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clientes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('María Gómez'));
    await tester.pumpAndSettle();
    expect(find.text('Gestión de documentos'), findsOneWidget);
    expect(find.byKey(const Key('uploadDocumentButton')), findsOneWidget);
    expect(find.text('Cargar documento'), findsOneWidget);
  });

  test('serializa y recupera todos los datos de un cliente', () {
    final original = Client(
      'Ana Pérez',
      '123456',
      DateTime(2026, 10, 5),
      450000,
      true,
      4,
      TaxStatus.progress,
    );
    final recovered = Client.fromMap(original.toMap());
    expect(recovered.name, original.name);
    expect(recovered.nit, original.nit);
    expect(recovered.due, original.due);
    expect(recovered.fee, original.fee);
    expect(recovered.paid, isTrue);
    expect(recovered.docs, 4);
    expect(recovered.status, TaxStatus.progress);
  });
}

Widget _testApp() => MaterialApp(
  home: HomeShell(store: MemoryClientStore(), enableDocumentStorage: false),
);

class MemoryClientStore implements ClientStore {
  List<Map<String, Object?>> data = [];
  Map<String, Object?>? accountant;
  @override
  Future<List<Map<String, Object?>>> loadClients() async => data;
  @override
  Future<void> saveClients(List<Map<String, Object?>> clients) async {
    data = clients;
  }

  @override
  Future<Map<String, Object?>?> loadAccountant() async => accountant;
  @override
  Future<void> saveAccountant(Map<String, Object?> profile) async {
    accountant = profile;
  }
}
