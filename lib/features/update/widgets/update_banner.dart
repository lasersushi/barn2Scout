import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/update_cubit.dart';

/// Inline strip above the tab content when a full-APK update is available
/// or in flight. Collapses to nothing in every other state.
///
/// Deliberately an inline widget rather than ScaffoldMessenger banners —
/// every tab page has its own Scaffold inside the IndexedStack, which makes
/// messenger-driven banners ambiguous.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, state) {
        final scheme = Theme.of(context).colorScheme;
        final cubit = context.read<UpdateCubit>();

        final Widget? content = switch (state) {
          UpdateAvailable(:final release) => _BannerRow(
              icon: Icons.system_update_outlined,
              title: 'Update ${release.tagName} available',
              subtitle: _firstLine(release.notes),
              actions: [
                TextButton(
                  onPressed: cubit.startDownload,
                  child: const Text('Download'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Dismiss',
                  onPressed: cubit.dismiss,
                ),
              ],
            ),
          UpdateDownloading(:final percent) => _BannerRow(
              icon: Icons.downloading_outlined,
              title: 'Downloading update… $percent%',
              progress: percent / 100,
            ),
          UpdateInstalling() => _BannerRow(
              icon: Icons.install_mobile_outlined,
              title: 'Confirm the install prompt to finish updating',
              actions: [
                TextButton(
                  onPressed: cubit.startDownload,
                  child: const Text('Retry'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Dismiss',
                  onPressed: cubit.dismiss,
                ),
              ],
            ),
          UpdateDownloadFailure(:final message) => _BannerRow(
              icon: Icons.error_outline,
              title: 'Update failed',
              subtitle: message,
              actions: [
                TextButton(
                  onPressed: cubit.startDownload,
                  child: const Text('Retry'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Dismiss',
                  onPressed: cubit.dismiss,
                ),
              ],
            ),
          _ => null,
        };

        if (content == null) return const SizedBox.shrink();

        // The shell Scaffold has no AppBar, so the banner is the topmost
        // widget on screen and must dodge the status bar itself. SafeArea
        // lives inside the visible branch only — wrapping the empty state
        // would pad the whole shell by status-bar height.
        return Material(
          color: scheme.secondaryContainer,
          child: SafeArea(bottom: false, child: content),
        );
      },
    );
  }

  static String? _firstLine(String notes) {
    final line = notes.trim().split('\n').first.trim();
    return line.isEmpty ? null : line;
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.progress,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: scheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSecondaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
        if (progress != null)
          LinearProgressIndicator(value: progress, minHeight: 3),
      ],
    );
  }
}
