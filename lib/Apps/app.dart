import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppHubScreen extends StatelessWidget {
  const AppHubScreen({super.key});

  Future<void> _launchApp(String urlScheme, String fallbackUrl) async {
    try {
      // First try the direct app URL scheme
      if (await canLaunchUrl(Uri.parse(urlScheme))) {
        await launchUrl(
          Uri.parse(urlScheme),
          mode: LaunchMode.externalApplication,
        );
        return;
      }
      
      // If that fails, try the web URL
      if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
        await launchUrl(
          Uri.parse(fallbackUrl),
          mode: LaunchMode.externalApplication,
        );
        return;
      }
      
      // As last resort, try opening in app store
      final storeUrl = urlScheme.contains('://') 
          ? urlScheme.split('://')[0]
          : urlScheme;
      await launchUrl(
        Uri.parse(
          'https://play.google.com/store/search?q=$storeUrl&c=apps'
        ),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Hub'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== SOCIAL APPS ==========
              _buildSectionHeader('Social'),
              _buildAppGrid([
                _AppItem('Facebook', 'assets/facebook.png', 
                  'fb://', 'https://facebook.com'),
                _AppItem('WhatsApp', 'assets/whatsapp.png', 
                  'whatsapp://', 'https://whatsapp.com'),
                _AppItem('Instagram', 'assets/insta.jpg', 
                  'instagram://app', 'https://instagram.com'),
                _AppItem('Twitter', 'assets/x.png', 
                  'twitter://', 'https://twitter.com'),
                _AppItem('LinkedIn', 'assets/linkedin.png', 
                  'linkedin://', 'https://linkedin.com'),
                _AppItem('Snapchat', 'assets/snap.jpg', 
                  'snapchat://', 'https://snapchat.com'),
              ]),

              // ========== PAYMENT APPS ==========
              _buildSectionHeader('Payment'),
              _buildAppGrid([
                _AppItem('PhonePe', 'assets/phonepe.png', 
                  'phonepe://', 'https://www.phonepe.com'),
                _AppItem('Paytm', 'assets/paytm.webp', 
                  'paytmmp://', 'https://paytm.com'),
                _AppItem('BHIM UPI', 'assets/upi.webp', 
                  'upi://pay', 'https://www.bhimupi.org.in'),
                _AppItem('GPay', 'assets/gpay.png', 
                  'tez://upi/pay', 'https://pay.google.com'),
              ]),

              // ========== GOVERNMENT APPS ==========
              _buildSectionHeader('Government App'),
              _buildAppGrid([
                _AppItem('IRCTC', 'assets/irct.png', 
                  'irctc://', 'https://www.irctc.co.in'),
                _AppItem('Umang', 'assets/umang.png', 
                  'umang://', 'https://web.umang.gov.in'),
                _AppItem('Aadhaar', 'assets/adhar.png', 
                  'uidai://', 'https://uidai.gov.in'),
                _AppItem('DigiLocker', 'assets/digi.png', 
                  'digilocker://', 'https://www.digilocker.gov.in'),
                _AppItem('Arogya Setu', 'assets/ar.webp', 
                  'aarogyasetu://', 'https://www.aarogyasetu.gov.in'),
              ]),

              // ========== PRODUCTIVITY APPS ==========
              _buildSectionHeader('Productivity'),
              _buildAppGrid([
                _AppItem('Google Meet', 'assets/meet.png', 
                  'com.google.android.apps.meetings://', 'https://meet.google.com'),
                _AppItem('Zoom', 'assets/zoom.png', 
                  'zoomus://', 'https://zoom.us'),
                _AppItem('Gmail', 'assets/gmail.jpg', 
                  'googlegmail://', 'https://mail.google.com'),
                _AppItem('Google Drive', 'assets/drive.webp', 
                  'googledrive://', 'https://drive.google.com'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildAppGrid(List<_AppItem> apps) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return InkWell(
          onTap: () => _launchApp(app.urlScheme, app.fallbackUrl),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                app.imagePath,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.apps, size: 40),
              ),
              const SizedBox(height: 8),
              Text(
                app.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppItem {
  final String title;
  final String imagePath;
  final String urlScheme;
  final String fallbackUrl;

  const _AppItem(
    this.title,
    this.imagePath,
    this.urlScheme,
    this.fallbackUrl,
  );
}