import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class CloudRepository {
  CloudRepository._();

  static final instance = CloudRepository._();
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  bool enabled = false;
  String? initializationError;

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => enabled ? _client.auth.currentUser?.id : null;

  Future<void> initialize() async {
    if (_url.isEmpty || _publishableKey.isEmpty) return;
    try {
      await Supabase.initialize(url: _url, publishableKey: _publishableKey);
      if (_client.auth.currentSession == null) {
        await _client.auth.signInAnonymously();
      }
      enabled = _client.auth.currentUser != null;
    } catch (error) {
      initializationError = error.toString();
      enabled = false;
    }
  }

  Future<void> syncClients(List<Map<String, Object?>> clients) async {
    final userId = _userId;
    if (userId == null || clients.isEmpty) return;
    final rows = clients
        .map(
          (client) => {
            ...client,
            'user_id': userId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        )
        .toList();
    await _client.from('clients').upsert(rows, onConflict: 'user_id,nit');
  }

  Future<void> syncAccountant(Map<String, Object?> profile) async {
    final userId = _userId;
    if (userId == null) return;
    await _client.from('accountant_profiles').upsert({
      ...profile,
      'user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> uploadDocument({
    required String clientId,
    required String name,
    required String localPath,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    final objectPath = '$userId/${_safe(clientId)}/${_safeFileName(name)}';
    await _client.storage
        .from('client-documents')
        .upload(
          objectPath,
          File(localPath),
          fileOptions: const FileOptions(upsert: true),
        );
  }

  Future<void> deleteDocument({
    required String clientId,
    required String name,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    final objectPath = '$userId/${_safe(clientId)}/${_safeFileName(name)}';
    await _client.storage.from('client-documents').remove([objectPath]);
  }

  String _safe(String value) => value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  String _safeFileName(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
}
