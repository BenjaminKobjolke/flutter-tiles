import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/flutter_tiles.dart';

/// Drives [ColorPickerHelper.showColorPicker] through its copy/paste buttons to
/// verify the alpha (transparency) channel survives the round trip.
///
/// Regression: the copy button used to read a stale captured color, so a
/// semi-transparent value pasted (or set via the alpha slider) was copied back
/// as fully opaque.
void main() {
  late String? clipboardText;
  late String? lastCopied;

  setUp(() {
    clipboardText = null;
    lastCopied = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          switch (call.method) {
            case 'Clipboard.getData':
              return <String, dynamic>{'text': clipboardText};
            case 'Clipboard.setData':
              lastCopied = (call.arguments as Map)['text'] as String?;
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// The dialog's action buttons are the only [TextButton]s in the tree:
  /// `[Cancel, Save]` in order.
  Finder dialogButtons() => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextButton),
  );

  /// Pumps a host with a button that opens the picker and stores its result.
  Future<Color?> openAndDrive(
    WidgetTester tester, {
    required Color initialColor,
    required Future<void> Function(WidgetTester tester) interact,
    ColorPickerMessageCallback? onMessage,
  }) async {
    Color? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ColorPickerHelper.showColorPicker(
                  context,
                  title: 'pick',
                  initialColor: initialColor,
                  onMessage: onMessage,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await interact(tester);
    return result;
  }

  testWidgets('host receives copied and invalid paste messages', (
    tester,
  ) async {
    final messages = <(String, bool)>[];
    clipboardText = 'invalid';
    await openAndDrive(
      tester,
      initialColor: Colors.red,
      onMessage: (context, message, {required isError}) =>
          messages.add((message, isError)),
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.copy));
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);
        await tester.tap(find.byIcon(Icons.content_paste));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
        await tester.tap(dialogButtons().first);
        await tester.pumpAndSettle();
      },
    );
    expect(messages, [
      ('Color copied to clipboard', false),
      ('No valid hex color on clipboard', true),
    ]);
  });

  testWidgets('default copy still shows snackbar', (tester) async {
    clipboardText = 'invalid';
    await openAndDrive(
      tester,
      initialColor: Colors.red,
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.copy));
        await tester.pump();
        expect(find.text('Color copied to clipboard'), findsOneWidget);
        await tester.tap(dialogButtons().first);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('default invalid paste still shows snackbar', (tester) async {
    clipboardText = 'invalid';
    await openAndDrive(
      tester,
      initialColor: Colors.red,
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.content_paste));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('No valid hex color on clipboard'), findsOneWidget);
      },
    );
  });

  testWidgets('paste of #80FF0000 preserves alpha through Save', (
    tester,
  ) async {
    clipboardText = '#80FF0000';

    final result = await openAndDrive(
      tester,
      initialColor: const Color(0xFFFFFFFF),
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.content_paste));
        await tester.pumpAndSettle();
        await tester.tap(dialogButtons().last); // Save
        await tester.pumpAndSettle();
      },
    );

    expect(result, isNotNull);
    expect(result!.toARGB32(), equals(0x80FF0000));
  });

  testWidgets('copy after paste emits 8-digit hex including alpha', (
    tester,
  ) async {
    clipboardText = '#80FF0000';

    await openAndDrive(
      tester,
      initialColor: const Color(0xFFFFFFFF),
      interact: (tester) async {
        await tester.tap(find.byIcon(Icons.content_paste));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.copy));
        await tester.pumpAndSettle();
      },
    );

    expect(lastCopied, equals('#80FF0000'));
  });

  testWidgets('Cancel returns null', (tester) async {
    final result = await openAndDrive(
      tester,
      initialColor: const Color(0xFF123456),
      interact: (tester) async {
        await tester.tap(dialogButtons().first); // Cancel
        await tester.pumpAndSettle();
      },
    );

    expect(result, isNull);
  });

  testWidgets('clipboard reply after dismissal does not update dialog', (
    tester,
  ) async {
    final reply = Completer<Map<String, dynamic>?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') return reply.future;
          return null;
        });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ColorPickerHelper.showColorPicker(
                context,
                title: 'pick',
                initialColor: Colors.red,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.content_paste));
    await tester.pump();
    await tester.tap(dialogButtons().first);
    await tester.pumpAndSettle();
    reply.complete({'text': '#FF0000'});
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
