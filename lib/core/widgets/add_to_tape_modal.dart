import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/audio_player/domain/audio_track.dart';
import '../../features/collections/presentation/providers/collections_provider.dart';

class AddToTapeModal {
  static void show(
    BuildContext context,
    WidgetRef ref,
    AudioTrack track,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return _AddToTapeContent(track: track);
      },
    );
  }
}

class _AddToTapeContent extends ConsumerStatefulWidget {
  final AudioTrack track;

  const _AddToTapeContent({required this.track});

  @override
  ConsumerState<_AddToTapeContent> createState() => _AddToTapeContentState();
}

class _AddToTapeContentState extends ConsumerState<_AddToTapeContent> {
  final TextEditingController _newTapeController = TextEditingController();
  int _selectedColorIndex = 0;
  bool _isCreatingNew = false;

  @override
  void dispose() {
    _newTapeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsNotifierProvider);
    final tapes = collections.playlists;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.radio_outlined, color: Theme.of(context).primaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'RECORD TO TAPE',
                          style: AppTypography.monoSmall.copyWith(
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a cassette tape to record "${widget.track.title}"',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    _isCreatingNew ? Icons.close : Icons.add_circle_outline,
                    color: AppColors.tapeAmber,
                  ),
                  tooltip: _isCreatingNew ? 'Cancel' : 'Create New Tape',
                  onPressed: () {
                    setState(() {
                      _isCreatingNew = !_isCreatingNew;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Inline New Tape Form
            if (_isCreatingNew) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.tapeAmber.withAlpha(120), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEW CASSETTE MIXTAPE',
                      style: AppTypography.monoSmall.copyWith(
                        color: AppColors.tapeAmber,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newTapeController,
                      autofocus: true,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'e.g., Midnight Drive C-60',
                        hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.obsidian,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Color chips
                    Text('Tape Shell Color:', style: AppTypography.monoSmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(AppColors.spinePalette.length, (idx) {
                        final color = AppColors.spinePalette[idx];
                        final isSelected = _selectedColorIndex == idx;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColorIndex = idx),
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tapeAmber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                        label: Text(
                          'CREATE & RECORD TRACK',
                          style: AppTypography.monoSmall.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () async {
                          final name = _newTapeController.text.trim();
                          if (name.isEmpty) return;

                          final tapeColor = AppColors.spinePalette[_selectedColorIndex];
                          final newTapeId = await ref
                              .read(collectionsNotifierProvider.notifier)
                              .createPlaylist(name, tapeColor.toARGB32());

                          await ref
                              .read(collectionsNotifierProvider.notifier)
                              .addSongToPlaylist(newTapeId, widget.track.id);

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.surfaceCard,
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: AppColors.tapeGreen, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Recorded to "$name"',
                                        style: AppTypography.monoSmall.copyWith(color: AppColors.tapeGreen),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Existing Tapes List
            if (tapes.isEmpty && !_isCreatingNew) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.album_outlined, size: 40, color: AppColors.tapeAmber),
                    const SizedBox(height: 10),
                    Text(
                      'No Mixtapes Created Yet',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create your first cassette tape to start recording songs.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tapeAmber,
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('CREATE FIRST TAPE', style: AppTypography.monoSmall.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setState(() {
                          _isCreatingNew = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: tapes.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.borderSubtle, height: 1),
                  itemBuilder: (context, index) {
                    final tape = tapes[index];
                    final color = Color(tape.colorAccent);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color, width: 1.5),
                        ),
                        child: Center(
                          child: Icon(Icons.subtitles_outlined, color: color, size: 18),
                        ),
                      ),
                      title: Text(
                        tape.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${tape.trackCount} tracks â€¢ Tape Cassette',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fiber_manual_record, color: Colors.red, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              'RECORD',
                              style: AppTypography.monoSmall.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () async {
                        await ref
                            .read(collectionsNotifierProvider.notifier)
                            .addSongToPlaylist(tape.id, widget.track.id);

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.surfaceCard,
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.tapeGreen, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Recorded "${widget.track.title}" to ${tape.name}',
                                      style: AppTypography.monoSmall.copyWith(color: AppColors.tapeGreen),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
