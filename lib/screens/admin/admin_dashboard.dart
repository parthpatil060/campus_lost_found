import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

// ── BROADCAST FEATURE START ──
import '../../models/broadcast_model.dart';
// ── BROADCAST FEATURE END ──

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FirestoreService _fs = FirestoreService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // ── BROADCAST FEATURE START ──
    _tabController = TabController(length: 4, vsync: this);
    // ── BROADCAST FEATURE END ──
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      key: _scaffoldKey,
      drawer: _AdminDrawer(
        name: admin?.name ?? 'Admin',
        email: admin?.email ?? '',
        onAnalytics: () => _tabController.animateTo(0),
        onVerifiers: () => _tabController.animateTo(1),
        onReports: () => _tabController.animateTo(2),
        // ── BROADCAST FEATURE START ──
        onBroadcasts: () => _tabController.animateTo(3),
        // ── BROADCAST FEATURE END ──
        onLogout: () async {
          await context.read<AuthProvider>().signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      body: Container(
        decoration: const BoxDecoration(color: AppTheme.background),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _AdminTopBar(
                  name: admin?.name ?? 'Admin',
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _AdminHero(name: admin?.name ?? 'Admin'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Analytics'),
                      Tab(text: 'Verifiers'),
                      Tab(text: 'Reports'),
                      // ── BROADCAST FEATURE START ──
                      Tab(text: 'Broadcasts'),
                      // ── BROADCAST FEATURE END ──
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _AnalyticsTab(fs: _fs),
                    _VerifiersTab(fs: _fs),
                    _ReportsTab(fs: _fs),
                    // ── BROADCAST FEATURE START ──
                    _AdminBroadcastsTab(fs: _fs),
                    // ── BROADCAST FEATURE END ──
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  final FirestoreService fs;

  const _AnalyticsTab({required this.fs});

  // ── BROADCAST FEATURE START ──
  Future<Map<String, int>> _getAnalyticsWithBroadcasts() async {
    final results = await Future.wait([
      fs.getAnalytics(),
      fs.getActiveBroadcasts().first,
      fs.getAllBroadcasts().first,
    ]);
    final base = results[0] as Map<String, int>;
    final activeBroadcasts = results[1] as List<BroadcastModel>;
    final allBroadcasts = results[2] as List<BroadcastModel>;
    return {
      ...base,
      'activeBroadcasts': activeBroadcasts.length,
      'totalBroadcasts': allBroadcasts.length,
    };
  }
  // ── BROADCAST FEATURE END ──

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      // ── BROADCAST FEATURE START ──
      future: _getAnalyticsWithBroadcasts(),
      // ── BROADCAST FEATURE END ──
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final cards = [
          ('Total Lost', '${data['totalLost'] ?? 0}', Icons.search_off_rounded, AppTheme.error),
          ('Total Found', '${data['totalFound'] ?? 0}', Icons.inventory_2_rounded, AppTheme.success),
          ('Matched', '${data['totalMatched'] ?? 0}', Icons.compare_arrows_rounded, AppTheme.primary),
          ('Total Users', '${data['totalUsers'] ?? 0}', Icons.groups_rounded, const Color(0xFF6A67CE)),
          // ── BROADCAST FEATURE START ──
          ('Active Broadcasts', '${data['activeBroadcasts'] ?? 0}', Icons.campaign_rounded, const Color(0xFF1976D2)),
          ('Total Broadcasts', '${data['totalBroadcasts'] ?? 0}', Icons.broadcast_on_personal_rounded, const Color(0xFF00796B)),
          // ── BROADCAST FEATURE END ──
        ];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final card = cards[index];
                return _MetricCard(
                  title: card.$1,
                  value: card.$2,
                  icon: card.$3,
                  color: card.$4,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Pending Submissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 14),
            _PendingPanel(
              title: 'Waiting for Verifiers (Lost)',
              count: data['pendingLost'] ?? 0,
              color: AppTheme.error,
              icon: Icons.pending_actions_rounded,
            ),
            const SizedBox(height: 12),
            _PendingPanel(
              title: 'New Found Items Submitted',
              count: data['pendingFound'] ?? 0,
              color: AppTheme.success,
              icon: Icons.inventory_2_rounded,
            ),
          ],
        );
      },
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final String name;
  final VoidCallback onMenuTap;

  const _AdminTopBar({required this.name, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Row(
      children: [
        InkWell(
          onTap: onMenuTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? 'A' : initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Control Center',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
              ),
              Text('Managing CampusRetrieve', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminHero extends StatelessWidget {
  final String name;

  const _AdminHero({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.buttonShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.shield_rounded, size: 100, color: Colors.white.withOpacity(0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: AppTheme.glassDecoration(opacity: 0.15, radius: BorderRadius.circular(12)),
                child: const Text(
                  'System Status: Active',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Hello, ${name.split(' ').first}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Monitor analytics, manage systems, and oversee the entire verification queue.',
                style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onAnalytics;
  final VoidCallback onVerifiers;
  final VoidCallback onReports;
  // ── BROADCAST FEATURE START ──
  final VoidCallback onBroadcasts;
  // ── BROADCAST FEATURE END ──
  final VoidCallback onLogout;

  const _AdminDrawer({
    required this.name,
    required this.email,
    required this.onAnalytics,
    required this.onVerifiers,
    required this.onReports,
    // ── BROADCAST FEATURE START ──
    required this.onBroadcasts,
    // ── BROADCAST FEATURE END ──
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Drawer(
      width: 320,
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials.isEmpty ? 'A' : initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
                      ),
                      Text(
                        'System Administrator',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _AdminDrawerItem(label: 'Global Analytics', icon: Icons.analytics_outlined, onTap: onAnalytics),
                _AdminDrawerItem(label: 'Verifier Access', icon: Icons.verified_user_outlined, onTap: onVerifiers),
                _AdminDrawerItem(label: 'Master Reports', icon: Icons.description_outlined, onTap: onReports),
                // ── BROADCAST FEATURE START ──
                _AdminDrawerItem(label: 'Broadcasts Log', icon: Icons.campaign_outlined, onTap: onBroadcasts),
                // ── BROADCAST FEATURE END ──
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _AdminDrawerItem(
              label: 'Sign Out',
              icon: Icons.logout_rounded,
              color: AppTheme.error,
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDrawerItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _AdminDrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.textPrimary;
    return ListTile(
      leading: Icon(icon, color: effectiveColor.withOpacity(0.7)),
      title: Text(
        label,
        style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w700, fontSize: 15),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

class _VerifiersTab extends StatefulWidget {
  final FirestoreService fs;

  const _VerifiersTab({required this.fs});

  @override
  State<_VerifiersTab> createState() => _VerifiersTabState();
}

class _VerifiersTabState extends State<_VerifiersTab> {
  final List<_LocalVerifierDraft> _localVerifiers = [];

  void _showCreateVerifierDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Verifier', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  hint: 'Full Name',
                  controller: nameCtrl,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  hint: 'College Email',
                  controller: emailCtrl,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!value.endsWith('@gst.sies.edu.in')) return 'Must be @gst.sies.edu.in';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  hint: 'Password',
                  controller: passCtrl,
                  isPassword: true,
                  validator: (value) =>
                      value != null && value.length >= 6 ? null : 'Min 6 characters',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            AppButton(
              text: 'Create',
              isLoading: isLoading,
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => isLoading = true);
                final verifier = _LocalVerifierDraft(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );
                Navigator.pop(context);
                this.setState(() => _localVerifiers.insert(0, verifier));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Verifier card created in frontend preview.'),
                  backgroundColor: AppTheme.success,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel verifier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Verifier', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to remove ${verifier.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirestoreService().deleteVerifier(verifier.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Access revoked'),
                  backgroundColor: AppTheme.error,
                ));
              }
            },
            child: const Text('Remove', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLocal(BuildContext context, _LocalVerifierDraft verifier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Verifier', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove the frontend preview for ${verifier.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _localVerifiers.removeWhere((item) => item.id == verifier.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Verifier preview removed.'),
                backgroundColor: AppTheme.error,
              ));
            },
            child: const Text('Remove', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateVerifierDialog(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        label: const Text('New Verifier', style: TextStyle(fontWeight: FontWeight.w700)),
        icon: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: widget.fs.getVerifiers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final verifiers = snapshot.data!;
          final hasAnyVerifier = verifiers.isNotEmpty || _localVerifiers.isNotEmpty;
          if (!hasAnyVerifier) {
            return const _AdminEmptyState(
              icon: Icons.verified_user_outlined,
              title: 'No verifiers yet',
              subtitle: 'Add verifiers to help process the lost and found queue.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
            children: [
              for (final verifier in _localVerifiers)
                _VerifierListTile(
                  title: verifier.name,
                  subtitle: verifier.email,
                  leadingText: verifier.name.isEmpty ? 'V' : verifier.name[0].toUpperCase(),
                  accentIcon: Icons.auto_awesome_rounded,
                  accentColor: const Color(0xFF7C73E6),
                  onDelete: () => _confirmDeleteLocal(context, verifier),
                ),
              for (final verifier in verifiers)
                _VerifierListTile(
                  title: verifier.name,
                  subtitle: verifier.email,
                  leadingText: verifier.name.isEmpty ? 'V' : verifier.name[0].toUpperCase(),
                  onDelete: () => _confirmDelete(context, verifier),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VerifierListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String leadingText;
  final VoidCallback onDelete;
  final IconData? accentIcon;
  final Color? accentColor;

  const _VerifierListTile({
    required this.title,
    required this.subtitle,
    required this.leadingText,
    required this.onDelete,
    this.accentIcon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: accentColor == null
                  ? AppTheme.primaryGradient
                  : LinearGradient(
                      colors: [accentColor!, AppTheme.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    leadingText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                if (accentIcon != null)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Icon(accentIcon, size: 14, color: Colors.white.withOpacity(0.9)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
          ),
        ],
      ),
    );
  }
}

class _LocalVerifierDraft {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  const _LocalVerifierDraft({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });
}

class _ReportsTab extends StatefulWidget {
  final FirestoreService fs;

  const _ReportsTab({required this.fs});

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              dividerColor: Colors.transparent,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Lost Items'),
                Tab(text: 'Found Items'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ReportStreamList(stream: widget.fs.getAllLostItems(), isLost: true),
              _ReportStreamList(stream: widget.fs.getAllFoundItems(), isLost: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportStreamList extends StatelessWidget {
  final Stream<List<dynamic>> stream;
  final bool isLost;

  const _ReportStreamList({required this.stream, required this.isLost});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        if (items.isEmpty) {
          return _AdminEmptyState(
            icon: isLost ? Icons.search_off_rounded : Icons.inventory_2_rounded,
            title: 'Queue is Clear',
            subtitle: 'Waiting for new reports to arrive.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _AdminReportTile(
              title: isLost ? item.itemName : item.description,
              subtitle: isLost ? item.possibleLocations.take(2).join(', ') : item.locationFound,
              status: item.status,
              icon: isLost ? Icons.search_off_rounded : Icons.inventory_2_rounded,
              color: isLost ? AppTheme.error : AppTheme.success,
              photoURL: item.photoURL,
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -1),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PendingPanel extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _PendingPanel({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminReportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final IconData icon;
  final Color color;
  final String? photoURL;

  const _AdminReportTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.color,
    this.photoURL,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: photoURL != null && photoURL!.isNotEmpty
                ? CachedNetworkImage(imageUrl: photoURL!, fit: BoxFit.cover)
                : Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'matched' ? AppTheme.primary.withOpacity(0.1) : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == 'matched' ? AppTheme.primary : color,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AdminEmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Icon(icon, color: AppTheme.textSecondary.withOpacity(0.4), size: 48),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── BROADCAST FEATURE START ──

// ─── ADMIN BROADCASTS TAB ────────────────────────────────────────────────────

/// Admin-only full broadcast log showing ALL broadcasts (active + inactive).
class _AdminBroadcastsTab extends StatelessWidget {
  final FirestoreService fs;

  const _AdminBroadcastsTab({required this.fs});

  void _confirmDeactivate(BuildContext context, BroadcastModel broadcast) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Deactivate Broadcast'),
        content: Text('Force-deactivate broadcast for "${broadcast.itemName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService().deactivateBroadcast(broadcast.broadcastId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Broadcast deactivated.'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: const Text('Deactivate', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BroadcastModel>>(
      stream: fs.getAllBroadcasts(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final broadcasts = snap.data ?? [];
        if (broadcasts.isEmpty) {
          return const _AdminEmptyState(
            icon: Icons.campaign_outlined,
            title: 'No broadcasts yet',
            subtitle: 'Verifiers can create broadcasts from their dashboard.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          itemCount: broadcasts.length,
          itemBuilder: (_, i) => _AdminBroadcastLogTile(
            broadcast: broadcasts[i],
            onDeactivate: broadcasts[i].isActive
                ? () => _confirmDeactivate(context, broadcasts[i])
                : null,
          ),
        );
      },
    );
  }
}

class _AdminBroadcastLogTile extends StatelessWidget {
  final BroadcastModel broadcast;
  final VoidCallback? onDeactivate;

  const _AdminBroadcastLogTile({
    required this.broadcast,
    this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final isLost = broadcast.broadcastType == 'lost_broadcast';
    final typeColor = isLost ? const Color(0xFF1976D2) : const Color(0xFF00796B);
    final typeLabel = isLost ? 'Lost' : 'Found';
    final now = DateTime.now();
    final isExpired = broadcast.expiresAt.isBefore(now);
    final isEffectivelyActive = broadcast.isActive && !isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: item name + type chip + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  broadcast.itemName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: typeColor),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isEffectivelyActive
                      ? AppTheme.success.withOpacity(0.12)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isEffectivelyActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isEffectivelyActive ? AppTheme.success : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Verifier name
          Text(
            'By: ${broadcast.createdByName}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          // Dates row
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 11, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Created ${DateFormat('MMM d, yyyy').format(broadcast.createdAt)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 10),
              Icon(Icons.timer_off_outlined, size: 11, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Expires ${DateFormat('MMM d, yyyy').format(broadcast.expiresAt)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Response count
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 11, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${broadcast.readBy.length} response${broadcast.readBy.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          // Deactivate button (if still active)
          if (onDeactivate != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDeactivate,
                icon: const Icon(Icons.block_outlined, size: 14),
                label: const Text('Deactivate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
// ── BROADCAST FEATURE END ──
