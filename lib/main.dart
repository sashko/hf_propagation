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
    );
  }
}
