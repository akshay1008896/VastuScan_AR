import 'package:flutter/material.dart';
import 'package:vastuscan_ar/models/scan_session.dart';
import 'package:vastuscan_ar/services/storage_service.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';
import 'package:vastuscan_ar/screens/map_view_screen.dart';
import 'package:vastuscan_ar/screens/non_compliant_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<ScanSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshSessions();
  }

  void _refreshSessions() {
    setState(() {
      _sessionsFuture = StorageService.instance.getAllSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text('Scan History', style: TextStyle(fontFamily: 'Outfit', color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<ScanSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('No saved scans yet.', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  const Text('Completed scans will appear here.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              return _buildSessionCard(sessions[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(ScanSession session) {
    final dateStr = '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}';
    final timeStr = '${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            session.name,
            style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          ),
          subtitle: Text(
            '$dateStr • $timeStr',
            style: const TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary, fontSize: 13),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.saffron.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${session.score.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.saffron, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(Icons.check_circle, AppColors.compliant, '${session.compliantCount} Compliant'),
                      _buildStat(Icons.warning, AppColors.nonCompliant, '${session.nonCompliantCount} Issues'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MapViewScreen(session: session)));
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            side: const BorderSide(color: AppColors.gold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('View Map'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => NonCompliantScreen(session: session)));
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.nonCompliant,
                            side: const BorderSide(color: AppColors.nonCompliant),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('View Issues'),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.glassBorder, height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.nonCompliant, size: 20),
                      onPressed: () async {
                        final confirm = await _showDeleteConfirm();
                        if (confirm) {
                          await StorageService.instance.deleteSession(session.id);
                          _refreshSessions();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
      ],
    );
  }

  Future<bool> _showDeleteConfirm() async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Delete Scan?', style: TextStyle(color: Colors.white, fontFamily: 'Outfit')),
        content: const Text('This scan data will be permanently removed.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.nonCompliant))),
        ],
      ),
    ) ?? false;
  }
}
