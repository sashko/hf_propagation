import 'package:hf_propagation/solar_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

Future<void> _launchURL(Uri url) async {
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

Color _getColorForCondition(String condition, BuildContext context) {
  switch (condition.trim()) {
    case 'Good':
    case 'MID LAT AUR':
    case '50MHz ES':
    case '70MHz ES':
    case '144MHz ES':
      return Colors.green.shade600;
    case 'Fair':
    case 'High LAT AUR':
    case 'High MUF (2M only)':
    case 'High MUF':
      return Colors.amber.shade700;
    case 'Poor':
    case 'Band Closed':
      return Colors.red.shade700;
    default:
      return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HF Propagation',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      themeMode: ThemeMode.system,
      home: const MainPage(title: 'HF Propagation'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    var failed = false;
    try {
      await fetchAndParseSolarData();
    } catch (_) {
      failed = true;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      // Only take over the screen when there is nothing to fall back on.
      _hasError = failed && solarData.isEmpty;
    });

    // A refresh that fails while data is already on screen keeps the stale
    // data visible and reports the failure instead of discarding the view.
    if (failed && solarData.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update solar data')),
      );
    }
  }

  static const _solarDataHelp = <String, String>{
    'SFI':
        'Solar Flux Index — radio emissions at 10.7 cm. Higher means better HF propagation. <70 poor, 90-100 average, 100-150 good, >150 ideal.',
    'SN':
        'Sunspot Number — count of visible sunspots. More sunspots = higher solar activity = better HF. <50 very poor, 75-100 good, 100-150 ideal, >150 exceptional.',
    'A Index':
        'Daily geomagnetic activity average (0-400). Lower = quieter = better HF. 1-5 best, 6-9 average, 10+ very poor.',
    'K Index':
        '3-hour geomagnetic disturbance (0-9). Lower = better. 0-1 best, 2-3 good, 4-5 average, 5-9 very poor.',
    'X-Ray':
        'Solar X-ray flux class. A/B = quiet, C = minor, M = moderate flare, X = major flare that can cause HF blackouts.',
    'MUF US Boulder':
        'Maximum Usable Frequency measured at Boulder, CO. Higher MUF means higher bands are open for propagation.',
    '304A':
        'Helium line EUV radiation at 304 Angstroms. Indicates overall solar activity level.',
    'Proton Flux':
        'High-energy proton level. Elevated values can cause polar cap absorption, degrading HF on polar paths.',
    'Electron Flux':
        'High-energy electron level. Elevated values indicate enhanced radiation belt activity.',
    'Aurora':
        'Auroral activity level. Higher activity can enhance VHF but degrade HF on paths through auroral zones.',
    'Normalization':
        'Data normalization factor applied by the source to adjust readings.',
    'Solar Wind':
        'Speed of the solar wind in km/s. Normal ~400. Above 500 can trigger geomagnetic disturbances.',
    'Magnetic Field':
        'Interplanetary magnetic field (Bz). Southward (negative) Bz drives more geomagnetic activity and worse HF conditions.',
    'Geomag Field':
        'Current geomagnetic field status — quiet, unsettled, active, or storm.',
    'S/N Level':
        'Signal-to-noise background level. Lower values mean a cleaner band with less noise.',
  };

  void _showSolarDataHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Solar Data Reference',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._solarDataHelp.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Icon(Icons.wb_sunny_outlined)),
            Card(
              child: ListTile(
                leading: const Icon(Icons.code_outlined),
                title: const Text('GitHub page'),
                onTap: () {
                  final Uri url = Uri(
                    scheme: 'https',
                    host: 'github.com',
                    path: 'sashko/hf_propagation',
                  );
                  _launchURL(url);
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Send feedback'),
                onTap: () {
                  String email = Uri.encodeComponent(
                    "open.source@oleksandr-kravchuk.com",
                  );
                  String subject = Uri.encodeComponent("HF Propagation");
                  Uri mail = Uri.parse("mailto:$email?subject=$subject");
                  _launchURL(mail);
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Support Ukraine'),
                onTap: () {
                  final Uri url = Uri(
                    scheme: 'https',
                    host: 'savelife.in.ua',
                    path: 'en/donate-en',
                  );
                  _launchURL(url);
                },
              ),
            ),
          ],
        ),
      ),
      body:
          _isLoading && solarData.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    const Text('Could not load solar data'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HF Band Conditions
                      const Text(
                        'HF Band Conditions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Center(
                        child: Text(
                          solarData['Updated'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.yellow.shade800,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('Band')),
                            DataColumn(label: Text('Day')),
                            DataColumn(label: Text('Night')),
                          ],
                          rows:
                              bandConditions.entries.map((entry) {
                                String dayCondition =
                                    entry.value['day'] ?? 'N/A';
                                String nightCondition =
                                    entry.value['night'] ?? 'N/A';

                                return DataRow(
                                  cells: [
                                    DataCell(Text(entry.key)),
                                    DataCell(
                                      Text(
                                        dayCondition,
                                        style: TextStyle(
                                          color: _getColorForCondition(
                                            dayCondition,
                                            context,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        nightCondition,
                                        style: TextStyle(
                                          color: _getColorForCondition(
                                            nightCondition,
                                            context,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // VHF Band Conditions
                      const Text(
                        'VHF Band Conditions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowHeight: 0,
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: SizedBox.shrink()),
                            DataColumn(label: SizedBox.shrink()),
                          ],
                          rows: [
                            DataRow(
                              cells: [
                                const DataCell(Text('Auroral Latitude')),
                                DataCell(
                                  Builder(
                                    builder: (context) {
                                      final dynamic aurLatStrValue =
                                          solarData['Aurora Lat'];

                                      final String auroraLatText;
                                      Color aurLatTextColor;

                                      if (aurLatStrValue == 'No Report') {
                                        auroraLatText = 'No Report';
                                        aurLatTextColor = Colors.red.shade700;
                                      } else {
                                        double? value = double.tryParse(
                                          aurLatStrValue,
                                        );
                                        auroraLatText =
                                            value != null
                                                ? '${value.toStringAsFixed(1)}°'
                                                : 'N/A';

                                        if (value == null) {
                                          aurLatTextColor =
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.color ??
                                              Colors.black;
                                        } else if (value >= 65) {
                                          aurLatTextColor = Colors.red.shade700;
                                        } else if (value >= 60) {
                                          aurLatTextColor =
                                              Colors.amber.shade700;
                                        } else {
                                          aurLatTextColor =
                                              Colors.green.shade600;
                                        }
                                      }
                                      return Text(
                                        auroraLatText,
                                        style: TextStyle(
                                          color: aurLatTextColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            ...vhfConditions.entries.map((entry) {
                              String location = entry.value;

                              return DataRow(
                                cells: [
                                  DataCell(Text(entry.key)),
                                  DataCell(
                                    Text(
                                      location,
                                      style: TextStyle(
                                        color: _getColorForCondition(
                                          location,
                                          context,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Solar Data
                      Row(
                        children: [
                          const Text(
                            'Solar Data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _showSolarDataHelp(context),
                            child: Icon(
                              Icons.help_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowHeight: 0,
                          columns: const [
                            DataColumn(label: SizedBox.shrink()),
                            DataColumn(label: SizedBox.shrink()),
                          ],
                          rows:
                              solarData.entries
                                  .where(
                                    (entry) =>
                                        entry.key != 'Updated' &&
                                        entry.key != 'Aurora Lat',
                                  )
                                  .map(
                                    (entry) => DataRow(
                                      cells: [
                                        DataCell(Text(entry.key)),
                                        DataCell(
                                          Text(
                                            entry.value,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerRight,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Data source: ',
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color ??
                                      Colors.black,
                                ),
                              ),
                              const TextSpan(
                                text: 'NØNBH',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: ' via ',
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color ??
                                      Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: 'hamqsl.com',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        final Uri url = Uri(
                                          scheme: 'https',
                                          host: 'hamqsl.com',
                                        );
                                        _launchURL(url);
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
    );
  }
}
