// ============================================================================
// File: test/tile_server_config_test.dart
// Mục đích: Chứa các kịch bản kiểm thử (Test) cho tile_server_config.
// Kết cấu:
//  - Sử dụng flutter_test, bao gồm các nhóm test (group) và các trường hợp test (test/testWidgets) cụ thể.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/core/services/tile_server_config.dart';

void main() {
  group(
    'TileServerConfig Tests (Fix OpenStreetMap Tile & Watermark Issues)',
    () {
      test(
        'Configures valid primary server and fallbacks without watermark',
        () {
          expect(TileServerConfig.servers.isNotEmpty, isTrue);

          final primary = TileServerConfig.servers.first;
          expect(primary.name, isNotEmpty);
          expect(primary.urlTemplate, isNotEmpty);
          expect(primary.fallbackUrl, isNotNull);
          expect(primary.subdomains, isNotEmpty);

          final osm = TileServerConfig.servers.firstWhere(
            (s) => s.name.contains('OpenStreetMap'),
          );
          expect(osm.urlTemplate, contains('{s}.tile.openstreetmap.de'));
          expect(osm.subdomains, contains('a'));
          expect(osm.subdomains, contains('b'));
          expect(osm.subdomains, contains('c'));
        },
      );

      test('buildTileLayer returns fully configured TileLayer without API key watermark', () {
        final layer = TileServerConfig.buildTileLayer();

        expect(layer.urlTemplate, isNotNull);
        expect(layer.fallbackUrl, isNotNull);
        expect(layer.subdomains, isNotEmpty);
        expect(layer.maxZoom, greaterThanOrEqualTo(18.0));
      });

      test('Custom overrides work in buildTileLayer', () {
        final custom = TileServerConfig.buildTileLayer(
          customUrlTemplate: 'https://test.tile.org/{z}/{x}/{y}.png',
          customFallbackUrl: 'https://backup.tile.org/{z}/{x}/{y}.png',
          customSubdomains: ['x', 'y'],
        );

        expect(
          custom.urlTemplate,
          equals('https://test.tile.org/{z}/{x}/{y}.png'),
        );
        expect(
          custom.fallbackUrl,
          equals('https://backup.tile.org/{z}/{x}/{y}.png'),
        );
        expect(custom.subdomains, equals(['x', 'y']));
      });
    },
  );
}
