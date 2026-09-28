import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

Map<String, String> solarData = {};
Map<String, Map<String, String>> bandConditions = {};
Map<String, String> vhfConditions = {};

String _tagText(xml.XmlElement parent, String name) {
  final matches = parent.findElements(name);
  return matches.isEmpty ? 'N/A' : matches.first.innerText.trim();
}

Future<void> fetchAndParseSolarData() async {
  const url = 'https://www.hamqsl.com/solarxml.php';

  try {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);

      // Solar data map
      final solarDataElement = document.findAllElements('solardata').first;
      String field(String tag) => _tagText(solarDataElement, tag);
      solarData = {
        'Updated': field('updated'),
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
        'Aurora Lat': field('latdegree'),
        'Solar Wind': field('solarwind'),
        'Magnetic Field': field('magneticfield'),
        'Geomag Field': field('geomagfield'),
        'S/N Level': field('signalnoise'),
      };

      // Print solar data
      if (kDebugMode) {
        debugPrint('\n\n--- Solar Data ---');
        solarData.forEach((key, value) => debugPrint('$key: $value'));
      }

      // Get the <calculatedconditions> element
      final calculatedConditions =
          document.findAllElements('calculatedconditions').first;

      final bands = calculatedConditions.findElements('band');
      for (var band in bands) {
        final name = band.getAttribute('name');
        final time = band.getAttribute('time'); // 'day' or 'night'
        final condition =
            band.innerText
                .trim(); // The actual condition text like "Good", "Poor"

        if (name != null && time != null) {
          // Initialize the map for each band
          if (!bandConditions.containsKey(name)) {
            bandConditions[name] = {'day': 'N/A', 'night': 'N/A'};
          }

          // Update based on the time attribute
          if (time == 'day') {
            bandConditions[name]?['day'] = condition;
          } else if (time == 'night') {
            bandConditions[name]?['night'] = condition;
          }
        }
      }

      // Print band conditions
      if (kDebugMode) {
        debugPrint('\n\n--- Band Conditions ---');
        bandConditions.forEach((band, cond) {
          debugPrint('$band - Day: ${cond['day']}, Night: ${cond['night']}');
        });
      }

      // Get the <calculatedvhfconditions> element
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

      vhfConditions = {
        "Aurora": aurora,
        "6m ES Europe": es6mEurope,
        "4m ES Europe": es4mEurope,
        "2m ES Europe": es2mEurope,
        "2m ES North America": es2mNorthAmerica,
      };

      // Print VHF conditions
      if (kDebugMode) {
        debugPrint('\n\n--- VHF Conditions ---');
        vhfConditions.forEach((location, cond) {
          debugPrint('$location: $cond');
        });
      }
    } else {
      throw Exception(
        'Failed to load data. Status code: ${response.statusCode}',
      );
    }
  } catch (e) {
    rethrow;
  }
}
