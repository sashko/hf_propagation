import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

Map<String, String> solarData = {};
Map<String, Map<String, String>> bandConditions = {};
Map<String, Map<String, String>> vhfConditions = {};

Future<void> fetchAndParseSolarData() async {
  final url = 'https://www.hamqsl.com/solarxml.php';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);

      // Solar data map
      final solarDataElement = document.findAllElements('solardata').first;
      solarData = {
        'Updated':
            solarDataElement.findElements('updated').first.text.trim() ?? '',
        'SFI':
            solarDataElement.findElements('solarflux').first.text.trim() ?? '',
        'A Index':
            solarDataElement.findElements('aindex').first.text.trim() ?? '',
        'K Index':
            solarDataElement.findElements('kindex').first.text.trim() ?? '',
        'MUF US Boulder':
            solarDataElement.findElements('kindexnt').first.text.trim() ?? '',
        'X-Ray': solarDataElement.findElements('xray').first.text.trim() ?? '',
        'SN': solarDataElement.findElements('sunspots').first.text.trim() ?? '',
        '304A':
            solarDataElement.findElements('heliumline').first.text.trim() ?? '',
        'Proton Flux':
            solarDataElement.findElements('protonflux').first.text.trim() ?? '',
        'Electon Flux':
            solarDataElement.findElements('electonflux').first.text.trim() ??
            '',
        'Aurora':
            solarDataElement.findElements('aurora').first.text.trim() ?? '',
        'Normalization':
            solarDataElement.findElements('normalization').first.text.trim() ??
            '',
        'Aurora Lat':
            solarDataElement.findElements('latdegree').first.text.trim() ?? '',
        'Solar Wind':
            solarDataElement.findElements('solarwind').first.text.trim() ?? '',
        'Magnetic Field':
            solarDataElement.findElements('magneticfield').first.text.trim() ??
            '',
        'Geomag Field':
            solarDataElement.findElements('geomagfield').first.text.trim() ??
            '',
        'S/N Level':
            solarDataElement.findElements('signalnoise').first.text.trim() ??
            '',
      };

      // Print solar data
      print('\n\n--- Solar Data ---');
      solarData.forEach((key, value) => print('$key: $value'));

      // Get the <calculatedconditions> element
      final calculatedConditions =
          document.findAllElements('calculatedconditions').first;

      final bands = calculatedConditions.findElements('band');
      for (var band in bands) {
        final name = band.getAttribute('name');
        final time = band.getAttribute('time'); // 'day' or 'night'
        final condition =
            band.text.trim(); // The actual condition text like "Good", "Poor"

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
      print('\n\n--- Band Conditions ---');
      bandConditions.forEach((band, cond) {
        print('$band - Day: ${cond['day']}, Night: ${cond['night']}');
      });
    } else {
      print('Failed to load data. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred: $e');
  }
}
