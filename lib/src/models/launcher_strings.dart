/// English launcher text that a host can replace with its own translations.
class LauncherStrings {
  /// Creates the default English text set.
  const LauncherStrings({
    this.cancel = 'Cancel',
    this.ok = 'OK',
    this.save = 'Save',
    this.delete = 'Delete',
    this.back = 'Back',
    this.empty = 'No tiles',
    this.emptySubtitle = 'Add a tile to get started',
    this.folderEmpty = 'Empty folder',
    this.reorderHint =
        "Drag onto a tile's center to group into a folder, or its edge to reorder",
    this.exitReorder = 'Exit Reorder Mode',
    this.dropGroup = 'Group with this tile',
    this.dropReorder = 'Place here',
    this.createFolderTitle = 'New Folder',
    this.createFolderHint = 'Folder name',
    this.addToFolderConfirm = 'Add this tile to the folder?',
    this.moveOutOfFolder = 'Move out of folder',
    this.editTile = 'Edit Tile',
    this.nameLabel = 'Tile name',
    this.nameHint = 'Enter tile name',
    this.settingsSection = 'Settings',
    this.pickIcon = 'Pick Icon',
    this.pickBackgroundColor = 'Pick Background Color',
    this.pickFontColor = 'Pick Font Color',
    this.pickIconColor = 'Pick Icon Color',
    this.returnToLauncherOnBack = 'Return to launcher on back',
    this.pinTile = 'Pin tile',
    this.moveToFolder = 'Move to folder',
    this.deleteTile = 'Delete Tile',
    this.deleteConfirm = 'Are you sure you want to delete this tile?',
    this.unsavedTitle = 'Unsaved changes',
    this.unsavedMessage = 'You have unsaved changes. Save them before leaving?',
    this.unsavedDiscard = 'Discard',
    this.useThisFolder = 'Use this folder',
    this.rootLevel = 'Root level',
    this.folderSearchHint = 'Search folders...',
    this.iconPickerTitle = 'Choose an Icon',
    this.iconPickerSearch = 'Search icons...',
    this.iconPickerAll = 'All',
    this.iconPickerSolid = 'Solid',
    this.iconPickerRegular = 'Regular',
    this.iconPickerBrands = 'Brands',
    this.iconPickerCount = '{count} icons',
    this.clearSearch = 'Clear search',
    this.copyHex = 'Copy hex',
    this.pasteHex = 'Paste hex',
    this.colorCopied = 'Color copied to clipboard',
    this.invalidHex = 'No valid hex color on clipboard',
    this.folderItemCount = '{count} items',
    this.filterHint = 'Filter tiles...',
  });

  /// Common action labels.
  final String cancel, ok, save, delete, back;

  /// Empty-state labels.
  final String empty, emptySubtitle, folderEmpty;

  /// Reorder labels.
  final String reorderHint, exitReorder, dropGroup, dropReorder;

  /// Folder action labels.
  final String createFolderTitle,
      createFolderHint,
      addToFolderConfirm,
      moveOutOfFolder;

  /// Editor labels.
  final String editTile, nameLabel, nameHint, settingsSection;

  /// Picker action labels.
  final String pickIcon, pickBackgroundColor, pickFontColor, pickIconColor;

  /// Tile option labels.
  final String returnToLauncherOnBack, pinTile, moveToFolder;

  /// Delete labels.
  final String deleteTile, deleteConfirm;

  /// Unsaved-change labels.
  final String unsavedTitle, unsavedMessage, unsavedDiscard;

  /// Folder picker labels.
  final String useThisFolder, rootLevel, folderSearchHint;

  /// Icon picker labels.
  final String iconPickerTitle,
      iconPickerSearch,
      iconPickerAll,
      iconPickerSolid,
      iconPickerRegular,
      iconPickerBrands,
      iconPickerCount,
      clearSearch;

  /// Color picker labels.
  final String copyHex, pasteHex, colorCopied, invalidHex;

  /// Folder count semantic template.
  final String folderItemCount;

  /// Filter field hint.
  final String filterHint;
}
