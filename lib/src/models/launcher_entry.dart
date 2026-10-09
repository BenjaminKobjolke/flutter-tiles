import 'dart:convert';

/// Persisted metadata for a launcher tile entry.
///
/// Tracks the tile's folder path, label, action type, icon name,
/// background color (ARGB32), sort order, and creation timestamp.
/// Used for the in-app launcher grid and backup/restore.
class LauncherEntry {
  /// Action string marking a tile as a folder that groups other tiles.
  ///
  /// A folder tile is a normal [LauncherEntry] with `action == folderAction`;
  /// its members reference it via [parentId]. Launcher-only (not a registered
  /// shortcut type) — tapping it opens a sub-grid instead of firing an intent.
  static const String folderAction = 'launcherFolder';

  /// Unique identifier (microsecondsSinceEpoch).
  final String id;

  /// The folder (or SAF URI) the tile opens.
  final String folderPath;

  /// User-visible tile label.
  final String label;

  /// Action type string (e.g. "openFolder", "takePhoto", "recordVideo", "openFile").
  final String action;

  /// Optional file path for "openFile" tiles.
  final String? filePath;

  /// Font Awesome field name (e.g. "folder", "camera").
  final String iconName;

  /// Tile background color as ARGB32 int.
  final int backgroundColor;

  /// Label font color as ARGB32 int.
  final int fontColor;

  /// Icon glyph color as ARGB32 int.
  final int iconColor;

  /// Manual reorder position.
  final int sortOrder;

  /// Creation timestamp in milliseconds since epoch.
  final int createdAtMs;

  /// Extra data for the shortcut (e.g., QR preset ID).
  final Map<String, String> extras;

  /// Optional base64-encoded PNG bytes used in place of [iconName].
  ///
  /// Set when the tile adopts an external icon (e.g. an installed app's
  /// launcher icon). When non-null, the tile widget renders this image and
  /// ignores the Font Awesome icon name.
  final String? customIconBase64;

  /// Whether pressing the system back button after this tile's action should
  /// return to the launcher tab.
  ///
  /// Defaults to `true`. For `openFolder` tiles, back first walks up to the
  /// tile's origin folder, then returns to the launcher. For tiles that push a
  /// route (camera, QR, internal viewer, media scanner), closing that route
  /// returns to the launcher. Has no effect when the action hands off to an
  /// external app (the OS controls back).
  final bool returnToLauncherOnBack;

  /// Id of the folder tile this entry belongs to, or `null` for the top level.
  ///
  /// Folders nest arbitrarily: a folder tile may itself carry a [parentId].
  final String? parentId;

  /// Whether this tile is pinned. Pinned tiles are ordered before unpinned ones
  /// at their level regardless of the active sort mode; within the pinned group
  /// they keep their manual `sortOrder` (so drag-reorder still orders them).
  /// Applies per level, including inside folders.
  final bool pinned;

  /// Whether this entry is a folder that groups other tiles.
  bool get isFolder => action == folderAction;

  /// Creates a [LauncherEntry] with the given metadata.
  const LauncherEntry({
    required this.id,
    required this.folderPath,
    required this.label,
    required this.action,
    this.filePath,
    required this.iconName,
    required this.backgroundColor,
    this.fontColor = 0xFFFFFFFF,
    this.iconColor = 0xFFFFFFFF,
    required this.sortOrder,
    required this.createdAtMs,
    this.extras = const {},
    this.customIconBase64,
    this.returnToLauncherOnBack = true,
    this.parentId,
    this.pinned = false,
  });

  /// Creates a [LauncherEntry] from a JSON-decoded map.
  factory LauncherEntry.fromMap(Map<String, dynamic> map) {
    return LauncherEntry(
      id: map['id'] as String,
      folderPath: map['folderPath'] as String,
      label: map['label'] as String,
      action: map['action'] as String,
      filePath: map['filePath'] as String?,
      iconName: map['iconName'] as String,
      backgroundColor: map['backgroundColor'] as int,
      fontColor: map['fontColor'] as int? ?? 0xFFFFFFFF,
      iconColor: map['iconColor'] as int? ?? 0xFFFFFFFF,
      sortOrder: map['sortOrder'] as int,
      createdAtMs: map['createdAtMs'] as int,
      extras: map['extras'] != null
          ? Map<String, String>.from(map['extras'] as Map)
          : const {},
      customIconBase64: map['customIconBase64'] as String?,
      returnToLauncherOnBack: map['returnToLauncherOnBack'] as bool? ?? true,
      parentId: map['parentId'] as String?,
      pinned: map['pinned'] as bool? ?? false,
    );
  }

  /// Creates a [LauncherEntry] from a JSON string.
  factory LauncherEntry.fromJson(String source) {
    return LauncherEntry.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  /// Serializes this entry to a JSON-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderPath': folderPath,
      'label': label,
      'action': action,
      'filePath': filePath,
      'iconName': iconName,
      'backgroundColor': backgroundColor,
      'fontColor': fontColor,
      'iconColor': iconColor,
      'sortOrder': sortOrder,
      'createdAtMs': createdAtMs,
      if (extras.isNotEmpty) 'extras': extras,
      if (customIconBase64 != null) 'customIconBase64': customIconBase64,
      // Only persisted when off, since true is the default on decode.
      if (!returnToLauncherOnBack) 'returnToLauncherOnBack': false,
      // Only persisted for tiles nested in a folder; null (top level) omitted.
      if (parentId != null) 'parentId': parentId,
      // Only persisted when pinned, since false is the default on decode.
      if (pinned) 'pinned': true,
    };
  }

  /// Serializes this entry to a JSON string.
  String toJson() => jsonEncode(toMap());

  /// Creates a copy of this entry with the given fields replaced.
  LauncherEntry copyWith({
    String? id,
    String? folderPath,
    String? label,
    String? action,
    String? filePath,
    String? iconName,
    int? backgroundColor,
    int? fontColor,
    int? iconColor,
    int? sortOrder,
    int? createdAtMs,
    Map<String, String>? extras,
    String? customIconBase64,
    bool? returnToLauncherOnBack,
    String? parentId,
    bool clearParent = false,
    bool? pinned,
  }) {
    return LauncherEntry(
      id: id ?? this.id,
      folderPath: folderPath ?? this.folderPath,
      label: label ?? this.label,
      action: action ?? this.action,
      filePath: filePath ?? this.filePath,
      iconName: iconName ?? this.iconName,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontColor: fontColor ?? this.fontColor,
      iconColor: iconColor ?? this.iconColor,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      extras: extras ?? this.extras,
      customIconBase64: customIconBase64 ?? this.customIconBase64,
      returnToLauncherOnBack:
          returnToLauncherOnBack ?? this.returnToLauncherOnBack,
      // Pass clearParent to eject a tile back to the top level, since the
      // `?? this.parentId` idiom cannot otherwise set it back to null.
      parentId: clearParent ? null : (parentId ?? this.parentId),
      pinned: pinned ?? this.pinned,
    );
  }

  /// Equality is based on [id] only.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LauncherEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
