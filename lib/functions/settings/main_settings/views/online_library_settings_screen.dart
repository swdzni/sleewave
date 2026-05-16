import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/files/setup_guide_opener.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/online_library_section.dart';

class OnlineLibrarySettingsScreen extends ConsumerStatefulWidget {
  const OnlineLibrarySettingsScreen({super.key});

  @override
  ConsumerState<OnlineLibrarySettingsScreen> createState() =>
      _OnlineLibrarySettingsScreenState();
}

class _OnlineLibrarySettingsScreenState
    extends ConsumerState<OnlineLibrarySettingsScreen> {
  final _urlController = TextEditingController();
  final _opener = SetupGuideOpener();
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(settingsViewModelProvider).load());
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(settingsViewModelProvider);
    final state = vm.state;
    if (!_seeded) {
      _urlController.text = state.settings.backendBaseUrl ?? '';
      _seeded = true;
    }
    return AppScaffold(
      child: ListView(
        children: [
          _SettingsSubHeader(
            title: 'Online Library',
            onBack: () => context.pop(),
          ),
          const SizedBox(height: 18),
          OnlineLibrarySection(
            status: state.status,
            sources: state.sources,
            urlController: _urlController,
            checking: state.checking,
            clearingCache: state.clearingCache,
            clearingSongs: state.clearingSongs,
            httpWarning: state.httpWarning,
            onCheck: () => vm.checkUrl(_urlController.text),
            onClear: () async {
              _urlController.clear();
              await vm.clear();
            },
            onClearCache: () async {
              final clear = await _confirm(
                title: 'Clear server cache?',
                message: 'This removes cached audio files from the server.',
                action: 'Clear',
              );
              if (clear) {
                await vm.clearServerCache();
              }
            },
            onClearSongs: () async {
              final clear = await _confirm(
                title: 'Clear all server songs?',
                message:
                    'This clears cached songs, the server track catalog, and device-library records.',
                action: 'Clear all',
              );
              if (clear) {
                await vm.clearServerSongs();
              }
            },
            onOpenGuide: () async {
              await _opener.open(AppConfig.backendSetupRepoUrl);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Setup guide link copied or opened.'),
                  ),
                );
              }
            },
          ),
          if (state.message != null) ...[
            const SizedBox(height: 16),
            Text(state.message!),
          ],
        ],
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _SettingsSubHeader extends StatelessWidget {
  const _SettingsSubHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineLarge),
        ),
      ],
    );
  }
}
