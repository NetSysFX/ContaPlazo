import 'package:contaplazo/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra panel principal', (tester) async {
    await tester.pumpWidget(const ContaPlazoApp());
    expect(find.text('ContaPlazo'), findsOneWidget);
    expect(find.text('Próximos vencimientos'), findsOneWidget);
    expect(find.text('Saldo por cobrar'), findsOneWidget);
  });
  testWidgets('navega a clientes', (tester) async {
    await tester.pumpWidget(const ContaPlazoApp());
    await tester.tap(find.text('Clientes'));
    await tester.pumpAndSettle();
    expect(find.text('Buscar por nombre, cédula o NIT'), findsOneWidget);
    expect(find.text('Nuevo cliente'), findsOneWidget);
  });
}
