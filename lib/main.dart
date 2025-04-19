import 'package:hf_propagation/solar_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

Future<void> _launchURL(Uri url) async {
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

Color _getColorForCondition(String condition, BuildContext context) {
  switch (condition.toLowerCase()) {
    case 'good':
      return Colors.green;
    case 'poor':
      return Colors.red;
    case 'fair':
      return Colors.yellow;
    default:
      return Theme.of(context).textTheme.bodyMedium?.color ??
          Colors.black; // Default to system color
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HF Propagation',
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData(brightness: Brightness.dark),
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
                        style: TextStyle(fontSize: 14, color: Colors.yellow),
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
                              String dayCondition = entry.value['day'] ?? 'N/A';
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
                                .skip(
                                  1,
                                ) // Skip "Updated" as it's already displayed above
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
                  ],
                ),
              ),
    );
  }
}
