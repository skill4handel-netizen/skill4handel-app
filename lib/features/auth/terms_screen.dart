import 'package:flutter/material.dart';
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms and rules')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text('Skill4Handel terms', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('You must be 16 or older. By creating an account you accept these rules.'),
          SizedBox(height: 16),
          Text('What is allowed', style: TextStyle(fontWeight: FontWeight.w800)),
          Text('Skill swaps, practical help, learning, volunteer help, and S4H tokens. No cash between users.'),
          SizedBox(height: 16),
          Text('What is banned', style: TextStyle(fontWeight: FontWeight.w800)),
          Text(
            'Sex work and sexual services, pornography, violent work, weapons, illegal drugs, theft, fraud, hacking for crime, and any other illegal activity. Accounts that offer these will be banned.',
          ),
          SizedBox(height: 16),
          Text('Responsibility', style: TextStyle(fontWeight: FontWeight.w800)),
          Text(
            'Skill4Handel is a matching platform. The quality, safety and result of each swap is the responsibility of the two people. Meet in a public place if you do not know the other person. Read the profile first.',
          ),
          SizedBox(height: 16),
          Text('Cancellation', style: TextStyle(fontWeight: FontWeight.w800)),
          Text('You may cancel an accepted exchange until 24 hours before the agreed date and time.'),
          SizedBox(height: 16),
          Text('Reports and bans', style: TextStyle(fontWeight: FontWeight.w800)),
          Text(
            'Use Report or Fraud in Support. We can suspend or ban accounts. Email info@skill4handel.com.',
          ),
        ],
      ),
    );
  }
}