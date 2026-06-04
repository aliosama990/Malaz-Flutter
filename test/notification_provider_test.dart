import 'package:flutter_test/flutter_test.dart';
import 'package:malaz_app/providers/notification_provider.dart';

void main() {
  group('NotificationsProvider dummy data', () {
    test('uses the selected child name in seeded notification text', () {
      final provider = NotificationsProvider();

      provider.loadDummyData(childName: 'ليلى');

      final notificationTexts =
          provider.notifications.map((notification) => notification.text);

      expect(notificationTexts, everyElement(contains('ليلى')));
      expect(notificationTexts.join('\n'), isNot(contains('سلمي')));
      expect(notificationTexts.join('\n'), isNot(contains('احمد')));
      expect(notificationTexts.join('\n'), isNot(contains('فرح')));
    });

    test('falls back to a generic child label when child name is blank', () {
      final provider = NotificationsProvider();

      provider.loadDummyData(childName: '   ');

      expect(
        provider.notifications.map((notification) => notification.text),
        everyElement(contains('طفلك')),
      );
    });
  });
}
