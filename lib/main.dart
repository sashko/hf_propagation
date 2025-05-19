import 'package:hf_propagation/solar_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
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
      return Colors.green;
    case 'Fair':
    case 'High LAT AUR':
    case 'High MUF (2M only)':
    case 'High MUF':
      return Colors.orange;
    case 'Poor':
    case 'Band Closed':
      return Colors.red;
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

  @override
  void initState() {
    super.initState();
    fetchAndParseSolarData().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });
    await fetchAndParseSolarData();
    setState(() {
      _isLoading = false;
    });
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
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
                          '${solarData['Updated'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 14, color: Colors.orange),
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
                                DataCell(Text('Auroral Latitude')),
                                DataCell(
                                  Builder(
                                    builder: (context) {
                                      final dynamic aurLatStrValue =
                                          solarData['Aurora Lat'];

                                      double? value = double.tryParse(
                                        aurLatStrValue,
                                      );

                                      // add ° symbol to the value
                                      final String auroraLatText =
                                          value != null
                                              ? '${value.toStringAsFixed(1)}°'
                                              : 'N/A';

                                      Color aurLatTextColor;
                                      if (value == null) {
                                        aurLatTextColor =
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color ??
                                            Colors.black;
                                      } else if (value >= 60) {
                                        aurLatTextColor = Colors.red;
                                      } else if (value >= 40) {
                                        aurLatTextColor = Colors.orange;
                                      } else {
                                        aurLatTextColor = Colors.green;
                                      }
                                      return Text(
                                        auroraLatText,
                                        style: TextStyle(
                                          color: aurLatTextColor,
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
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Solar Data
                      const Text(
                        'Solar Data',
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
                                        DataCell(Text(entry.value)),
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
                              TextSpan(
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
                                style: TextStyle(
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
