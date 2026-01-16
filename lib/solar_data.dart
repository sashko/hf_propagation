import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

Map<String, String> solarData = {};
Map<String, Map<String, String>> bandConditions = {};
Map<String, String> vhfConditions = {};

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
            solarDataElement.findElements('updated').first.innerText.trim(),
        'SFI':
            solarDataElement.findElements('solarflux').first.innerText.trim(),
        'A Index':
            solarDataElement.findElements('aindex').first.innerText.trim(),
        'K Index':
            solarDataElement.findElements('kindex').first.innerText.trim(),
        'MUF US Boulder':
            solarDataElement.findElements('kindexnt').first.innerText.trim(),
        'X-Ray': solarDataElement.findElements('xray').first.innerText.trim(),
        'SN': solarDataElement.findElements('sunspots').first.innerText.trim(),
        '304A':
            solarDataElement.findElements('heliumline').first.innerText.trim(),
        'Proton Flux':
            solarDataElement.findElements('protonflux').first.innerText.trim(),
        'Electon Flux':
            solarDataElement.findElements('electonflux').first.innerText.trim(),
        'Aurora':
            solarDataElement.findElements('aurora').first.innerText.trim(),
        'Normalization':
            solarDataElement.findElements('normalization').first.innerText.trim(),
        'Aurora Lat':
            solarDataElement.findElements('latdegree').first.innerText.trim(),
        'Solar Wind':
            solarDataElement.findElements('solarwind').first.innerText.trim(),
        'Magnetic Field':
            solarDataElement.findElements('magneticfield').first.innerText.trim(),
        'Geomag Field':
            solarDataElement.findElements('geomagfield').first.innerText.trim(),
        'S/N Level':
            solarDataElement.findElements('signalnoise').first.innerText.trim(),
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
            band.innerText.trim(); // The actual condition text like "Good", "Poor"

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
      print('\n\n--- VHF Conditions ---');
      vhfConditions.forEach((location, cond) {
        print('$location: $cond');
      });
    } else {
      print('Failed to load data. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred: $e');
  }
}
