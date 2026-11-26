import 'package:flutter_test/flutter_test.dart';
import 'package:fmds_render_lab/main.dart';

void main() {
  testWidgets('lab renders version', (tester) async {
    await tester.pumpWidget(const RenderLab());
    expect(find.textContaining('FMDS Render Lab v0.1.0'), findsOneWidget);
  });
}
