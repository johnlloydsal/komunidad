import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme/app_theme.dart';

// 🔹 Main Hotline Page
class HotlinePage extends StatelessWidget {
  const HotlinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("ILOILO CITY EMERGENCY HOTLINES"),
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHotlineButton(
                context,
                "EMERGENCIES",
                const EmergenciesPage(),
              ),
            const SizedBox(height: 10),
            _buildHotlineButton(
              context,
              "FIRE STATION",
              const FireStationPage(),
            ),
            const SizedBox(height: 10),
            _buildHotlineButton(
              context,
              "HEALTH CENTERS",
              const HealthCentersPage(),
            ),
            const SizedBox(height: 10),
            _buildHotlineButton(context, "HOSPITALS", const HospitalsPage()),
            const SizedBox(height: 10),
            _buildHotlineButton(
              context,
              "COAST GUARDS",
              const CoastGuardsPage(),
            ),
            const SizedBox(height: 10),
            _buildHotlineButton(
              context,
              "POLICE STATION",
              const PoliceStationPage(),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHotlineButton(BuildContext context, String text, Widget page) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// 🔹 Reusable Hotline Card (Title + Number)
Widget _buildHotlineCard(String title, String number) {
  return Builder(
    builder: (context) {
      return Card(
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: () => _handleCallTap(context, title, number),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              number,
                              style: GoogleFonts.robotoMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.call,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// 🔹 Handle Call Action
void _handleCallTap(BuildContext context, String title, String numbers) {
  // Split multiple numbers if separated by " / " or "/"
  List<String> numberList = numbers
      .split(RegExp(r'\s*/\s*'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  if (numberList.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No valid phone number found'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // If only one number, call directly
  if (numberList.length == 1) {
    _makePhoneCall(context, numberList[0]);
  } else {
    // Multiple numbers, show selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Call $title',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: numberList.map((num) {
            return ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.primaryColor),
              title: Text(
                num,
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.call, color: AppTheme.primaryColor),
              onTap: () {
                Navigator.pop(context);
                _makePhoneCall(context, num);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// 🔹 Make Phone Call
Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
  // Remove any spaces, dashes, or special characters except +
  final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: cleanNumber,
  );

  try {
    final bool launched = await launchUrl(
      launchUri,
      mode: LaunchMode.externalApplication,
    );
    
    if (!launched) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot call $phoneNumber'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: Unable to open phone dialer'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Copy Number',
          textColor: Colors.white,
          onPressed: () {
            // You could add clipboard functionality here if needed
          },
        ),
      ),
    );
  }
}

// 📌 Emergencies Page
class EmergenciesPage extends StatelessWidget {
  const EmergenciesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("EMERGENCIES"),
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHotlineCard("CDRRMO (ICDRR)", "333-3333 / 333-2933"),
          _buildHotlineCard("BFP", "333-1111 / 337-6676"),
          _buildHotlineCard("PNP", "333-1111 / Loc. 503"),
          _buildHotlineCard("Red Cross Iloilo", "337-5900"),
          _buildHotlineCard("PSTMO", "333-1111"),
        ],
      ),
    );
  }
}

// 📌 Fire Station Page
class FireStationPage extends StatelessWidget {
  const FireStationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("FIRE STATION"),
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHotlineCard("Arevalo", "300-0000"),
          _buildHotlineCard("Jaro", "320-2222"),
          _buildHotlineCard("La Paz", "337-1111"),
          _buildHotlineCard("Mandurriao", "337-3333"),
          _buildHotlineCard("Molo", "300-1234"),
        ],
      ),
    );
  }
}

// 📌 Health Centers Page
class HealthCentersPage extends StatelessWidget {
  const HealthCentersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("HEALTH CENTERS"),
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHotlineCard("Sta. Barbara", "315-1234"),
          _buildHotlineCard("Mandurriao", "336-9876"),
          _buildHotlineCard("Molo", "333-0000"),
          _buildHotlineCard("Jaro", "337-5678"),
        ],
      ),
    );
  }
}

// 📌 Hospitals Page
class HospitalsPage extends StatelessWidget {
  const HospitalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("HOSPITALS"),
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHotlineCard("WVMC", "321-2841"),
          _buildHotlineCard("St. Paul’s Hospital", "337-2741"),
          _buildHotlineCard("Iloilo Doctors Hospital", "338-1780"),
          _buildHotlineCard("Metro Iloilo Hospital", "337-1450"),
        ],
      ),
    );
  }
}

// 📌 Coast Guards Page
class CoastGuardsPage extends StatelessWidget {
  const CoastGuardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("COAST GUARDS"),
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHotlineCard("Coast Guard Iloilo", "0939-123-4567"),
          _buildHotlineCard("Coast Guard Dumangas", "0945-567-8910"),
          _buildHotlineCard("Coast Guard Station", "0917-654-3210"),
        ],
      ),
    );
  }
}

// 📌 Police Station Page
class PoliceStationPage extends StatelessWidget {
  const PoliceStationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("POLICE STATION"),
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHotlineCard("ICPO HQ", "333-1111"),
          _buildHotlineCard("Arevalo", "337-8901"),
          _buildHotlineCard("Jaro", "320-2233"),
          _buildHotlineCard("La Paz", "333-2222"),
          _buildHotlineCard("Mandurriao", "333-7777"),
          _buildHotlineCard("Molo", "337-1122"),
        ],
      ),
    );
  }
}
