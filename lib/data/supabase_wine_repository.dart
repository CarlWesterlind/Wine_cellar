import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tasting_note.dart';
import '../models/wine.dart';
import 'wine_repository.dart';

/// Stores wines and tasting notes in the Supabase `wines` and
/// `tasting_notes` tables. Row level security limits every query to the
/// signed-in user's rows.
class SupabaseWineRepository implements WineRepository {
  SupabaseWineRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('wines');
  SupabaseQueryBuilder get _notes => _client.from('tasting_notes');

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
}
