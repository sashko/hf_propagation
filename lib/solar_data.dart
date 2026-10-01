import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;

typedef BandCondition = ({String day, String night});

@immutable
class SolarData {
  const SolarData({
    required this.updated,
    required this.auroraLat,
    required this.indices,
    required this.bands,
    required this.vhf,
  });

  final String updated;
  final String auroraLat;

  final Map<String, String> indices;

  final Map<String, BandCondition> bands;

  final Map<String, String> vhf;
}

String _tagText(xml.XmlElement parent, String name) {
  final matches = parent.findElements(name);
  return matches.isEmpty ? 'N/A' : matches.first.innerText.trim();
}

const _cacheKey = 'solar_xml';

Future<SolarData?> loadCachedSolarData() async {
  final body = (await SharedPreferences.getInstance()).getString(_cacheKey);
  if (body == null) return null;
  try {
    return _parseSolarXml(body);
  } catch (_) {
    return null;
  }
}

Future<SolarData> fetchSolarData() async {
  const url = 'https://www.hamqsl.com/solarxml.php';

  final response = await http
      .get(Uri.parse(url))
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception('Failed to load data. Status code: ${response.statusCode}');
  }

  final data = _parseSolarXml(response.body);
  await (await SharedPreferences.getInstance()).setString(
    _cacheKey,
    response.body,
  );
  return data;
}

SolarData _parseSolarXml(String body) {
  final document = xml.XmlDocument.parse(body);

  final solarDataElement = document.findAllElements('solardata').first;
  String field(String tag) => _tagText(solarDataElement, tag);

  final indices = {
    'SFI': field('solarflux'),
    'A Index': field('aindex'),
    'K Index': field('kindex'),
    'MUF US Boulder': field('kindexnt'),
    'X-Ray': field('xray'),
    'SN': field('sunspots'),
    '304A': field('heliumline'),
    'Proton Flux': field('protonflux'),
    'Electron Flux': field('electonflux'),
    'Aurora': field('aurora'),
    'Normalization': field('normalization'),
    'Solar Wind': field('solarwind'),
    'Magnetic Field': field('magneticfield'),
    'Geomag Field': field('geomagfield'),
    'S/N Level': field('signalnoise'),
  };

  if (kDebugMode) {
    debugPrint('\n\n--- Solar Data ---');
    indices.forEach((key, value) => debugPrint('$key: $value'));
  }

  final calculatedConditions =
      document.findAllElements('calculatedconditions').first;

  final bandElements = calculatedConditions.findElements('band');
  final bands = <String, BandCondition>{};

  for (var band in bandElements) {
    final name = band.getAttribute('name');
    final time = band.getAttribute('time'); // 'day' or 'night'
    final condition = band.innerText.trim();

    if (name != null && time != null) {
      var current = bands[name] ?? (day: 'N/A', night: 'N/A');

      if (time == 'day') {
        current = (day: condition, night: current.night);
      } else if (time == 'night') {
        current = (day: current.day, night: condition);
      }
      bands[name] = current;
    }
  }

  if (kDebugMode) {
    debugPrint('\n\n--- Band Conditions ---');
    bands.forEach((band, cond) {
      debugPrint('$band - Day: ${cond.day}, Night: ${cond.night}');
    });
  }

  final calculatedVhfConditions =
      document.findAllElements('calculatedvhfconditions').first;

  String aurora = 'N/A';
  String es2mEurope = 'N/A';
  String es4mEurope = 'N/A';
  String es6mEurope = 'N/A';
  String es2mNorthAmerica = 'N/A';

  final phenomenons = calculatedVhfConditions.findElements('phenomenon');

  for (var p in phenomenons) {
    final location = p.getAttribute('location');
    final condition = p.innerText.trim();

    switch (location) {
      case "northern_hemi":
        aurora = condition;
        break;
      case "europe":
        es2mEurope = condition;
        break;
      case "europe_4m":
        es4mEurope = condition;
        break;
      case "europe_6m":
        es6mEurope = condition;
        break;
      case "north_america":
        es2mNorthAmerica = condition;
        break;
    }
  }

  final vhf = {
    "Aurora": aurora,
    "6m ES Europe": es6mEurope,
    "4m ES Europe": es4mEurope,
    "2m ES Europe": es2mEurope,
    "2m ES North America": es2mNorthAmerica,
  };

  if (kDebugMode) {
    debugPrint('\n\n--- VHF Conditions ---');
    vhf.forEach((location, cond) {
      debugPrint('$location: $cond');
    });
  }

  return SolarData(
    updated: field('updated'),
    auroraLat: field('latdegree'),
    indices: indices,
    bands: bands,
    vhf: vhf,
  );
}
