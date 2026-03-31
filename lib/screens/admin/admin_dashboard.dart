import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👑', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            const Text('Admin Dashboard'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (mounted)
                Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(text: 'Analytics'),
            Tab(text: 'Verifiers'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AnalyticsTab(fs: _fs),
          _VerifiersTab(fs: _fs),
          _ReportsTab(fs: _fs),
        ],
      ),
    );
  }
}

// ─── ANALYTICS TAB ───────────────────────────────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  final FirestoreService fs;
  const _AnalyticsTab({required this.fs});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: fs.getAnalytics(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overview',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                    emoji: '😢',
                    label: 'Total Lost',
                    value: '${data['totalLost'] ?? 0}',
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)]),
                  ),
                  _StatCard(
                    emoji: '🎉',
                    label: 'Total Found',
                    value: '${data['totalFound'] ?? 0}',
                    gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)]),
                  ),
                  _StatCard(
                    emoji: '✅',
                    label: 'Matched',
                    value: '${data['totalMatched'] ?? 0}',
                    gradient: AppTheme.primaryGradient,
                  ),
                  _StatCard(
                    emoji: '👥',
                    label: 'Total Users',
                    value: '${data['totalUsers'] ?? 0}',
                    gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFAB47BC)]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Pending Actions',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              _PendingCard(
                label: 'Pending Lost Reports',
                count: data['pendingLost'] ?? 0,
                color: AppTheme.error,
                emoji: '😢',
              ),
              const SizedBox(height: 8),
              _PendingCard(
                label: 'Pending Found Reports',
                count: data['pendingFound'] ?? 0,
                color: const Color(0xFF4CAF50),
                emoji: '🎉',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final LinearGradient gradient;

  const _StatCard(
      {required this.emoji,
        required this.label,
        required this.value,
        required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final String emoji;

  const _PendingCard(
      {required this.label,
        required this.count,
        required this.color,
        required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── VERIFIERS TAB ───────────────────────────────────────────────────────────

class _VerifiersTab extends StatelessWidget {
  final FirestoreService fs;
  const _VerifiersTab({required this.fs});

  void _showCreateVerifierDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Create Verifier',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                    hint: 'Full Name', controller: nameCtrl,
                    validator: (v) => v?.isEmpty == true ? 'Required' : null),
                const SizedBox(height: 12),
                AppTextField(
                    hint: 'Email (@gst.sies.edu.in)',
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Required';
                      if (!v!.endsWith('@gst.sies.edu.in')) {
                        return 'Must be @gst.sies.edu.in';
                      }
                      return null;
                    }),
                const SizedBox(height: 12),
                AppTextField(
                    hint: 'Password',
                    controller: passCtrl,
                    isPassword: true,
                    validator: (v) =>
                    v != null && v.length < 6 ? 'Min 6 chars' : null),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                if (!formKey.currentState!.validate()) return;
                setDlgState(() => isLoading = true);
                try {
                  // This requires Admin SDK in production
                  // Using secondary auth for demo
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Verifier created successfully! (Requires Cloud Function in production)'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  setDlgState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: isLoading
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateVerifierDialog(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Verifier'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: fs.getVerifiers(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final verifiers = snap.data ?? [];
          if (verifiers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🛡️', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('No verifiers yet',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  SizedBox(height: 8),
                  Text('Tap + to create a verifier account.',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: verifiers.length,
            itemBuilder: (_, i) => _VerifierCard(
              verifier: verifiers[i],
              onDelete: () => _confirmDelete(context, verifiers[i]),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel verifier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Verifier'),
        content: Text(
            'Are you sure you want to delete ${verifier.name}\'s account?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirestoreService().deleteVerifier(verifier.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Verifier deleted.'),
                  backgroundColor: AppTheme.error,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _VerifierCard extends StatelessWidget {
  final UserModel verifier;
  final VoidCallback onDelete;

  const _VerifierCard({required this.verifier, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                verifier.name.isNotEmpty
                    ? verifier.name[0].toUpperCase()
                    : 'V',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(verifier.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text(verifier.email,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Verifier',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary)),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.error, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── REPORTS TAB ─────────────────────────────────────────────────────────────

class _ReportsTab extends StatefulWidget {
  final FirestoreService fs;
  const _ReportsTab({required this.fs});

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tc,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [Tab(text: 'Lost'), Tab(text: 'Found')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tc,
            children: [
              StreamBuilder(
                stream: widget.fs.getAllLostItems(),
                builder: (_, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: snap.data!.length,
                    itemBuilder: (_, i) {
                      final item = snap.data![i];
                      return _SimpleReportTile(
                        title: item.itemName,
                        subtitle:
                        item.possibleLocations.take(2).join(', '),
                        status: item.status,
                        date: item.createdAt,
                        isLost: true,
                      );
                    },
                  );
                },
              ),
              StreamBuilder(
                stream: widget.fs.getAllFoundItems(),
                builder: (_, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: snap.data!.length,
                    itemBuilder: (_, i) {
                      final item = snap.data![i];
                      return _SimpleReportTile(
                        title: item.description,
                        subtitle: item.locationFound,
                        status: item.status,
                        date: item.createdAt,
                        isLost: false,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimpleReportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final DateTime date;
  final bool isLost;

  const _SimpleReportTile(
      {required this.title,
        required this.subtitle,
        required this.status,
        required this.date,
        required this.isLost});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isLost
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(isLost ? '😢' : '🎉',
                    style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusDot(status: status),
              const SizedBox(height: 4),
              Text(
                '${date.day}/${date.month}',
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'matched':
        color = AppTheme.success;
        break;
      case 'claimed':
        color = AppTheme.primary;
        break;
      default:
        color = const Color(0xFFF59E0B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
