import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/google_drive_service.dart';
import '../models/backup_metadata.dart';
import '../utils/localization.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final GoogleDriveService _driveService = GoogleDriveService();
  
  Map<String, dynamic>? _stats;
  List<BackupMetadata>? _backups;
  bool _isLoading = false;
  String _selectedPeriod = '1_year';
  
  String get _currentLanguage => Localizations.localeOf(context).toString();
  int _databaseSize = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String t(String key) => AppLocalizations.t(key, _currentLanguage);

  Future<void> _loadData() async {
    await _dbService.init();
    final language = _dbService.getLanguage();
    final dbSize = await _dbService.getDatabaseSize();
    setState(() {
      // _currentLanguage = language; // No longer needed
      _stats = _dbService.getDataStats();
      _databaseSize = dbSize;
    });

    if (_driveService.isSignedIn) {
      await _loadBackups();
    }
  }

  Future<void> _loadBackups() async {
    try {
      final backups = await _driveService.listBackups();
      setState(() {
        _backups = backups;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error')}: $e')),
        );
      }
    }
  }

  DateTime _getCutoffDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '6_months':
        return DateTime(now.year, now.month - 6, now.day);
      case '1_year':
        return DateTime(now.year - 1, now.month, now.day);
      case '2_years':
        return DateTime(now.year - 2, now.month, now.day);
      default:
        return DateTime(now.year - 1, now.month, now.day);
    }
  }

  Future<void> _backupAndClean() async {
    final cutoffDate = _getCutoffDate();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('confirm_backup_clean')),
        content: Text(t('confirm_backup_clean_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('continue')),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // 1. Sign in to Google Drive if needed
      if (!_driveService.isSignedIn) {
        final signedIn = await _driveService.signIn();
        if (!signedIn) {
          throw Exception(t('google_signin_failed'));
        }
      }

      // 2. Export data (ZIP with JSON + Attachments)
      final zipBytes = await _dbService.exportBackupBytes(endDate: cutoffDate);
      
      // 3. Create backup metadata
      final stats = _dbService.getDataStats();
      final metadata = BackupMetadata(
        id: '',
        fileName: 'finagevoz_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.zip',
        createdAt: DateTime.now(),
        fileSize: zipBytes.length,
        transactionCount: stats['transactionCount'] ?? 0,
        eventCount: stats['eventCount'] ?? 0,
        startDate: stats['oldestTransaction'],
        endDate: cutoffDate,
      );

      // 4. Upload to Google Drive
      await _driveService.uploadBackup(zipBytes, metadata);

      // 5. Delete old data
      final deleted = await _dbService.deleteOldData(cutoffDate);

      // 6. Reload data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t('backup_success')}: ${deleted['transactions']} ${t('transactions')}, ${deleted['events']} ${t('events')}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(BackupMetadata backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('confirm_restore')),
        content: Text('${t('confirm_restore_message')}\n\n${backup.fileName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('restore')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // 1. Download backup
      final zipBytes = await _driveService.downloadBackup(backup.id);

      // 2. Import data
      final imported = await _dbService.importBackupBytes(zipBytes);

      // 3. Reload data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t('restore_success')}: ${imported['transactions']} ${t('transactions')}, ${imported['events']} ${t('events')}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('confirm_wipe_title')),
        content: Text(t('confirm_wipe_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('wipe_all')),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // Delete everything by setting cutoff date to far future
      final futureDate = DateTime.now().add(const Duration(days: 36500)); // 100 years
      final deleted = await _dbService.deleteOldData(futureDate);
      
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t('data_wiped_msg')
                  .replaceAll('{transactions}', '${deleted['transactions']}')
                  .replaceAll('{events}', '${deleted['events']}'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error')}: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('data_management')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('database_statistics'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow(Icons.receipt_long, t('transactions'), '${_stats?['transactionCount'] ?? 0}'),
                          _buildStatRow(Icons.event, t('events'), '${_stats?['eventCount'] ?? 0}'),
                          _buildStatRow(Icons.category, t('categories'), '${_stats?['categoryCount'] ?? 0}'),
                          const Divider(height: 32),
                          FutureBuilder<int>(
                            future: _dbService.getDatabaseSize(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                );
                              }
                              
                              final sizeBytes = snapshot.data!;
                              final sizeMB = sizeBytes / (1024 * 1024);
                              final maxSizeMB = 100.0; // Assume 100MB max for visual
                              final progress = (sizeMB / maxSizeMB).clamp(0.0, 1.0);
                              
                              String formattedSize;
                              if (sizeBytes < 1024) {
                                formattedSize = '$sizeBytes B';
                              } else if (sizeBytes < 1024 * 1024) {
                                formattedSize = '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
                              } else {
                                formattedSize = '${sizeMB.toStringAsFixed(2)} MB';
                              }
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.storage, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(t('database_size'))),
                                      Text(
                                        formattedSize,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progress < 0.5
                                            ? Colors.green
                                            : progress < 0.8
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(progress * 100).toStringAsFixed(0)}% ${t('of_max_size')}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Google Drive Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t('google_drive'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (_driveService.isSignedIn)
                                TextButton.icon(
                                  icon: const Icon(Icons.logout),
                                  label: Text(t('sign_out')),
                                  onPressed: () async {
                                    await _driveService.signOut();
                                    setState(() {
                                      _backups = null;
                                    });
                                  },
                                )
                              else
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.login),
                                  label: Text(t('sign_in')),
                                  onPressed: () async {
                                    final success = await _driveService.signIn();
                                    if (success) {
                                      await _loadBackups();
                                    }
                                  },
                                ),
                            ],
                          ),
                          if (_driveService.isSignedIn) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${t('signed_in_as')}: ${_driveService.userEmail}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Backup and Clean Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('backup_and_clean'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedPeriod,
                            decoration: InputDecoration(
                              labelText: t('clean_data_older_than'),
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(value: '6_months', child: Text(t('6_months'))),
                              DropdownMenuItem(value: '1_year', child: Text(t('1_year'))),
                              DropdownMenuItem(value: '2_years', child: Text(t('2_years'))),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriod = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.cloud_upload),
                              label: Text(t('backup_and_clean_button')),
                              onPressed: _backupAndClean,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          const Divider(height: 32),
                          Text(
                            t('danger_zone'),
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              label: Text(t('wipe_all_data'), style: const TextStyle(color: Colors.red)),
                              onPressed: _deleteAllData,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                side: BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Backups List
                  if (_driveService.isSignedIn && _backups != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('available_backups'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            if (_backups!.isEmpty)
                              Center(child: Text(t('no_backups')))
                            else
                              ..._backups!.map((backup) => ListTile(
                                leading: const Icon(Icons.cloud_done),
                                title: Text(DateFormat('dd/MM/yyyy HH:mm').format(backup.createdAt)),
                                subtitle: Text(
                                  '${backup.transactionCount} ${t('transactions')}, ${backup.eventCount} ${t('events')} • ${backup.formattedSize}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.restore),
                                  onPressed: () => _restoreBackup(backup),
                                ),
                              )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
