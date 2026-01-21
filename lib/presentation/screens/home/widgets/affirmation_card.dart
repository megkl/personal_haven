import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';

class AffirmationCard extends StatelessWidget {
  const AffirmationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Affirmation:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '"You are capable of amazing things"',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
