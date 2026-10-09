import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tiles/flutter_tiles.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const TilesExampleApp());

/// Small host app showing how to supply storage and tile actions.
class TilesExampleApp extends StatelessWidget {
  /// Creates the example app.
  const TilesExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter Tiles',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const _TilesScreen(),
  );
}

class _TilesScreen extends StatefulWidget {
  const _TilesScreen();

  @override
  State<_TilesScreen> createState() => _TilesScreenState();
}

class _TilesScreenState extends State<_TilesScreen> {
  LauncherCubit? _cubit;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = LauncherStore(prefs: prefs, key: 'example_tiles');
    if (store.getRaw() == null) {
      await store.setEntries(const [
        LauncherEntry(
          id: 'photos',
          folderPath: '',
          label: 'Photos',
          action: 'demo',
          iconName: 'image',
          backgroundColor: 0xFF3F51B5,
          sortOrder: 0,
          createdAtMs: 0,
        ),
        LauncherEntry(
          id: 'music',
          folderPath: '',
          label: 'Music',
          action: 'demo',
          iconName: 'music',
          backgroundColor: 0xFF00897B,
          sortOrder: 1,
          createdAtMs: 0,
        ),
        LauncherEntry(
          id: 'notes',
          folderPath: '',
          label: 'Notes',
          action: 'demo',
          iconName: 'noteSticky',
          backgroundColor: 0xFFEF6C00,
          sortOrder: 2,
          createdAtMs: 0,
        ),
        LauncherEntry(
          id: 'favorites',
          folderPath: '',
          label: 'Favorites',
          action: LauncherEntry.folderAction,
          iconName: 'folder',
          backgroundColor: 0xFF8E24AA,
          sortOrder: 3,
          createdAtMs: 0,
        ),
        LauncherEntry(
          id: 'camera',
          folderPath: '',
          label: 'Camera',
          action: 'demo',
          iconName: 'camera',
          backgroundColor: 0xFF00796B,
          sortOrder: 4,
          createdAtMs: 0,
          parentId: 'favorites',
        ),
      ]);
    }
    final cubit = LauncherCubit(store: store)..loadEntries();
    if (!mounted) {
      await cubit.close();
      return;
    }
    setState(() => _cubit = cubit);
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _open(LauncherEntry entry) {
    if (entry.isFolder) {
      setState(() => _query = '');
      _cubit!.openFolder(entry.id);
    } else {
      _message('Opened ${entry.label}');
    }
  }

  Future<void> _addTile() async {
    final cubit = _cubit!;
    final now = DateTime.now();
    final state = cubit.state as LauncherLoaded;
    await cubit.addEntry(
      LauncherEntry(
        id: now.microsecondsSinceEpoch.toString(),
        folderPath: '',
        label: 'New Tile',
        action: 'demo',
        iconName: 'star',
        backgroundColor: 0xFF3949AB,
        sortOrder: state.allEntries.length,
        createdAtMs: now.millisecondsSinceEpoch,
        parentId: state.openFolderId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<LauncherCubit, LauncherState>(
        builder: (context, state) {
          final openFolder = state is LauncherLoaded
              ? state.allEntries
                    .where((entry) => entry.id == state.openFolderId)
                    .firstOrNull
              : null;
          final insideFolder = openFolder != null;
          return PopScope(
            canPop: !insideFolder,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && insideFolder) cubit.closeFolder();
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(openFolder?.label ?? 'Flutter Tiles'),
                leading: insideFolder
                    ? BackButton(onPressed: cubit.closeFolder)
                    : null,
                actions: [
                  IconButton(
                    tooltip: 'Add tile',
                    icon: const Icon(Icons.add),
                    onPressed: _addTile,
                  ),
                  IconButton(
                    tooltip: 'Reorder',
                    icon: const Icon(Icons.swap_vert),
                    onPressed: cubit.toggleReorderMode,
                  ),
                ],
              ),
              body: LauncherView(
                filterQuery: _query,
                bottomBuilder: (context, count) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: LauncherFilterField(
                    query: _query,
                    onChanged: (query) => setState(() => _query = query),
                  ),
                ),
                onTileTap: _open,
                onTileUpdated: (entry) => _message('Updated ${entry.label}'),
                onTileDeleted: (entry) => _message('Deleted ${entry.label}'),
              ),
            ),
          );
        },
      ),
    );
  }
}
