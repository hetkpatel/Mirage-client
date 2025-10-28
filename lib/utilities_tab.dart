import 'package:flutter/material.dart';
import 'package:mirageclient/MirageClient.dart';
import 'package:mirageclient/models/mirage_utility.dart';

class UtilitiesTab extends StatefulWidget {
  const UtilitiesTab({super.key});

  @override
  State<UtilitiesTab> createState() => _UtilitiesTabState();
}

class _UtilitiesTabState extends State<UtilitiesTab> {
  List<MirageUtilityItem> _utilities = const [];
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _usage;

  @override
  void initState() {
    super.initState();
    _loadUtilities();
  }

  Future<void> _loadUtilities() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        MirageClient.getUtilities(),
        MirageClient.getDiskUsage(),
      ]);
      if (!mounted) return;
      setState(() {
        _utilities = results[0] as List<MirageUtilityItem>;
        _usage = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Utilities are unavailable right now.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _UtilitiesError(
        message: _error!,
        onRetry: _loadUtilities,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUtilities,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_usage != null) _StorageCard(usage: _usage!),
          ..._utilities.map(
            (utility) => _UtilityTile(
              item: utility,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(utility.title),
                      content: Text(
                        'This quick action is coming soon. Stay tuned!',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityTile extends StatelessWidget {
  const _UtilityTile({
    required this.item,
    required this.onTap,
  });

  final MirageUtilityItem item;
  final VoidCallback onTap;

  IconData _iconFromName(String name) {
    switch (name) {
      case 'lock':
        return Icons.lock_outline_rounded;
      case 'scanner':
        return Icons.document_scanner_outlined;
      case 'print':
        return Icons.print_outlined;
      case 'storage':
        return Icons.storage_rounded;
      case 'spark':
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _iconFromName(item.iconName),
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(item.title),
        subtitle: Text(item.subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.badge!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _UtilitiesError extends StatelessWidget {
  const _UtilitiesError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.settings_suggest_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.usage});

  final Map<String, dynamic> usage;

  @override
  Widget build(BuildContext context) {
    final used = (usage['used'] as num?)?.toDouble() ?? 0;
    final total = (usage['total'] as num?)?.toDouble() ?? 1;
    final percentage =
        total == 0 ? 0.0 : (used / total).clamp(0, 1).toDouble();
    final usedReadable = usage['usedReadable'] as String? ??
        '${(used / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    final totalReadable = usage['totalReadable'] as String? ??
        '${(total / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('$usedReadable of $totalReadable used'),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 10.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
