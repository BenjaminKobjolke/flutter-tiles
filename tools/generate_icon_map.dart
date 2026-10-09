/// Generator script that parses the font_awesome_flutter package source
/// and produces a Dart file with all non-deprecated icons.
///
/// Usage:
///   dart run tools/generate_icon_map.dart
///
/// Output:
///   lib/src/generated/font_awesome_all_icons.dart
library;

import 'dart:io';

/// Represents a parsed icon entry from the source file.
class ParsedIcon {
  final String fieldName;
  final String displayName;
  final String category; // 'solid', 'regular', 'brands'
  final String constructorCall; // raw IconData(...) literal for the glyph
  final List<String> searchKeywords;

  ParsedIcon({
    required this.fieldName,
    required this.displayName,
    required this.category,
    required this.constructorCall,
    required this.searchKeywords,
  });
}

/// Convert camelCase field name to display name.
/// e.g. 'folderOpen' -> 'folder open'
/// e.g. 'solidAddressBook' -> 'address book'
String camelCaseToDisplayName(String fieldName, String category) {
  // Strip category prefix for solid/regular that use prefixed names
  var name = fieldName;
  if (category == 'solid' && name.startsWith('solid') && name.length > 5) {
    name = name[5].toLowerCase() + name.substring(6);
  }

  // Insert space before each uppercase letter
  final buffer = StringBuffer();
  for (var i = 0; i < name.length; i++) {
    final char = name[i];
    if (i > 0 && char.toUpperCase() == char && char.toLowerCase() != char) {
      buffer.write(' ');
      buffer.write(char.toLowerCase());
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

/// Determine the category from the icon's font family.
///
/// font_awesome_flutter 11 uses font families like `FontAwesomeSolid`,
/// `FontAwesomeRegular`, and `FontAwesomeBrands`.
String getCategory(String fontFamily) {
  if (fontFamily.contains('Solid')) return 'solid';
  if (fontFamily.contains('Regular')) return 'regular';
  if (fontFamily.contains('Brands')) return 'brands';
  return 'unknown';
}

/// Extract search keywords from the doc comment line containing keywords.
/// e.g. '  /// Digit Zero, nada, none, zero, zilch' -> ['digit zero', 'nada', 'none', 'zero', 'zilch']
List<String> extractKeywords(String? keywordLine) {
  if (keywordLine == null) return [];
  // Remove the /// prefix
  final content = keywordLine.replaceFirst(RegExp(r'^\s*///\s*'), '');
  if (content.isEmpty) return [];
  return content
      .split(',')
      .map((s) => s.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toList();
}

void main() {
  // Find the source file
  final pubCachePath =
      Platform.environment['PUB_CACHE'] ??
      (Platform.isWindows
          ? '${Platform.environment['LOCALAPPDATA']}\\Pub\\Cache'
          : '${Platform.environment['HOME']}/.pub-cache');

  final sourceFile = File(
    '$pubCachePath${Platform.pathSeparator}hosted${Platform.pathSeparator}pub.dev${Platform.pathSeparator}font_awesome_flutter-11.0.0${Platform.pathSeparator}lib${Platform.pathSeparator}font_awesome_flutter.dart',
  );

  if (!sourceFile.existsSync()) {
    stderr.writeln('ERROR: Could not find font_awesome_flutter.dart at:');
    stderr.writeln('  ${sourceFile.path}');
    stderr.writeln('Make sure the package is in your pub cache.');
    exit(1);
  }

  print('Reading ${sourceFile.path}...');
  final lines = sourceFile.readAsLinesSync();
  print('Read ${lines.length} lines.');

  // Parse all non-deprecated icon declarations.
  //
  // font_awesome_flutter 11 declares each icon across several lines, e.g.:
  //
  //   static const FaIconData zero = FaIconData(
  //     IconData(
  //       0x30,
  //       fontFamily: 'FontAwesomeSolid',
  //       fontPackage: 'font_awesome_flutter',
  //     ),
  //   );
  //
  // Deprecated aliases (`static const FaIconData innosoft = fortyTwoGroup;`)
  // and duotone icons (`FaDuotoneIconData`) are skipped.
  final icons = <ParsedIcon>[];
  final fieldPattern = RegExp(
    r'^\s*static\s+const\s+FaIconData\s+(\w+)\s*=\s*FaIconData\(\s*$',
  );
  final codePointPattern = RegExp(r'(0x[0-9a-fA-F]+)');
  final fontFamilyPattern = RegExp(r"fontFamily:\s*'([^']+)'");
  final fontPackagePattern = RegExp(r"fontPackage:\s*'([^']+)'");

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Skip deprecated entries (look for @Deprecated annotation above)
    if (i > 0 && lines[i - 1].contains('@Deprecated')) continue;
    // Also check 2 lines above (in case there's a blank line)
    if (i > 1 &&
        lines[i - 1].trim().isEmpty &&
        lines[i - 2].contains('@Deprecated'))
      continue;

    final match = fieldPattern.firstMatch(line);
    if (match == null) continue;

    final fieldName = match.group(1)!;

    // Collect the inner IconData(...) fields from the following lines.
    final window = lines.skip(i + 1).take(6).join('\n');
    final codePoint = codePointPattern.firstMatch(window)?.group(1);
    final fontFamily = fontFamilyPattern.firstMatch(window)?.group(1);
    final fontPackage = fontPackagePattern.firstMatch(window)?.group(1);
    if (codePoint == null || fontFamily == null) continue;

    final category = getCategory(fontFamily);
    if (category == 'unknown') continue;

    // Build a flat, const IconData literal for the glyph.
    final packagePart = fontPackage != null
        ? ", fontPackage: '$fontPackage'"
        : '';
    final constructorCall =
        "IconData($codePoint, fontFamily: '$fontFamily'$packagePart)";

    // Look for keywords in doc comments above this declaration.
    // Pattern:
    //   /// Solid Address Book icon           <- title line (i-4 or i-3)
    //   ///                                    <- blank doc line
    //   /// https://fontawesome.com/...        <- URL line
    //   /// keyword1, keyword2, ...            <- keyword line (i-1)
    //   static const IconData ...             <- current line (i)
    List<String> keywords = [];
    String docTitle = '';

    // Find the keyword line: it's the line just before the declaration
    // that starts with /// and contains commas (keywords)
    if (i >= 1) {
      final prevLine = lines[i - 1].trim();
      if (prevLine.startsWith('///') && !prevLine.contains('fontawesome.com')) {
        keywords = extractKeywords(lines[i - 1]);
      }
    }

    // Find the title line (e.g. "/// Solid Address Book icon")
    for (var j = i - 1; j >= i - 5 && j >= 0; j--) {
      final docLine = lines[j].trim();
      if (docLine.endsWith('icon') && docLine.startsWith('///')) {
        // Extract title: "/// Solid Address Book icon" -> "address book"
        var title = docLine
            .replaceFirst(RegExp(r'^\s*///\s*'), '')
            .replaceFirst(RegExp(r'\s+icon$'), '');
        // Remove category prefix
        title = title
            .replaceFirst(RegExp(r'^Solid\s+', caseSensitive: false), '')
            .replaceFirst(RegExp(r'^Regular\s+', caseSensitive: false), '')
            .replaceFirst(RegExp(r'^Brands\s+', caseSensitive: false), '');
        docTitle = title.toLowerCase();
        break;
      }
    }

    // Add title as keyword if not already present
    if (docTitle.isNotEmpty && !keywords.contains(docTitle)) {
      keywords.insert(0, docTitle);
    }

    final displayName = camelCaseToDisplayName(fieldName, category);

    icons.add(
      ParsedIcon(
        fieldName: fieldName,
        displayName: displayName,
        category: category,
        constructorCall: constructorCall,
        searchKeywords: keywords,
      ),
    );
  }

  print('Found ${icons.length} icons:');
  print('  Solid: ${icons.where((i) => i.category == 'solid').length}');
  print('  Regular: ${icons.where((i) => i.category == 'regular').length}');
  print('  Brands: ${icons.where((i) => i.category == 'brands').length}');

  // Generate the output file
  final outputDir = Directory('lib/src/generated');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
    print('Created directory: ${outputDir.path}');
  }

  final output = StringBuffer();
  output.writeln('// GENERATED FILE - DO NOT EDIT');
  output.writeln('// Generated by: dart run tools/generate_icon_map.dart');
  output.writeln('// Source: font_awesome_flutter 11.0.0');
  output.writeln('// ignore_for_file: constant_identifier_names');
  output.writeln();
  output.writeln("import 'package:flutter/widgets.dart';");
  output.writeln();

  // Enum
  output.writeln('/// Category of a Font Awesome icon.');
  output.writeln('enum FaIconCategory {');
  output.writeln('  /// Solid style icon.');
  output.writeln('  solid,');
  output.writeln('  /// Regular style icon.');
  output.writeln('  regular,');
  output.writeln('  /// Brand logo icon.');
  output.writeln('  brands,');
  output.writeln('}');
  output.writeln();

  // FaIconEntry class
  output.writeln(
    '/// A single Font Awesome icon entry with metadata for search and display.',
  );
  output.writeln('class FaIconEntry {');
  output.writeln('  /// Human-readable icon name.');
  output.writeln('  final String displayName;');
  output.writeln('  /// Font Awesome field name used to resolve the icon.');
  output.writeln('  final String fieldName;');
  output.writeln('  /// Font Awesome glyph data.');
  output.writeln('  final IconData iconData;');
  output.writeln('  /// Font Awesome category for filtering.');
  output.writeln('  final FaIconCategory category;');
  output.writeln('  /// Search terms associated with the icon.');
  output.writeln('  final List<String> searchKeywords;');
  output.writeln();
  output.writeln('  /// Creates icon metadata for the picker.');
  output.writeln('  const FaIconEntry({');
  output.writeln('    required this.displayName,');
  output.writeln('    required this.fieldName,');
  output.writeln('    required this.iconData,');
  output.writeln('    required this.category,');
  output.writeln('    required this.searchKeywords,');
  output.writeln('  });');
  output.writeln('}');
  output.writeln();

  // Icon list
  output.writeln(
    '/// All non-deprecated Font Awesome icons from the font_awesome_flutter package.',
  );
  output.writeln('const List<FaIconEntry> allFontAwesomeIcons = [');

  for (final icon in icons) {
    final keywordsStr = icon.searchKeywords
        .map((k) => "'${_escapeString(k)}'")
        .join(', ');
    output.writeln('  FaIconEntry(');
    output.writeln("    displayName: '${_escapeString(icon.displayName)}',");
    output.writeln("    fieldName: '${icon.fieldName}',");
    output.writeln('    iconData: ${icon.constructorCall},');
    output.writeln('    category: FaIconCategory.${icon.category},');
    output.writeln('    searchKeywords: [$keywordsStr],');
    output.writeln('  ),');
  }

  output.writeln('];');

  final outputFile = File('lib/src/generated/font_awesome_all_icons.dart');
  outputFile.writeAsStringSync(output.toString());
  print('Generated: ${outputFile.path}');
  print('Total entries: ${icons.length}');
}

/// Escape single quotes in strings for Dart source code.
String _escapeString(String s) {
  return s.replaceAll("'", "\\'").replaceAll(r'$', r'\$');
}
