import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/wine.dart';
import 'wine_repository.dart';

/// Stores wines in the Supabase `wines` table. Row level security limits
/// every query to the signed-in user's rows.
class SupabaseWineRepository implements WineRepository {
  SupabaseWineRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('wines');

  @override
  Future<List<Wine>> fetchAll() async {
    final rows = await _table.select().order('name');
    return rows.map(Wine.fromMap).toList();
  }

  @override
  Future<Wine> add(Wine wine) async {
    final row = await _table.insert(wine.toMap()).select().single();
    return Wine.fromMap(row);
  }

  @override
  Future<Wine> update(Wine wine) async {
    final row = await _table
        .update(wine.toMap())
        .eq('id', wine.id!)
        .select()
        .single();
    return Wine.fromMap(row);
  }

  @override
  Future<void> delete(String id) => _table.delete().eq('id', id);
}
