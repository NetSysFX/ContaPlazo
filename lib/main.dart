import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'data/local_database.dart';

void main() => runApp(const ContaPlazoApp());

const brand = Color(0xFF075E54);

class ContaPlazoApp extends StatelessWidget {
  const ContaPlazoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ContaPlazo',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: brand),
      scaffoldBackgroundColor: const Color(0xFFF4F7F5),
      useMaterial3: true,
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Color(0xFFE1E8E4)),
        ),
      ),
    ),
    home: const HomeShell(),
  );
}

enum TaxStatus { pending, progress, filed }

class Client {
  Client(
    this.name,
    this.nit,
    this.due,
    this.fee,
    this.paid,
    this.docs,
    this.status,
  );
  final String name, nit;
  DateTime due;
  double fee;
  bool paid;
  int docs;
  TaxStatus status;
  final List<StoredDocument> files = [];

  Map<String, Object?> toMap() => {
    'nit': nit,
    'name': name,
    'due_date': due.toIso8601String(),
    'fee': fee,
    'paid': paid ? 1 : 0,
    'document_count': docs,
    'tax_status': status.index,
  };

  factory Client.fromMap(Map<String, Object?> map) => Client(
    map['name']! as String,
    map['nit']! as String,
    DateTime.parse(map['due_date']! as String),
    (map['fee']! as num).toDouble(),
    map['paid'] == 1,
    map['document_count']! as int,
    TaxStatus.values[map['tax_status']! as int],
  );
}

class StoredDocument {
  StoredDocument(this.name, this.path, this.size, this.modified);
  final String name, path;
  final int size;
  final DateTime modified;
}

