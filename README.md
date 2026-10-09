# flutter_tiles

A reusable Flutter launcher grid with colored icon tiles, folders, badges, drag reorder, filtering, an editor, and SharedPreferences storage. Tile actions belong to the host app.

## Setup

Use FVM with Flutter 3.44.1 (Dart 3.9.2 or newer within Dart 3). On Windows, `install.bat` installs the FVM version and fetches package dependencies. To use this checkout from a sibling app, add:

```yaml
dependencies:
  flutter_tiles:
    path: ../flutter-tiles
```

Then run `fvm flutter pub get` in the host app. The example app has its own dependency on the package at `../`.

## Usage

Create a store on the key your app owns, load a cubit, and put the view below a `BlocProvider`. This is the core of [the example app](example/lib/main.dart):

```dart
final prefs = await SharedPreferences.getInstance();
final store = LauncherStore(prefs: prefs, key: 'example_tiles');
final cubit = LauncherCubit(store: store)..loadEntries();

BlocProvider.value(
  value: cubit,
  child: LauncherView(
    filterQuery: query,
    bottomBuilder: (context, count) => LauncherFilterField(
      query: query,
      onChanged: (value) => setState(() => query = value),
    ),
    onTileTap: (entry) {
      if (entry.isFolder) {
        cubit.openFolder(entry.id);
      } else {
        handleTileAction(entry.action, entry.extras);
      }
    },
  ),
)
```

`handleTileAction` is your app's action handler. Close the cubit when its owning screen is disposed. Call `cubit.closeFolder()` from your app's back navigation when a folder is open. The package reports folder taps to `onTileTap`; the host chooses when to open one.

Optional host hooks let you keep your app's presentation:

- `LauncherEditorConfig.bodyBuilder` wraps the editor body; the host owns safe-area handling when set.
- `ColorPickerHelper.showColorPicker(onMessage:)` and `LauncherEditorConfig.onColorPickerMessage` show copy/paste feedback through the host; `isError` distinguishes invalid paste from successful copy.
- `LauncherView.emptyStateBuilder` builds the empty view for `LauncherEmptyCase.noTiles`, `emptyFolder`, or `noMatches`.

## Host inputs

| Input | What the host controls |
| --- | --- |
| `LauncherStyle` | Columns, spacing, label and badge appearance, and highlight color. |
| `LauncherStrings` | Text shown by the grid, dialogs, editor, and pickers; English defaults are built in. |
| `LauncherSort`, `usageCounts` | Display order and counts for most-used sorting. Pinning takes precedence. |
| `filterQuery`, `bottomBuilder` | Name filter and a bottom widget; the builder receives the visible tile count. The included `LauncherFilterField` is optional. |
| `LauncherEditorConfig` | Optional host settings section, return-to-launcher switch, editor `bodyBuilder`, and `onColorPickerMessage`. |
| `emptyStateBuilder` | Host empty state for top-level emptiness, an empty folder, or no filter matches. |
| `onTileTap` | Action for regular tiles and folder tiles; folder opening is a host job. |
| `onExitReorder`, `onBackgroundLongPress`, `onTileUpdated`, `onTileDeleted` | Host navigation and feedback hooks. |

Use `LauncherCubit.addEntry` to add a tile. Long-press a tile to edit its name, icon, colors, pin, or folder. Use reorder mode to drag tiles into order or folders. While reordering, the full current folder is visible even if the host has a filter query.

## Storage

`LauncherStore` saves a JSON list in `SharedPreferences`. Its default key is `launcher_entries`, matching the Media File Explorer launcher and its backup format. Set `key` to another value to keep an app's tiles separate, as the example does with `example_tiles`. Entry field names and their stored JSON format remain compatible with the existing app. The package does not choose what an entry's `action` string means.

## Run and test

From this repository on Windows:

```text
install.bat
tools\run_tests.bat
tools\run_integration_tests.bat
```

`tools\run_tests.bat` runs the package unit tests and the example test. `tools\run_integration_tests.bat` runs the package integration tests. To run the example, use `fvm flutter run -d windows` or a connected Android device from `example/`. Use `update.bat` to refresh dependencies. Regenerate the bundled Font Awesome icon list with `fvm dart run tools/generate_icon_map.dart`.

## Dependencies

The package uses `flutter_bloc`, `shared_preferences`, `flutter_colorpicker`, and `font_awesome_flutter`. The example also depends directly on `flutter_bloc` and `shared_preferences` for its host wiring.
