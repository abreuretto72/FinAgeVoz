import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/sync/cloud_sync_service.dart';
import '../utils/localization.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final CloudSyncService _syncService = CloudSyncService();
  
  bool _autoSync = true;
  String _currentLanguage = 'pt_BR';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentLanguage = Localizations.localeOf(context).toString();
  }

  Future<void> _loadSettings() async {
    await _dbService.init();
    setState(() {
      _autoSync = _dbService.getAutoSyncEnabled();
    });
  }

  String t(String key) => AppLocalizations.t(key, _currentLanguage);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('sync_settings') == 'sync_settings' ? 'Sincronização' : t('sync_settings')),
      ),
      body: StreamBuilder(
        stream: _syncService.authStateChanges,
        builder: (context, snapshot) {
          final user = snapshot.data;
          
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Você precisa estar logado para sincronizar.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final user = await _syncService.signInWithGoogle();
                        if (user == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Login cancelado ou falhou. Verifique sua conexão e tente novamente.')),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao fazer login: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Fazer Login com Google'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Info
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  child: user.photoURL == null ? const Icon(Icons.person) : null,
                ),
                title: Text(user.displayName ?? 'Usuário'),
                subtitle: Text(user.email ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await _syncService.signOut();
                  },
                ),
              ),
              const Divider(),
              
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _syncService.isSyncingNotifier,
                        builder: (context, isSyncing, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSyncing ? Icons.sync : Icons.cloud_done,
                                color: isSyncing ? Colors.blue : Colors.green,
                                size: 48,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                isSyncing ? 'Sincronizando...' : 'Sincronizado',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<DateTime?>(
                        valueListenable: _syncService.lastSyncNotifier,
                        builder: (context, lastSync, _) {
                          return Text(
                            lastSync != null 
                                ? 'Última sincronização: ${DateFormat('dd/MM/yyyy HH:mm').format(lastSync.toLocal())}'
                                : 'Nunca sincronizado',
                            style: const TextStyle(color: Colors.grey),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              ElevatedButton.icon(
                onPressed: () async {
                  await _syncService.sync();
                },
                icon: const Icon(Icons.sync),
                label: const Text('Sincronizar Agora'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Settings
              SwitchListTile(
                title: const Text('Sincronização Automática'),
                subtitle: const Text('Sincronizar dados a cada 5 minutos quando conectado'),
                value: _autoSync,
                onChanged: user == null ? null : (value) async {
                  setState(() {
                    _autoSync = value;
                  });
                  await _dbService.setAutoSyncEnabled(value);
                  if (value) {
                    _syncService.startAutoSync();
                  }
                },
              ),
              
              const Divider(),
              
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Como funciona?'),
                subtitle: const Text(
                  'Seus dados são salvos localmente e enviados para a nuvem quando houver conexão. '
                  'Você pode acessar seus dados em outros dispositivos fazendo login com a mesma conta.'
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