class AccountantProfile {
  AccountantProfile({
    this.name = '',
    this.professionalId = '',
    this.phone = '',
    this.email = '',
    this.firm = '',
  });
  String name, professionalId, phone, email, firm;
  Map<String, Object?> toMap() => {
    'name': name,
    'professional_id': professionalId,
    'phone': phone,
    'email': email,
    'firm': firm,
  };
  factory AccountantProfile.fromMap(Map<String, Object?> map) =>
      AccountantProfile(
        name: map['name']! as String,
        professionalId: map['professional_id']! as String,
        phone: map['phone']! as String,
        email: map['email']! as String,
        firm: map['firm']! as String,
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.store, this.enableDocumentStorage = true});
  final ClientStore? store;
  final bool enableDocumentStorage;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  bool loading = true;
  late final ClientStore store;
  AccountantProfile accountant = AccountantProfile();
  final clients = <Client>[
    Client(
      'María Gómez',
      '52.841.963',
      DateTime(2026, 9, 4),
      280000,
      false,
      3,
      TaxStatus.progress,
    ),
    Client(
      'Carlos Rodríguez',
      '79.402.118',
      DateTime(2026, 9, 8),
      320000,
      true,
      5,
      TaxStatus.pending,
    ),
    Client(
      'Distribuciones Nova SAS',
      '901.452.778-3',
      DateTime(2026, 9, 12),
      650000,
      false,
      4,
      TaxStatus.pending,
    ),
    Client(
      'Laura Martínez',
      '1.032.884.120',
      DateTime(2026, 9, 18),
      250000,
      true,
      6,
      TaxStatus.filed,
    ),
  ];

  @override
  void initState() {
    super.initState();
    store = widget.store ?? LocalDatabase.instance;
    _initializePersistence();
  }

  Future<void> _initializePersistence() async {
    final storedAccountant = await store.loadAccountant();
    if (storedAccountant != null) {
      accountant = AccountantProfile.fromMap(storedAccountant);
    }
    final stored = await store.loadClients();
    if (stored.isEmpty) {
      await _saveClients();
    } else {
      clients
        ..clear()
        ..addAll(stored.map(Client.fromMap));
    }
    if (widget.enableDocumentStorage) await _loadStoredDocuments();
    await _saveClients();
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadStoredDocuments() async {
    for (final client in clients) {
      final directory = await clientDirectory(client);
      if (!await directory.exists()) continue;
      final files = await directory
          .list()
          .where((item) => item is File)
          .cast<File>()
          .toList();
      client.files
        ..clear()
        ..addAll(
          await Future.wait(
            files.map((file) async {
              final stat = await file.stat();
              return StoredDocument(
                file.uri.pathSegments.last,
                file.path,
                stat.size,
                stat.modified,
              );
            }),
          ),
        );
      if (client.files.isNotEmpty) client.docs = client.files.length;
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveClients() =>
      store.saveClients(clients.map((client) => client.toMap()).toList());

  Future<void> _saveAccountant(AccountantProfile profile) async {
    accountant = profile;
    await store.saveAccountant(profile.toMap());
    if (mounted) setState(() {});
  }

  Future<void> addClient() async {
    final name = TextEditingController(), nit = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre o razón social',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nit,
              decoration: const InputDecoration(labelText: 'Cédula o NIT'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      setState(
        () => clients.add(
          Client(
            name.text.trim(),
            nit.text.trim(),
            DateTime.now().add(const Duration(days: 30)),
            0,
            false,
            0,
            TaxStatus.pending,
          ),
        ),
      );
      await _saveClients();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(clients, refresh, accountant),
      Clients(clients, refresh),
      Payments(clients, refresh),
      Settings(accountant, _saveAccountant),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              child: Image(
                image: AssetImage('assets/branding/contaplazo_icon.png'),
                width: 34,
                height: 34,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'ContaPlazo',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .4),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : pages[index],
      ),
      floatingActionButton: index == 1
          ? FloatingActionButton.extended(
              onPressed: addClient,
              icon: const Icon(Icons.person_add),
              label: const Text('Nuevo cliente'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Pagos',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  void refresh() {
    setState(() {});
    unawaited(_saveClients());
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard(this.clients, this.refresh, this.accountant, {super.key});
  final List<Client> clients;
  final VoidCallback refresh;
  final AccountantProfile accountant;
  @override
  Widget build(BuildContext context) {
    final pending = clients.where((c) => c.status != TaxStatus.filed).length;
    final debt = clients
        .where((c) => !c.paid)
        .fold<double>(0, (s, c) => s + c.fee);
    final ordered = [...clients]..sort((a, b) => a.due.compareTo(b.due));
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          accountant.name.isEmpty
              ? 'Buenos días, contador'
              : 'Buenos días, ${accountant.name}',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Text('Este es el estado de tus obligaciones tributarias.'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Metric(
                Icons.event_note,
                '$pending',
                'Declaraciones pendientes',
                Colors.deepOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Metric(
                Icons.account_balance_wallet,
                money(debt),
                'Saldo por cobrar',
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        DashboardCharts(clients: clients),
        const SizedBox(height: 24),
        Text(
          'Próximos vencimientos',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...ordered
            .take(3)
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClientTile(c, refresh),
              ),
            ),
      ],
    );
  }
}

class DashboardCharts extends StatelessWidget {
  const DashboardCharts({super.key, required this.clients});
  final List<Client> clients;
  @override
  Widget build(BuildContext context) {
    final total = clients.isEmpty ? 1 : clients.length;
    final filed = clients.where((c) => c.status == TaxStatus.filed).length;
    final progress = clients
        .where((c) => c.status == TaxStatus.progress)
        .length;
    final pending = clients.where((c) => c.status == TaxStatus.pending).length;
    final paid = clients
        .where((c) => c.paid)
        .fold<double>(0, (s, c) => s + c.fee);
    final billed = clients.fold<double>(0, (s, c) => s + c.fee);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen visual',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: filed / total,
                        strokeWidth: 11,
                        backgroundColor: const Color(0xFFE6ECE9),
                        color: Colors.green,
                      ),
                      Text(
                        '${(filed / total * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    children: [
                      ChartBar(
                        label: 'Presentadas',
                        value: filed / total,
                        count: filed,
                        color: Colors.green,
                      ),
                      ChartBar(
                        label: 'En proceso',
                        value: progress / total,
                        count: progress,
                        color: Colors.blue,
                      ),
                      ChartBar(
                        label: 'Pendientes',
                        value: pending / total,
                        count: pending,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recaudo de honorarios'),
                Text(
                  '${billed == 0 ? 0 : (paid / billed * 100).round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: brand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: billed == 0 ? 0 : paid / billed,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: const Color(0xFFE6ECE9),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartBar extends StatelessWidget {
  const ChartBar({
    super.key,
    required this.label,
    required this.value,
    required this.count,
    required this.color,
  });
  final String label;
  final double value;
  final int count;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: const Color(0xFFE6ECE9),
            color: color,
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

class Metric extends StatelessWidget {
  const Metric(this.icon, this.value, this.label, this.color, {super.key});
  final IconData icon;
  final String value, label;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    ),
  );
}

class ClientTile extends StatelessWidget {
  const ClientTile(this.client, this.refresh, {super.key});
  final Client client;
  final VoidCallback refresh;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE1F1EC),
        child: Text(
          '${client.due.day}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: brand),
        ),
      ),
      title: Text(
        client.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${date(client.due)} · ${client.docs} documentos'),
      trailing: Status(client.status),
      onTap: () => details(context, client, refresh),
    ),
  );
}

class Clients extends StatelessWidget {
  const Clients(this.clients, this.refresh, {super.key});
  final List<Client> clients;
  final VoidCallback refresh;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Buscar por nombre, cédula o NIT',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
          itemCount: clients.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final c = clients[i];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(child: Text(c.name[0])),
                title: Text(
                  c.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('NIT/CC ${c.nit}\nVence ${date(c.due)}'),
                isThreeLine: true,
                trailing: Status(c.status),
                onTap: () => details(context, c, refresh),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class Payments extends StatelessWidget {
  const Payments(this.clients, this.refresh, {super.key});
  final List<Client> clients;
  final VoidCallback refresh;
  @override
  Widget build(BuildContext context) {
    final paid = clients
            .where((c) => c.paid)
            .fold<double>(0, (s, c) => s + c.fee),
        debt = clients
            .where((c) => !c.paid)
            .fold<double>(0, (s, c) => s + c.fee);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'Estado de cuenta',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Metric(
                Icons.check_circle_outline,
                money(paid),
                'Pagado',
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Metric(
                Icons.schedule,
                money(debt),
                'Pendiente',
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Servicios',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...clients.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: SwitchListTile(
                value: c.paid,
                onChanged: (v) {
                  c.paid = v;
                  refresh();
                },
                title: Text(
                  c.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${money(c.fee)} · ${c.paid ? 'Pagado' : 'Por cobrar'}',
                ),
                secondary: Icon(
                  c.paid ? Icons.verified : Icons.pending_actions,
                  color: c.paid ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Settings extends StatelessWidget {
  const Settings(this.profile, this.onSave, {super.key});
  final AccountantProfile profile;
  final Future<void> Function(AccountantProfile) onSave;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Text(
        'Configuración',
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(
                profile.name.isEmpty
                    ? 'Completar perfil profesional'
                    : profile.name,
              ),
              subtitle: Text(
                profile.professionalId.isEmpty
                    ? 'Datos del contador y firma'
                    : '${profile.professionalId}${profile.firm.isEmpty ? '' : ' · ${profile.firm}'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => editAccountantProfile(context, profile, onSave),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.notifications_outlined),
              title: Text('Recordatorios'),
              subtitle: Text('Avisar 15, 7 y 2 días antes'),
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text('Seguridad'),
              subtitle: Text('PIN, biometría y respaldo seguro'),
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Acerca de ContaPlazo'),
              subtitle: Text('Versión 1.0.0'),
            ),
          ],
        ),
      ),
    ],
  );
}

Future<void> editAccountantProfile(
  BuildContext context,
  AccountantProfile current,
  Future<void> Function(AccountantProfile) onSave,
) async {
  final name = TextEditingController(text: current.name);
  final professionalId = TextEditingController(text: current.professionalId);
  final phone = TextEditingController(text: current.phone);
  final email = TextEditingController(text: current.email);
  final firm = TextEditingController(text: current.firm);
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Perfil profesional'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre completo *'),
            ),
            TextField(
              controller: professionalId,
              decoration: const InputDecoration(
                labelText: 'Tarjeta profesional o identificación',
              ),
            ),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
              ),
            ),
            TextField(
              controller: firm,
              decoration: const InputDecoration(
                labelText: 'Firma o despacho contable',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  if (saved == true && name.text.trim().isNotEmpty) {
    await onSave(
      AccountantProfile(
        name: name.text.trim(),
        professionalId: professionalId.text.trim(),
        phone: phone.text.trim(),
        email: email.text.trim(),
        firm: firm.text.trim(),
      ),
    );
  }
}

class Status extends StatelessWidget {
  const Status(this.status, {super.key});
  final TaxStatus status;
  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      TaxStatus.pending => ('Pendiente', Colors.orange),
      TaxStatus.progress => ('En proceso', Colors.blue),
      TaxStatus.filed => ('Presentada', Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Future<void> details(BuildContext context, Client c, VoidCallback refresh) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'NIT/CC ${c.nit}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('Fecha de presentación'),
                  subtitle: Text(date(c.due)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: c.due,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2035),
                      helpText: 'Seleccionar vencimiento',
                    );
                    if (selected != null) {
                      update(() => c.due = selected);
                      refresh();
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('Documentos registrados'),
                  subtitle: Text('${c.docs} archivos'),
                  trailing: IconButton(
                    tooltip: 'Agregar documento',
                    onPressed: () async {
                      final document = await pickAndStoreDocument(c);
                      if (document != null) {
                        update(() {
                          c.files.add(document);
                          c.docs = c.files.length;
                        });
                        refresh();
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ),
                if (c.files.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F6F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Agrega certificados, extractos, RUT, facturas o archivos PDF.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ...c.files.map(
                  (document) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE7F2EE),
                      child: Icon(documentIcon(document.name), color: brand),
                    ),
                    title: Text(
                      document.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(fileSize(document.size)),
                    onTap: () => OpenFilex.open(document.path),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'open') {
                          await OpenFilex.open(document.path);
                        } else if (value == 'delete') {
                          final confirmed = await confirmDelete(
                            context,
                            document.name,
                          );
                          if (confirmed &&
                              await deleteStoredDocument(document)) {
                            update(() {
                              c.files.remove(document);
                              c.docs = c.files.length;
                            });
                            refresh();
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'open', child: Text('Abrir')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ),
                ),
                DropdownButtonFormField<TaxStatus>(
                  initialValue: c.status,
                  decoration: const InputDecoration(
                    labelText: 'Estado de la declaración',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: TaxStatus.pending,
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(
                      value: TaxStatus.progress,
                      child: Text('En proceso'),
                    ),
                    DropdownMenuItem(
                      value: TaxStatus.filed,
                      child: Text('Presentada'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      update(() => c.status = v);
                      refresh();
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.request_quote_outlined),
                  title: const Text('Honorarios del contador'),
                  subtitle: Text(money(c.fee)),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () async {
                    final amount = await editFee(context, c.fee);
                    if (amount != null) {
                      update(() => c.fee = amount);
                      refresh();
                    }
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: c.paid,
                  title: const Text('Servicio pagado'),
                  subtitle: Text(money(c.fee)),
                  onChanged: (v) {
                    update(() => c.paid = v);
                    refresh();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

Future<double?> editFee(BuildContext context, double current) async {
  final controller = TextEditingController(
    text: current == 0 ? '' : current.toStringAsFixed(0),
  );
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Editar honorarios'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Valor del servicio',
          prefixText: '\$ ',
          helperText: 'Ingresa el valor en pesos colombianos',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  if (accepted != true) return null;
  final normalized = controller.text.replaceAll('.', '').replaceAll(',', '.');
  final amount = double.tryParse(normalized);
  return amount != null && amount >= 0 ? amount : null;
}

Future<Directory> clientDirectory(Client client) async {
  final root = await getApplicationDocumentsDirectory();
  final safeId = client.nit.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  return Directory(
    '${root.path}${Platform.pathSeparator}contaplazo_documents${Platform.pathSeparator}$safeId',
  );
}

Future<StoredDocument?> pickAndStoreDocument(Client client) async {
  final selection = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: [
      'pdf',
      'jpg',
      'jpeg',
      'png',
      'doc',
      'docx',
      'xls',
      'xlsx',
    ],
  );
  if (selection == null) return null;
  final directory = await clientDirectory(client);
  await directory.create(recursive: true);
  var name = selection.name;
  var destination = File('${directory.path}${Platform.pathSeparator}$name');
  if (await destination.exists()) {
    name = '${DateTime.now().millisecondsSinceEpoch}_$name';
    destination = File('${directory.path}${Platform.pathSeparator}$name');
  }
  final saved = await destination.writeAsBytes(await selection.readAsBytes());
  final stat = await saved.stat();
  return StoredDocument(name, saved.path, stat.size, stat.modified);
}

Future<bool> deleteStoredDocument(StoredDocument document) async {
  final file = File(document.path);
  if (await file.exists()) await file.delete();
  return true;
}

Future<bool> confirmDelete(BuildContext context, String name) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text('¿Deseas eliminar permanentemente “$name”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ??
    false;

IconData documentIcon(String name) {
  final extension = name.split('.').last.toLowerCase();
  if (extension == 'pdf') return Icons.picture_as_pdf_outlined;
  if (['jpg', 'jpeg', 'png'].contains(extension)) return Icons.image_outlined;
  if (['xls', 'xlsx'].contains(extension)) return Icons.table_chart_outlined;
  return Icons.description_outlined;
}

String fileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String money(double n) =>
    '\$${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
