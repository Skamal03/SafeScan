import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Scan History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService().getReportHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading history', style: TextStyle(color: AppTheme.danger)));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('No security logs found', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final status = data['status'] ?? 'SAFE';
              
              Color statusColor;
              IconData statusIcon;
              switch (status) {
                case 'CRITICAL':
                  statusColor = AppTheme.danger;
                  statusIcon = Icons.gpp_bad;
                  break;
                case 'WARNING':
                  statusColor = AppTheme.warning;
                  statusIcon = Icons.report_problem;
                  break;
                default:
                  statusColor = AppTheme.success;
                  statusIcon = Icons.verified_user;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              data['type'] ?? 'Unknown Scan',
                              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Text(
                          timestamp != null ? DateFormat('MMM d, HH:mm').format(timestamp) : 'Pending...',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['summary'] ?? 'No summary provided',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
