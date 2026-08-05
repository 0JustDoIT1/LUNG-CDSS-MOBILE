import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relaxation_game/relaxation_game.dart';

void main() {
  testWidgets('shows the animal match game', (tester) async {
    final controller = MatchThreeController(
      animationDelay: Duration.zero,
      recordStore: MemoryGameRecordStore(),
    );
    addTearDown(controller.dispose);
    await controller.recordsReady;

    await tester.pumpWidget(
      MaterialApp(home: AnimalMatchGamePage(controller: controller)),
    );

    expect(find.text('동물 팡팡'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('MOVES'), findsOneWidget);
    expect(find.text('새 게임'), findsOneWidget);
    expect(find.text('최고 기록 0'), findsOneWidget);
  });
}
