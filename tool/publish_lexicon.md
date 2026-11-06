# Publishing a lexicon update

Apps check the public `lexicon` bucket in Supabase once a day and use a
newer lexicon without an app release.

1. Edit the files in `tool/lexicon/`.
2. Raise `lexiconVersion` in `tool/build_lexicon.dart` by one.
3. Build and test:

   ```bash
   dart run tool/build_lexicon.dart
   flutter test test/lexicon_data_test.dart
   ```

4. Create `version.json` with the same numbers:

   ```json
   {"format": 1, "version": 2}
   ```

5. Upload both files to the `lexicon` bucket (Supabase dashboard → Storage
   → lexicon → Upload, replacing the old files), `lexicon.json` first and
   `version.json` last, so no app sees a version number before its file.
6. Commit the changes, so the next app release ships the same lexicon.
