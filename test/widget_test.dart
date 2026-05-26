import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_wall_app/main.dart';

void main() {
  testWidgets('Wallpaper Wall app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const WallpaperWallApp());
    expect(find.text('Wallpaper Wall'), findsOneWidget);
  });
}