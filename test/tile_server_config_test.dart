import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/core/services/tile_server_config.dart';

void main() {
  group('TileServerConfig Tests (Fix OpenStreetMap Tile & Watermark Issues)', () {
    test('Configures valid primary server and fallbacks without watermark', () {
      expect(TileServerConfig.servers.isNotEmpty, isTrue);

      final primary = TileServerConfig.servers.first;
      expect(primary.name, contains('OpenStreetMap'));
      expect(primary.urlTemplate, contains('{s}.tile.openstreetmap.de'));
      expect(primary.fallbackUrl, isNotNull);
      expect(primary.subdomains, contains('a'));
      expect(primary.subdomains, contains('b'));
      expect(primary.subdomains, contains('c'));
    });

    test('buildTileLayer returns fully configured TileLayer without API key watermark', () {
      final layer = TileServerConfig.buildTileLayer();

      expect(layer.urlTemplate, isNotNull);
      expect(layer.urlTemplate, contains('tile.openstreetmap.de'));
      expect(layer.fallbackUrl, isNotNull);
      expect(layer.fallbackUrl, contains('google.com'));
      expect(layer.subdomains, contains('a'));
      expect(layer.subdomains, contains('b'));
      expect(layer.subdomains, contains('c'));
      expect(layer.maxZoom, equals(18.0));
    });

    test('Custom overrides work in buildTileLayer', () {
      final custom = TileServerConfig.buildTileLayer(
        customUrlTemplate: 'https://test.tile.org/{z}/{x}/{y}.png',
        customFallbackUrl: 'https://backup.tile.org/{z}/{x}/{y}.png',
        customSubdomains: ['x', 'y'],
      );

      expect(custom.urlTemplate, equals('https://test.tile.org/{z}/{x}/{y}.png'));
      expect(custom.fallbackUrl, equals('https://backup.tile.org/{z}/{x}/{y}.png'));
      expect(custom.subdomains, equals(['x', 'y']));
    });
  });
}
