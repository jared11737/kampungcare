import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';

/// 7-screen onboarding flow for KampungCare.
/// Designed elderly-first: large text, large buttons, high contrast, BM text.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 7;

  // ----- Page 1: Welcome -----
  bool _isElderly = true; // true = "Saya sendiri", false = "Untuk ibu/bapa"

  // ----- Page 2: Profile -----
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();

  // ----- Page 3: Health Conditions -----
  final Map<String, bool> _conditions = {
    'Diabetes': false,
    'Darah Tinggi': false,
    'Sakit Jantung': false,
    'Arthritis': false,
    'Asma': false,
    'Kolesterol Tinggi': false,
  };
  final _otherConditionController = TextEditingController();

  // ----- Page 4: Medications -----
  final List<_MedicationEntry> _medications = [];
  final _medNameController = TextEditingController();
  final _medDosageController = TextEditingController();
  final Set<String> _selectedMedTimes = {};

  // ----- Page 5: Emergency Contacts -----
  final _caregiverNameController = TextEditingController();
  final _caregiverPhoneController = TextEditingController();
  String _caregiverRelation = 'Anak';
  final _buddyNameController = TextEditingController();
  final _buddyPhoneController = TextEditingController();

  // ----- Page 6: Preferences -----
  TimeOfDay _morningCheckIn = const TimeOfDay(hour: 6, minute: 30);
  TimeOfDay _eveningCheckIn = const TimeOfDay(hour: 20, minute: 0);
  double _voiceSpeed = 0.45;
  double _textSizePreview = 20.0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _otherConditionController.dispose();
    _medNameController.dispose();
    _medDosageController.dispose();
    _caregiverNameController.dispose();
    _caregiverPhoneController.dispose();
    _buddyNameController.dispose();
    _buddyPhoneController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: AppConstants.transitionDuration,
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    HapticFeedback.mediumImpact();
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  void _previousPage() {
    HapticFeedback.mediumImpact();
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  void _skipToLogin() {
    HapticFeedback.mediumImpact();
    context.go(AppRoutes.login);
  }

  void _finishOnboarding() {
    HapticFeedback.mediumImpact();
    context.go(AppRoutes.login);
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KampungCareTheme.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressBar(),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildWelcomePage(),
                  _buildProfilePage(),
                  _buildHealthPage(),
                  _buildMedicationsPage(),
                  _buildEmergencyPage(),
                  _buildPreferencesPage(),
                  _buildCompletePage(),
                ],
              ),
            ),

            // Navigation buttons (shown on pages 2-6)
            if (_currentPage > 0 && _currentPage < _totalPages - 1)
              _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  // =============================================
  // PROGRESS BAR
  // =============================================
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenPadding,
        vertical: 16,
      ),
      child: Column(
        children: [
          // Step text
          Semantics(
            label: 'Langkah ${_currentPage + 1} daripada $_totalPages',
            child: Text(
              '${_currentPage + 1} / $_totalPages',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: KampungCareTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(
                KampungCareTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // PAGE 1: WELCOME
  // =============================================
  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // Heart icon
          const Icon(
            Icons.favorite,
            size: 100,
            color: KampungCareTheme.primaryGreen,
          ),
          const SizedBox(height: 24),
          // Title
          const Text(
            'Selamat Datang ke\nKampungCare',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: KampungCareTheme.primaryGreen,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Siapa yang akan guna app ini?',
            style: TextStyle(
              fontSize: 22,
              color: KampungCareTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // "Saya sendiri" button
          Semantics(
            button: true,
            label: 'Saya sendiri. Untuk warga emas.',
            child: _buildLargeChoiceButton(
              label: 'Saya sendiri',
              subtitle: 'Saya warga emas',
              icon: Icons.elderly,
              isSelected: _isElderly,
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _isElderly = true);
                _nextPage();
              },
            ),
          ),
          const SizedBox(height: 16),

          // "Untuk ibu/bapa saya" button
          Semantics(
            button: true,
            label: 'Untuk ibu atau bapa saya. Untuk penjaga.',
            child: _buildLargeChoiceButton(
              label: 'Untuk ibu/bapa saya',
              subtitle: 'Saya penjaga',
              icon: Icons.supervisor_account,
              isSelected: !_isElderly,
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _isElderly = false);
                _nextPage();
              },
            ),
          ),
          const SizedBox(height: 40),

          // Skip button for demo
          Semantics(
            button: true,
            label: 'Skip. Guna data demo untuk pembentangan.',
            child: TextButton(
              onPressed: _skipToLogin,
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Skip \u2014 Guna Data Demo',
                style: TextStyle(
                  fontSize: 20,
                  color: KampungCareTheme.calmBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLargeChoiceButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color borderColor =
        isSelected ? KampungCareTheme.primaryGreen : Colors.grey.shade400;
    final Color bgColor = isSelected
        ? KampungCareTheme.primaryGreen.withValues(alpha: 0.08)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, size: 44, color: KampungCareTheme.primaryGreen),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: KampungCareTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 18,
                        color: KampungCareTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 24,
                color: KampungCareTheme.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================
  // PAGE 2: PROFILE
  // =============================================
  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Maklumat Peribadi',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: KampungCareTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isElderly
                ? 'Isi maklumat anda'
                : 'Isi maklumat ibu/bapa anda',
            style: const TextStyle(
              fontSize: 20,
              color: KampungCareTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Name
          const Text(
            'Nama',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: KampungCareTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Nama penuh',
            textField: true,
            child: SizedBox(
              height: 64,
              child: TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 24),
                decoration: const InputDecoration(
                  hintText: 'Nama penuh',
                  prefixIcon: Icon(Icons.person, size: 28),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Age
          const Text(
            'Umur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: KampungCareTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Umur',
            textField: true,
            child: SizedBox(
              height: 64,
              child: TextField(
                controller: _ageController,
                style: const TextStyle(fontSize: 24),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Umur',
                  prefixIcon: Icon(Icons.cake, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Phone
          const Text(
            'Nombor Telefon',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: KampungCareTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Nombor telefon dengan awalan +60',
            textField: true,
            child: SizedBox(
              height: 64,
              child: TextField(
                controller: _phoneController,
                style: const TextStyle(fontSize: 24),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+60121234567',
                  prefixIcon: Icon(Icons.phone, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =============================================
  // PAGE 3: HEALTH CONDITIONS
  // =============================================
  Widget _buildHealthPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Penyakit Sedia Ada',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: KampungCareTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih yang berkenaan',
            style: TextStyle(
              fontSize: 20,
              color: KampungCareTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Condition checkboxes
          ..._conditions.entries.map((entry) {
            return Semantics(
              label: '${entry.key}. ${entry.value ? "Dipilih" : "Tidak dipilih"}',
              toggled: entry.value,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _conditions[entry.key] = !entry.value;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: entry.value
                          ? KampungCareTheme.primaryGreen.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: entry.value
                            ? KampungCareTheme.primaryGreen
                            : Colors.grey.shade300,
                        width: entry.value ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: Checkbox(
                            value: entry.value,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _conditions[entry.key] = val ?? false;
                              });
                            },
                            activeColor: KampungCareTheme.primaryGreen,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 22,
                              color: KampungCareTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // "Lain-lain" free text
          const Text(
            'Lain-lain',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: KampungCareTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Penyakit lain yang tidak tersenarai',
            textField: true,
            child: SizedBox(
              height: 64,
              child: TextField(
                controller: _otherConditionController,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  hintText: 'Contoh: Gout, Migrain',
                  prefixIcon: Icon(Icons.edit_note, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =============================================
  // PAGE 4: MEDICATIONS
  // =============================================
  Widget _buildMedicationsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ubat Harian',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: KampungCareTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Senaraikan ubat yang diambil setiap hari',
            style: TextStyle(
              fontSize: 20,
              color: KampungCareTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Add medication form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Med name
                Semantics(
                  label: 'Nama ubat',
                  textField: true,
                  child: SizedBox(
                    height: 64,
                    child: TextField(
                      controller: _medNameController,
                      style: const TextStyle(fontSize: 22),
                      decoration: const InputDecoration(
                        hintText: 'Nama ubat',
                        prefixIcon: Icon(Icons.medication, size: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Dosage
                Semantics(
                  label: 'Dos ubat',
                  textField: true,
                  child: SizedBox(
                    height: 64,
                    child: TextField(
                      controller: _medDosageController,
                      style: const TextStyle(fontSize: 22),
                      decoration: const InputDecoration(
                        hintText: 'Dos (cth: 500mg)',
                        prefixIcon: Icon(Icons.scale, size: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Time chips
                const Text(
                  'Masa pengambilan:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: KampungCareTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: ['Pagi', 'Tengah Hari', 'Malam'].map((time) {
                    final selected = _selectedMedTimes.contains(time);
                    return Semantics(
                      label: '$time. ${selected ? "Dipilih" : "Tidak dipilih"}',
                      toggled: selected,
                      child: FilterChip(
                        label: Text(
                          time,
                          style: TextStyle(
                            fontSize: 20,
                            color: selected
                                ? Colors.white
                                : KampungCareTheme.textPrimary,
                          ),
                        ),
                        selected: selected,
                        selectedColor: KampungCareTheme.primaryGreen,
                        checkmarkColor: Colors.white,
                        backgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        onSelected: (val) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (val) {
                              _selectedMedTimes.add(time);
                            } else {
                              _selectedMedTimes.remove(time);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Add medication button
                Semantics(
                  button: true,
                  label: 'Tambah ubat ke senarai',
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _addMedication,
                      icon: const Icon(Icons.add, size: 28),
                      label: const Text(
                        'Tambah Ubat',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KampungCareTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // "Guna contoh" demo button
          Semantics(
            button: true,
            label: 'Guna contoh ubat untuk demo',
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _fillDemoMedications,
                icon: const Icon(Icons.auto_fix_high, size: 24),
                label: const Text(
                  'Guna contoh',
                  style: TextStyle(fontSize: 20),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KampungCareTheme.calmBlue,
                  side: const BorderSide(color: KampungCareTheme.calmBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // List of added medications
          if (_medications.isNotEmpty) ...[
            Text(
              'Ubat ditambah (${_medications.length}):',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: KampungCareTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ..._medications.asMap().entries.map((entry) {
              final index = entry.key;
              final med = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  label:
                      '${med.name} ${med.dosage}. ${med.times.join(", ")}. Tekan untuk buang.',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: KampungCareTheme.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.medication,
                          color: KampungCareTheme.primaryGreen,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${med.name} ${med.dosage}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: KampungCareTheme.textPrimary,
                                ),
                              ),
                              Text(
                                med.times.join(', '),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: KampungCareTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _medications.removeAt(index);
                            });
                          },
                          icon: const Icon(
                            Icons.close,
                            color: KampungCareTheme.urgentRed,
                            size: 28,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _addMedication() {
    HapticFeedback.mediumImpact();
    final name = _medNameController.text.trim();
    final dosage = _medDosageController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _medications.add(_MedicationEntry(
        name: name,
        dosage: dosage,
        times: _selectedMedTimes.toList(),
      ));
      _medNameController.clear();
      _medDosageController.clear();
      _selectedMedTimes.clear();
    });
  }

  void _fillDemoMedications() {
    HapticFeedback.mediumImpact();
    setState(() {
      _medications.clear();
      _medications.addAll([
        _MedicationEntry(
          name: 'Metformin',
          dosage: '500mg',
          times: ['Pagi', 'Malam'],
        ),
        _MedicationEntry(
          name: 'Amlodipine',
          dosage: '5mg',
          times: ['Pagi'],
        ),
        _MedicationEntry(
          name: 'Glucosamine',
          dosage: '500mg',
          times: ['Tengah Hari'],
        ),
      ]);
    });
  }

  // =============================================
  // PAGE 5: EMERGENCY CONTACTS
  // =============================================
  Widget _buildEmergencyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kenalan Kecemasan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: KampungCareTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Siapa yang perlu dihubungi jika berlaku kecemasan?',
            style: TextStyle(
              fontSize: 20,
              color: KampungCareTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Caregiver section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.supervisor_account,
                      color: KampungCareTheme.calmBlue,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Penjaga',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: KampungCareTheme.calmBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Caregiver name
                Semantics(
                  label: 'Nama penjaga',
                  textField: true,
                  child: SizedBox(
                    height: 64,
                    child: TextField(
                      controller: _caregiverNameController,
                      style: const TextStyle(fontSize: 22),
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Nama penjaga',
                        prefixIcon: Icon(Icons.person, size: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Caregiver phone
                Semantics(
                  label: 'Nombor telefon penjaga',
                  textField: true,
                  child: SizedBox(
                    height: 64,
                    child: TextField(
                      controller: _caregiverPhoneController,
                      style: const TextStyle(fontSize: 22),
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+60121234567',
                        prefixIcon: Icon(Icons.phone, size: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Relationship dropdown
                const Text(
                  'Hubungan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: KampungCareTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Pilih hubungan dengan penjaga. Pilihan semasa: $_caregiverRelation',
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _caregiverRelation,
                        isExpanded: true,
                        style: const TextStyle(
                          fontSize: 22,
                          color: KampungCareTheme.textPrimary,
                        ),
                        items: ['Anak', 'Pasangan', 'Adik-beradik', 'Lain-lain']
                            .map((rel) => DropdownMenuItem(
                                  value: rel,
                                  child: Text(rel),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            HapticFeedback.selectionClick();
                            setState(() => _caregiverRelation = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Buddy section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: KampungCareTheme.warningAmber,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Buddy (Jiran / Kawan)',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: KampungCareTheme.warningAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Buddy name
                Semantics(
                  label: 'Nama buddy',
                  textField: true,
                  child: SizedBox(
                    height: 64,
                    child: TextField(
                      controller: _buddyNameController,
                      style: const TextStyle(fontSize: 22),
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Nama jiran / kawan',
                        prefixIcon: Icon(Icons.person, size: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Buddy phone
                Semantics(
                  label: 'Nombor telefon buddy',
                  textField: true,
                  child: SizedBox(
                    height: 64,
                    child: TextField(
                      controller: _buddyPhoneController,
                      style: const TextStyle(fontSize: 22),
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+60121234567',
                        prefixIcon: Icon(Icons.phone, size: 28),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Send SMS invitation (mock)
          Semantics(
            button: true,
            label: 'Hantar jemputan SMS kepada penjaga dan buddy',
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'SMS dihantar!',
                        style: TextStyle(fontSize: 20),
                      ),
                      backgroundColor: KampungCareTheme.primaryGreen,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.sms, size: 28),
                label: const Text(
                  'Hantar jemputan SMS',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KampungCareTheme.primaryGreen,
                  side: const BorderSide(
                    color: KampungCareTheme.primaryGreen,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =============================================
  // PAGE 6: PREFERENCES
  // =============================================
  Widget _buildPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tetapan Pilihan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: KampungCareTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sesuaikan ikut keselesaan anda',
            style: TextStyle(
              fontSize: 20,
              color: KampungCareTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Morning check-in time
          _buildTimePickerRow(
            label: 'Check-in Pagi',
            icon: Icons.wb_sunny,
            iconColor: KampungCareTheme.warningAmber,
            time: _morningCheckIn,
            onTap: () async {
              HapticFeedback.mediumImpact();
              final picked = await showTimePicker(
                context: context,
                initialTime: _morningCheckIn,
                helpText: 'Pilih masa check-in pagi',
                confirmText: 'OK',
                cancelText: 'Batal',
              );
              if (picked != null) {
                setState(() => _morningCheckIn = picked);
              }
            },
          ),
          const SizedBox(height: 16),

          // Evening check-in time
          _buildTimePickerRow(
            label: 'Check-in Malam',
            icon: Icons.nights_stay,
            iconColor: KampungCareTheme.calmBlue,
            time: _eveningCheckIn,
            onTap: () async {
              HapticFeedback.mediumImpact();
              final picked = await showTimePicker(
                context: context,
                initialTime: _eveningCheckIn,
                helpText: 'Pilih masa check-in malam',
                confirmText: 'OK',
                cancelText: 'Batal',
              );
              if (picked != null) {
                setState(() => _eveningCheckIn = picked);
              }
            },
          ),
          const SizedBox(height: 32),

          // Voice speed slider
          const Text(
            'Kelajuan Suara',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: KampungCareTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Kelajuan suara. Laraskan dari perlahan ke cepat.',
            slider: true,
            value: _voiceSpeedLabel(_voiceSpeed),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 14,
                    ),
                    activeTrackColor: KampungCareTheme.primaryGreen,
                    inactiveTrackColor: Colors.grey.shade300,
                    thumbColor: KampungCareTheme.primaryGreen,
                  ),
                  child: Slider(
                    value: _voiceSpeed,
                    min: 0.3,
                    max: 0.8,
                    divisions: 5,
                    label: _voiceSpeedLabel(_voiceSpeed),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _voiceSpeed = val);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Perlahan',
                      style: TextStyle(
                        fontSize: 18,
                        color: KampungCareTheme.textSecondary,
                      ),
                    ),
                    Text(
                      'Sederhana',
                      style: TextStyle(
                        fontSize: 18,
                        color: KampungCareTheme.textSecondary,
                      ),
                    ),
                    Text(
                      'Cepat',
                      style: TextStyle(
                        fontSize: 18,
                        color: KampungCareTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Text size preview
          const Text(
            'Saiz Teks',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: KampungCareTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Saiz teks. Laraskan untuk melihat pratonton.',
            slider: true,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 14,
                ),
                activeTrackColor: KampungCareTheme.calmBlue,
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: KampungCareTheme.calmBlue,
              ),
              child: Slider(
                value: _textSizePreview,
                min: 16.0,
                max: 32.0,
                divisions: 8,
                label: '${_textSizePreview.round()}sp',
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _textSizePreview = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pratonton:',
                  style: TextStyle(
                    fontSize: 18,
                    color: KampungCareTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selamat pagi! Apa khabar hari ini?',
                  style: TextStyle(
                    fontSize: _textSizePreview,
                    color: KampungCareTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTimePickerRow({
    required String label,
    required IconData icon,
    required Color iconColor,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Semantics(
      button: true,
      label: '$label. Masa semasa: $timeStr. Tekan untuk tukar.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(icon, size: 36, color: iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: KampungCareTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _voiceSpeedLabel(double speed) {
    if (speed <= 0.4) return 'Perlahan';
    if (speed <= 0.6) return 'Sederhana';
    return 'Cepat';
  }

  // =============================================
  // PAGE 7: COMPLETE
  // =============================================
  Widget _buildCompletePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          // Green checkmark
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: KampungCareTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: KampungCareTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Semua siap!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: KampungCareTheme.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Esok pagi, Sayang akan telefon\nMak Cik untuk tanya khabar.',
            style: TextStyle(
              fontSize: 22,
              color: KampungCareTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Icon(
            Icons.favorite,
            size: 48,
            color: KampungCareTheme.urgentRed,
          ),
          const SizedBox(height: 48),

          // "Mula" button
          Semantics(
            button: true,
            label: 'Mula menggunakan KampungCare',
            child: SizedBox(
              width: double.infinity,
              height: 72,
              child: ElevatedButton(
                onPressed: _finishOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KampungCareTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Mula',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =============================================
  // NAVIGATION BUTTONS (Pages 2-6)
  // =============================================
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPadding,
        12,
        AppConstants.screenPadding,
        20,
      ),
      decoration: BoxDecoration(
        color: KampungCareTheme.warmWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // "Kembali" (Back) button
          Expanded(
            child: Semantics(
              button: true,
              label: 'Kembali ke halaman sebelumnya',
              child: SizedBox(
                height: 64,
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KampungCareTheme.textSecondary,
                    side: BorderSide(color: Colors.grey.shade400, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kembali',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // "Seterusnya" (Next) button
          Expanded(
            child: Semantics(
              button: true,
              label: 'Seterusnya ke halaman seterusnya',
              child: SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KampungCareTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Seterusnya',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple data class for medication entries during onboarding.
class _MedicationEntry {
  final String name;
  final String dosage;
  final List<String> times;

  _MedicationEntry({
    required this.name,
    required this.dosage,
    required this.times,
  });
}
