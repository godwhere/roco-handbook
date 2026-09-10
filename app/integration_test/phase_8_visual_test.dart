import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:roco_handbook/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures the Phase 8 filter, Tools, and shiny flows', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const ValueKey('pet-filters')));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('phase8-filter-sheet');

    Navigator.of(tester.element(find.byKey(const ValueKey('pet-filter-sheet'))))
        .pop();
    await tester.pumpAndSettle();

    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(Offset(size.width * 0.625, size.height - 65));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('phase8-tools');

    await tester.tap(find.byKey(const ValueKey('tool-card-egg-groups')));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('phase8-egg-groups');
    await tester.tap(find.byKey(const ValueKey('egg-group-filters')));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('phase8-egg-group-filters');
    Navigator.of(
      tester.element(find.byKey(const ValueKey('egg-group-filter-sheet'))),
    ).pop();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byKey(const ValueKey('egg-groups-list'))))
        .pop();
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('tools-page')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tool-card-game-descriptions')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await binding.takeScreenshot('phase8-game-descriptions');
    await tester.tap(find.byKey(const ValueKey('game-description-1001')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await binding.takeScreenshot('phase8-game-description-detail');
    Navigator.of(
      tester.element(
        find.byKey(const ValueKey('game-description-detail-1001')),
      ),
    ).pop();
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.byKey(const ValueKey('game-description-list'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tool-card-event-timeline')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await binding.takeScreenshot('phase8-activity-timeline');
    await tester.tap(find.byKey(const ValueKey('activity-activity_1600019')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await binding.takeScreenshot('phase8-activity-detail');
    Navigator.of(
      tester.element(
        find.byKey(const ValueKey('activity-detail-activity_1600019')),
      ),
    ).pop();
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.byKey(const ValueKey('activity-timeline-page'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('tool-card-outfit-inspiration')),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await binding.takeScreenshot('phase8-outfit-catalog');
    await tester.tap(find.byKey(const ValueKey('outfit-fashion_000001')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await binding.takeScreenshot('phase8-outfit-detail');
    Navigator.of(
      tester.element(
        find.byKey(const ValueKey('outfit-detail-fashion_000001')),
      ),
    ).pop();
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.byKey(const ValueKey('outfit-inspiration-page'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tapAt(Offset(size.width * 0.125, size.height - 65));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('pet-search')), '030');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pet-result-pet_000009')));
    await tester.pumpAndSettle();

    final toggle = tester.getRect(
      find.byKey(const ValueKey('pet-shiny-toggle')),
    );
    await tester.tapAt(
      Offset(toggle.center.dx + toggle.width * 0.25, toggle.center.dy),
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('phase8-shiny-detail');
  });
}
