import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_text_field.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
        onLogout: () async {
          await context.read<AuthProvider>().signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      body: DecoratedBox(
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _AdminHero(name: admin?.name ?? 'Admin'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelPadding: EdgeInsets.zero,
                    tabs: const [
                      Tab(text: 'Analytics'),
                      Tab(text: 'Verifiers'),
                      Tab(text: 'Reports'),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: fs.getAnalytics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final cards = [
          ('Total lost', '${data['totalLost'] ?? 0}', Icons.search_off_rounded, AppTheme.error),
          ('Total found', '${data['totalFound'] ?? 0}', Icons.inventory_2_rounded, AppTheme.success),
          ('Matched', '${data['totalMatched'] ?? 0}', Icons.compare_arrows_rounded, AppTheme.primary),
          ('Users', '${data['totalUsers'] ?? 0}', Icons.groups_rounded, AppTheme.warning),
        ];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.98,
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
            const SizedBox(height: 18),
            _PendingPanel(
              title: 'Pending lost reports',
              count: data['pendingLost'] ?? 0,
              color: AppTheme.error,
              icon: Icons.pending_actions_rounded,
            ),
            const SizedBox(height: 12),
            _PendingPanel(
              title: 'Pending found reports',
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
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary.withOpacity(0.18)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? 'A' : initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
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
                'Admin workspace',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(name, style: const TextStyle(color: AppTheme.textSecondary)),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppTheme.buttonShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Admin control', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            'Hello, ${name.split(' ').first}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review analytics, manage verifier access, and monitor report volume.',
            style: TextStyle(color: Colors.white70, height: 1.5),
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
  final VoidCallback onLogout;

  const _AdminDrawer({
    required this.name,
    required this.email,
    required this.onAnalytics,
    required this.onVerifiers,
    required this.onReports,
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
      width: 300,
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: Colors.white,
                      child: Text(
                        initials.isEmpty ? 'A' : initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _AdminDrawerItem(label: 'Analytics', icon: Icons.analytics_outlined, onTap: onAnalytics),
              _AdminDrawerItem(label: 'Verifiers', icon: Icons.verified_user_outlined, onTap: onVerifiers),
              _AdminDrawerItem(label: 'Reports', icon: Icons.description_outlined, onTap: onReports),
              const Spacer(),
              _AdminDrawerItem(
                label: 'Logout',
                icon: Icons.logout_rounded,
                color: AppTheme.error,
                onTap: onLogout,
              ),
            ],
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(icon, color: effectiveColor),
        title: Text(
          label,
          style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w600),
        ),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }
}

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
        builder: (context, setState) => AlertDialog(
          title: const Text('Create verifier'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  hint: 'Full name',
                  controller: nameCtrl,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  hint: 'Email',
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
                      value != null && value.length >= 6 ? null : 'Minimum 6 characters',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isLoading = true);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Verifier creation requires production cloud function wiring'),
                        backgroundColor: AppTheme.success,
                      ));
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
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
        title: const Text('Delete verifier'),
        content: Text('Delete ${verifier.name} from verifier access?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirestoreService().deleteVerifier(verifier.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Verifier deleted'),
                  backgroundColor: AppTheme.error,
                ));
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
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
        label: const Text('Add verifier'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: fs.getVerifiers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final verifiers = snapshot.data!;
          if (verifiers.isEmpty) {
            return const _AdminEmptyState(
              icon: Icons.verified_user_outlined,
              title: 'No verifiers added',
              subtitle: 'Create verifier access to help staff review and match submissions.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
            itemCount: verifiers.length,
            itemBuilder: (context, index) {
              final verifier = verifiers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          verifier.name.isEmpty ? 'V' : verifier.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(verifier.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(verifier.email, style: const TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(context, verifier),
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                      label: const Text('Remove', style: TextStyle(color: AppTheme.error)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelPadding: EdgeInsets.zero,
              tabs: const [
                Tab(text: 'Lost'),
                Tab(text: 'Found'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              StreamBuilder(
                stream: widget.fs.getAllLostItems(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return const _AdminEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No lost reports',
                      subtitle: 'Lost report records will appear here once submitted.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _AdminReportTile(
                      title: items[index].itemName,
                      subtitle: items[index].possibleLocations.take(2).join(', '),
                      status: items[index].status,
                      icon: Icons.search_off_rounded,
                      color: AppTheme.error,
                      photoURL: items[index].photoURL,
                    ),
                  );
                },
              ),
              StreamBuilder(
                stream: widget.fs.getAllFoundItems(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return const _AdminEmptyState(
                      icon: Icons.inventory_2_rounded,
                      title: 'No found reports',
                      subtitle: 'Found report records will appear here once submitted.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _AdminReportTile(
                      title: items[index].description,
                      subtitle: items[index].locationFound,
                      status: items[index].status,
                      icon: Icons.inventory_2_rounded,
                      color: AppTheme.success,
                      photoURL: items[index].photoURL,
                    ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary)),
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: photoURL != null && photoURL!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoURL!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(icon, color: color),
                  )
                : Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
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

  const _AdminEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: AppTheme.canvas,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
