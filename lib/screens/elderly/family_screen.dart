import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/care_network.dart';
import '../../providers/settings_provider.dart';
import '../../services/service_locator.dart';

/// Family and neighbours screen.
/// Shows care network contacts with large "Panggil" (Call) buttons.
class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  CareNetwork? _network;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCareNetwork();
  }

  Future<void> _loadCareNetwork() async {
    final user = ServiceLocator.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final network =
          await ServiceLocator.database.getCareNetwork(user.uid);
      setState(() {
        _network = network;
        _isLoading = false;
      });
    } catch (e) {
      print('[FamilyScreen] Error loading network: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makeCall(String phone) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.isEnglish ? 'Unable to make call' : 'Tidak dapat membuat panggilan',
                style: const TextStyle(fontSize: 20),
              ),
              backgroundColor: KampungCareTheme.urgentRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      print('[FamilyScreen] Error making call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider);

    final allContacts = <CareContact>[];
    if (_network != null) {
      allContacts.addAll(_network!.caregivers);
      allContacts.addAll(_network!.buddies);
    }

    return Scaffold(
      backgroundColor: KampungCareTheme.warmWhite,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: KampungCareTheme.textOnDark,
        leading: Semantics(
          button: true,
          label: 'Kembali ke halaman utama',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(AppRoutes.elderlyHome);
            },
          ),
        ),
        title: Text(
          S.isEnglish ? 'Family & Neighbours' : 'Keluarga & Jiran',
          style: const TextStyle(
            fontSize: AppConstants.headerTextSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF6A1B9A),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.silaTunggu,
                    style: const TextStyle(
                      fontSize: AppConstants.minTextSize,
                      color: KampungCareTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : allContacts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      S.isEnglish
                          ? 'No contacts in care network'
                          : 'Tiada kenalan dalam rangkaian penjagaan',
                      style: const TextStyle(
                        fontSize: AppConstants.minTextSize,
                        color: KampungCareTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Caregivers section
                      if (_network!.caregivers.isNotEmpty) ...[
                        _SectionHeader(
                          title: S.isEnglish ? 'Family' : 'Keluarga',
                          icon: Icons.family_restroom_rounded,
                        ),
                        const SizedBox(height: 12),
                        ..._network!.caregivers.map(
                          (contact) => _ContactCard(
                            contact: contact,
                            onCall: () => _makeCall(contact.phone),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Buddies section
                      if (_network!.buddies.isNotEmpty) ...[
                        _SectionHeader(
                          title: S.isEnglish ? 'Neighbours' : 'Jiran',
                          icon: Icons.people_rounded,
                        ),
                        const SizedBox(height: 12),
                        ..._network!.buddies.map(
                          (contact) => _ContactCard(
                            contact: contact,
                            onCall: () => _makeCall(contact.phone),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}

/// Section header with icon and title.
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 28, color: KampungCareTheme.textPrimary),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: KampungCareTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Contact card with name, relation, phone, and large Call button.
class _ContactCard extends StatelessWidget {
  final CareContact contact;
  final VoidCallback onCall;

  const _ContactCard({
    required this.contact,
    required this.onCall,
  });

  IconData _getRelationIcon() {
    final relation = contact.relation.toLowerCase();
    if (relation.contains('anak') || relation.contains('daughter') ||
        relation.contains('son')) {
      return Icons.child_care_rounded;
    } else if (relation.contains('jiran') || relation.contains('neighbour')) {
      return Icons.house_rounded;
    } else if (relation.contains('suami') || relation.contains('isteri')) {
      return Icons.favorite_rounded;
    }
    return Icons.person_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: S.isEnglish
          ? '${contact.name}, ${contact.relation}. Tap Call to contact.'
          : '${contact.name}, ${contact.relation}. Tekan Panggil untuk hubungi.',
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Avatar circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getRelationIcon(),
                  size: 32,
                  color: const Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(width: 16),

              // Name and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: KampungCareTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.relation,
                      style: const TextStyle(
                        fontSize: AppConstants.minTextSize,
                        color: KampungCareTheme.textSecondary,
                      ),
                    ),
                    if (contact.distance != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${contact.distance} ${S.isEnglish ? "from home" : "dari rumah"}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: KampungCareTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Call button
              Semantics(
                button: true,
                label: S.isEnglish
                    ? 'Call ${contact.name}'
                    : 'Panggil ${contact.name}',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onCall,
                    child: Container(
                      width: 80,
                      height: 64,
                      decoration: BoxDecoration(
                        color: KampungCareTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: KampungCareTheme.primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.call_rounded,
                              size: 28, color: Colors.white),
                          const SizedBox(height: 2),
                          Text(
                            S.isEnglish ? 'Call' : 'Panggil',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
