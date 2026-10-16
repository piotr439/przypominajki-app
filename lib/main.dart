import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:home_widget/home_widget.dart';

const String csvUrl = 'https://docs.google.com/spreadsheets/d/1k_ClRMichtghqtVIs24aVAEJc_s2qK3Bf2jEFUtNrbY/export?format=csv';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PrzypominajkaApp());
}

class PrzypominajkaApp extends StatelessWidget {
  const PrzypominajkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Małżeńskie Przypominajki',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0081A7)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String todayText = "Ładowanie dzisiejszej przypominajki...";
  String imageName = "";
  String imageUrl = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDailyContent();
  }

  String _formatTodayDate() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return "$day.$month.$year";
  }

  Future<void> fetchDailyContent() async {
    try {
      final response = await http.get(Uri.parse(csvUrl));
      
      if (response.statusCode == 200) {
        final lines = const LineSplitter().convert(response.body);
        final String todayStr = _formatTodayDate();

        String foundText = "Brak wpisu na dzień $todayStr.";
        String foundImageName = "";

        for (var i = 1; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains(todayStr)) {
            final columns = line.split(',');
            if (columns.length >= 4) {
              foundImageName = columns[1].replaceAll('"', '').trim();
              foundText = columns.sublist(3).join(',').replaceAll('"', '').trim();
              break;
            }
          }
        }

        setState(() {
          todayText = foundText;
          imageName = foundImageName;
          imageUrl = foundImageName.isNotEmpty
              ? 'https://drive.google.com/thumbnail?id=$foundImageName&sz=w1000'
              : '';
          isLoading = false;
        });

        await HomeWidget.saveWidgetData<String>('widget_text', todayText);
        await HomeWidget.saveWidgetData<String>('widget_image', imageUrl);
        await HomeWidget.updateWidget(
          name: 'PrzypominajkaWidgetProvider',
          iOSName: 'PrzypominajkaWidget',
        );
      } else {
        setState(() {
          todayText = "Błąd pobierania danych (Kod: ${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        todayText = "Błąd połączenia: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Małżeńskie Przypominajki'),
        backgroundColor: const Color(0xFF0081A7),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 120,
                              color: Colors.grey[200],
                              child: Center(
                                child: Text('Grafika: $imageName'),
                              ),
                            ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SelectableText(
                        todayText,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: fetchDailyContent,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Odśwież dzisiejszą treść'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF07167),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
