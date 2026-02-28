import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../data/mock_data.dart';
import '../../models/conversation.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stories = MockData.conversations
        .where((c) => c.type == 'cerita' || c.type == 'casual')
        .toList();

    return Scaffold(
      backgroundColor: KampungCareTheme.warmWhite,
      appBar: AppBar(title: const Text('Cerita Dikongsi')),
      body: stories.isEmpty
          ? const Center(
              child: Text(
                'Belum ada cerita yang dikongsi',
                style: TextStyle(
                    fontSize: 20, color: KampungCareTheme.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                return _StoryCard(
                  story: story,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            _StoryTranscriptScreen(story: story),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Conversation story;
  final VoidCallback onTap;

  const _StoryCard({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = BmStrings.malayDate(story.timestamp);
    final preview =
        story.messages.length > 1 ? story.messages[1].content : '';
    final typeLabel = story.type == 'cerita' ? 'Cerita' : 'Sembang';

    return Semantics(
      label: '$typeLabel pada $dateStr. Tekan untuk baca selanjutnya.',
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: story.type == 'cerita'
                        ? KampungCareTheme.warningAmber
                        : KampungCareTheme.calmBlue,
                    width: 4,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        story.type == 'cerita'
                            ? Icons.menu_book
                            : Icons.chat_bubble_outline,
                        size: 24,
                        color: story.type == 'cerita'
                            ? KampungCareTheme.warningAmber
                            : KampungCareTheme.calmBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: story.type == 'cerita'
                              ? KampungCareTheme.warningAmber
                              : KampungCareTheme.calmBlue,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: const TextStyle(
                            fontSize: 16,
                            color: KampungCareTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (story.aiNotes.isNotEmpty)
                    Text(
                      story.aiNotes,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '"$preview"',
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: KampungCareTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Baca selanjutnya',
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Baca Selanjutnya \u2192',
                            style: TextStyle(
                                fontSize: 18,
                                color: KampungCareTheme.calmBlue,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full transcript detail view.
/// Shows the conversation as narrative paragraphs on a cream background
/// with generous line spacing for comfortable reading.
class _StoryTranscriptScreen extends StatelessWidget {
  final Conversation story;

  const _StoryTranscriptScreen({required this.story});

  /// Convert chat messages into narrative paragraphs.
  /// Groups assistant and user messages into a flowing story format.
  List<_NarrativeParagraph> _buildNarrative() {
    final paragraphs = <_NarrativeParagraph>[];

    for (final msg in story.messages) {
      final isAi = msg.role == 'assistant';
      final speaker = isAi ? 'Sayang' : 'Mak Cik Siti';
      paragraphs.add(_NarrativeParagraph(
        speaker: speaker,
        text: msg.content,
        isAi: isAi,
      ));
    }

    return paragraphs;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = BmStrings.malayDate(story.timestamp);
    final typeLabel = story.type == 'cerita' ? 'Cerita' : 'Sembang';
    final narrativeParagraphs = _buildNarrative();
    final durationMinutes = (story.duration / 60).ceil();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // warm cream
      body: CustomScrollView(
        slivers: [
          // Sticky app bar with back button
          SliverAppBar(
            backgroundColor: KampungCareTheme.warmWhite,
            foregroundColor: KampungCareTheme.textPrimary,
            elevation: 0,
            pinned: true,
            leading: Semantics(
              button: true,
              label: 'Kembali ke senarai cerita',
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 28),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
              ),
            ),
            title: Text(
              typeLabel,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: KampungCareTheme.textPrimary,
              ),
            ),
            centerTitle: true,
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPadding,
              vertical: 16,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Date header
                Semantics(
                  header: true,
                  child: Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: AppConstants.minTextSize,
                      color: KampungCareTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Title from AI notes
                if (story.aiNotes.isNotEmpty) ...[
                  Text(
                    story.aiNotes,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: KampungCareTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Duration
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 20, color: KampungCareTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '$durationMinutes minit perbualan',
                      style: const TextStyle(
                        fontSize: 18,
                        color: KampungCareTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Decorative divider
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: story.type == 'cerita'
                        ? KampungCareTheme.warningAmber
                        : KampungCareTheme.calmBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 24),

                // Narrative paragraphs
                ...narrativeParagraphs.map((p) => _NarrativeParagraphWidget(
                      paragraph: p,
                    )),

                const SizedBox(height: 32),

                // Bottom divider
                Center(
                  child: Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: KampungCareTheme.textSecondary
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // AI notes footer
                if (story.aiNotes.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KampungCareTheme.calmBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            KampungCareTheme.calmBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 20,
                                color: KampungCareTheme.calmBlue),
                            SizedBox(width: 8),
                            Text(
                              'Nota AI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: KampungCareTheme.calmBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          story.aiNotes,
                          style: const TextStyle(
                            fontSize: 18,
                            color: KampungCareTheme.textSecondary,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Data model for a narrative paragraph in the transcript.
class _NarrativeParagraph {
  final String speaker;
  final String text;
  final bool isAi;

  const _NarrativeParagraph({
    required this.speaker,
    required this.text,
    required this.isAi,
  });
}

/// Widget that renders a single narrative paragraph.
/// Uses 22sp text with 1.8 line spacing for comfortable elderly reading.
class _NarrativeParagraphWidget extends StatelessWidget {
  final _NarrativeParagraph paragraph;

  const _NarrativeParagraphWidget({required this.paragraph});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${paragraph.speaker} berkata: ${paragraph.text}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Speaker name
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: paragraph.isAi
                        ? KampungCareTheme.calmBlue
                        : KampungCareTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  paragraph.speaker,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: paragraph.isAi
                        ? KampungCareTheme.calmBlue
                        : KampungCareTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Narrative text with generous line spacing
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                paragraph.text,
                style: const TextStyle(
                  fontSize: 22,
                  color: KampungCareTheme.textPrimary,
                  height: 1.8,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
