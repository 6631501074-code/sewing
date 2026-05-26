import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sewing/Homepage/task_card.dart';

void main() {
  testWidgets('task card opens through tap', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            title: 'งานทดสอบ',
            tailorName: 'งานรายวัน',
            status: TaskStatus.doing,
            imagePath: 'asset/img/user.png',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('งานทดสอบ'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
