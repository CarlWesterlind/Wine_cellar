import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/consumed_bottle.dart';
import '../models/rack.dart';
import '../models/tasting_note.dart';
import '../models/wine.dart';
import 'wine_repository.dart';

/// Stores wines, tasting notes, history and racks in the Supabase `wines`,
/// `tasting_notes`, `consumed_bottles` and `racks` tables. Row level security limits every query to the
/// signed-in user's rows.
class SupabaseWineRepository implements WineRepository {
  SupabaseWineRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('wines');
  SupabaseQueryBuilder get _notes => _client.from('tasting_notes');
  SupabaseQueryBuilder get _history => _client.from('consumed_bottles');
  SupabaseQueryBuilder get _racks => _client.from('racks');

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

  /// Notes are deleted along with their wine by the database
  /// (`on delete cascade`).
  @override
  Future<List<TastingNote>> fetchNotes(String wineId) async {
    final rows = await _notes
        .select()
        .eq('wine_id', wineId)
        .order('created_at');
    return rows.map(TastingNote.fromMap).toList();
  }

  @override
  Future<TastingNote> addNote(TastingNote note) async {
    final row = await _notes.insert(note.toMap()).select().single();
    return TastingNote.fromMap(row);
  }

  @override
  Future<TastingNote> updateNote(TastingNote note) async {
    final row = await _notes
        .update(note.toMap())
        .eq('id', note.id!)
        .select()
        .single();
    return TastingNote.fromMap(row);
  }

  @override
  Future<void> deleteNote(String id) => _notes.delete().eq('id', id);

  /// History is deleted along with its wine by the database.
  @override
  Future<List<ConsumedBottle>> fetchHistory() async {
    final rows = await _history.select().order('created_at');
    return rows.map(ConsumedBottle.fromMap).toList();
  }

  @override
  Future<ConsumedBottle> addConsumed(ConsumedBottle bottle) async {
    final row = await _history.insert(bottle.toMap()).select().single();
    return ConsumedBottle.fromMap(row);
  }

  @override
  Future<void> deleteConsumed(String id) => _history.delete().eq('id', id);

  @override
  Future<List<Rack>> fetchRacks() async {
    final rows = await _racks.select().order('name');
    return rows.map(Rack.fromMap).toList();
  }

  @override
  Future<Rack> addRack(Rack rack) async {
    final row = await _racks.insert(rack.toMap()).select().single();
    return Rack.fromMap(row);
  }

  @override
  Future<Rack> updateRack(Rack rack) async {
    final row = await _racks
        .update(rack.toMap())
        .eq('id', rack.id!)
        .select()
        .single();
    return Rack.fromMap(row);
  }

  @override
  Future<void> deleteRack(String id) => _racks.delete().eq('id', id);
}
