import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/foundation/app_mode.dart';
import '../core/theme/provider/theme_provider.dart';
import '../core/theme/tweakcn_theme.g.dart';
import '../ui/components/shadcn_avatar.dart';
import '../ui/components/shadcn_badge.dart';
import '../ui/components/shadcn_button.dart';
import '../ui/components/shadcn_card.dart';
import '../ui/components/shadcn_chat_bubble.dart';
import '../ui/components/shadcn_data_table.dart';
import '../ui/components/shadcn_input.dart';
import '../ui/components/shadcn_radio_group.dart';
import '../ui/components/shadcn_select.dart';
import '../ui/components/shadcn_separator.dart';
import '../ui/components/shadcn_switch.dart';

class ShadcnComponentsPage extends ConsumerStatefulWidget {
  const ShadcnComponentsPage({super.key});

  @override
  ConsumerState<ShadcnComponentsPage> createState() =>
      _ShadcnComponentsPageState();
}

class _ShadcnComponentsPageState extends ConsumerState<ShadcnComponentsPage> {
  // Create Account form
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Chat
  final _chatController = TextEditingController();
  final List<_ChatMessage> _chatMessages = [
    _ChatMessage('Hi, how can I help you today?', false, 'Sofia', 'SD'),
    _ChatMessage('Hey, I\'m having trouble with my account.', true, 'You', 'YO'),
    _ChatMessage('What seems to be the problem?', false, 'Sofia', 'SD'),
    _ChatMessage('I can\'t log in to my account.', true, 'You', 'YO'),
  ];

  // Report Issue
  final _issueController = TextEditingController();
  String _issueArea = 'billing';
  String _issueSeverity = 'medium';

  // Cookie Settings
  bool _strictCookies = true;
  bool _functionalCookies = false;
  bool _performanceCookies = false;

  // Plan selection
  String _selectedPlan = 'starter';

  // Move Goal
  int _moveGoal = 350;

  // Team member roles
  final Map<String, String> _teamRoles = {
    'Sofia Davis': 'owner',
    'Jackson Lee': 'member',
    'Isabella Nguyen': 'member',
  };

  // Data table selection
  final Set<int> _selectedPayments = {};

  // Share document
  final _shareEmailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _chatController.dispose();
    _issueController.dispose();
    _shareEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final mode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'tweakcn',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: colors.foreground,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            icon: Icon(
              mode == AppMode.light ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: colors.foreground,
              size: 20.r,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          children: [
            // Row 1: Revenue + Subscriptions
            _buildRevenueCard(colors),
            SizedBox(height: 12.h),
            _buildSubscriptionsCard(colors),

            SizedBox(height: 12.h),

            // Row 2: Move Goal + Exercise Minutes
            _buildMoveGoalCard(colors),
            SizedBox(height: 12.h),
            _buildExerciseMinutesCard(colors),

            SizedBox(height: 12.h),

            // Row 3: Upgrade Plan
            _buildUpgradePlanCard(colors),

            SizedBox(height: 12.h),

            // Row 4: Team Members
            _buildTeamMembersCard(colors),

            SizedBox(height: 12.h),

            // Row 5: Cookie Settings + Create Account
            _buildCookieSettingsCard(colors),
            SizedBox(height: 12.h),
            _buildCreateAccountCard(colors),

            SizedBox(height: 12.h),

            // Row 6: Chat
            _buildChatCard(colors),

            SizedBox(height: 12.h),

            // Row 7: tweakcn Info
            _buildTweakcnInfoCard(colors),

            SizedBox(height: 12.h),

            // Row 8: Payments Table
            _buildPaymentsCard(colors),

            SizedBox(height: 12.h),

            // Row 9: Share Document + Report Issue
            _buildShareDocumentCard(colors),
            SizedBox(height: 12.h),
            _buildReportIssueCard(colors),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Revenue Card (Line Chart)
  // ─────────────────────────────────────────
  Widget _buildRevenueCard(TweakcnColors colors) {
    return ShadcnCard(
      title: 'Total Revenue',
      description: '+20.1% from last month',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\$15,231.89',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: colors.foreground,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 180.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 1.5),
                      FlSpot(2, 4),
                      FlSpot(3, 3.5),
                      FlSpot(4, 5),
                      FlSpot(5, 3),
                      FlSpot(6, 4.5),
                      FlSpot(7, 6),
                      FlSpot(8, 5.5),
                      FlSpot(9, 7),
                      FlSpot(10, 6),
                      FlSpot(11, 8),
                    ],
                    isCurved: true,
                    color: colors.chart1,
                    barWidth: 2.r,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors.chart1.withValues(alpha: 0.15),
                    ),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Subscriptions Card (Bar Chart)
  // ─────────────────────────────────────────
  Widget _buildSubscriptionsCard(TweakcnColors colors) {
    return ShadcnCard(
      title: 'Subscriptions',
      description: '+180.1% from last month',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '+2,350',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: colors.foreground,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 180.h,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                barGroups: List.generate(12, (i) {
                  final values = [4, 3, 5, 7, 5, 8, 6, 9, 7, 10, 8, 11];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i].toDouble(),
                        color: colors.chart1,
                        width: 14.w,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(3.r),
                          topRight: Radius.circular(3.r),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Move Goal Card
  // ─────────────────────────────────────────
  Widget _buildMoveGoalCard(TweakcnColors colors) {
    return ShadcnCard(
      title: 'Move Goal',
      description: 'Set your daily activity goal.',
      content: Column(
        children: [
          SizedBox(height: 8.h),
          // Goal counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleButton(
                icon: Icons.remove,
                colors: colors,
                onTap: () => setState(() => _moveGoal = max(100, _moveGoal - 10)),
              ),
              SizedBox(width: 24.w),
              Column(
                children: [
                  Text(
                    '$_moveGoal',
                    style: TextStyle(
                      fontSize: 48.sp,
                      fontWeight: FontWeight.bold,
                      color: colors.foreground,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'CALORIES/DAY',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: colors.mutedForeground,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 24.w),
              _circleButton(
                icon: Icons.add,
                colors: colors,
                onTap: () => setState(() => _moveGoal = min(1000, _moveGoal + 10)),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          // Mini bar chart
          SizedBox(
            height: 80.h,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                barGroups: List.generate(7, (i) {
                  final heights = [0.4, 0.6, 0.3, 0.8, 0.5, 0.7, 0.9];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: heights[i] * _moveGoal / 350,
                        color: colors.chart1.withValues(alpha: 0.6 + heights[i] * 0.4),
                        width: 28.w,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required TweakcnColors colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 16.r, color: colors.foreground),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Exercise Minutes Card (Dual Line Chart)
  // ─────────────────────────────────────────
  Widget _buildExerciseMinutesCard(TweakcnColors colors) {
    return ShadcnCard(
      title: 'Exercise Minutes',
      description: 'Your exercise minutes are ahead of where you normally are.',
      content: SizedBox(
        height: 200.h,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24.h,
                  getTitlesWidget: (value, meta) {
                    const labels = [
                      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    ];
                    if (value.toInt() >= 0 && value.toInt() < labels.length) {
                      return Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          labels[value.toInt()],
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: colors.mutedForeground,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(enabled: false),
            lineBarsData: [
              // This year
              LineChartBarData(
                spots: const [
                  FlSpot(0, 30),
                  FlSpot(1, 45),
                  FlSpot(2, 35),
                  FlSpot(3, 55),
                  FlSpot(4, 48),
                  FlSpot(5, 62),
                ],
                isCurved: true,
                color: colors.chart1,
                barWidth: 2.r,
                dotData: FlDotData(show: false),
              ),
              // Last year
              LineChartBarData(
                spots: const [
                  FlSpot(0, 20),
                  FlSpot(1, 25),
                  FlSpot(2, 30),
                  FlSpot(3, 35),
                  FlSpot(4, 32),
                  FlSpot(5, 40),
                ],
                isCurved: true,
                color: colors.chart2,
                barWidth: 2.r,
                dotData: FlDotData(show: false),
                dashArray: [5, 5],
              ),
            ],
            minY: 0,
          ),
        ),
      ),
      footer: Row(
        children: [
          _legendDot(colors.chart1),
          SizedBox(width: 4.w),
          Text('This Year', style: TextStyle(fontSize: 11.sp, color: colors.mutedForeground)),
          SizedBox(width: 16.w),
          _legendDot(colors.chart2),
          SizedBox(width: 4.w),
          Text('Last Year', style: TextStyle(fontSize: 11.sp, color: colors.mutedForeground)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 8.r,
      height: 8.r,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // ─────────────────────────────────────────
  // Upgrade Plan Card
  // ─────────────────────────────────────────
  Widget _buildUpgradePlanCard(TweakcnColors colors) {
    return ShadcnCard(
      title: 'Upgrade your plan',
      description:
          'You\'re currently on the free plan. Upgrade to unlock more features.',
      content: Column(
        children: [
          ShadcnRadioGroup<String>(
            value: _selectedPlan,
            onChanged: (val) => setState(() => _selectedPlan = val),
            items: const [
              ShadcnRadioItem(
                value: 'starter',
                label: 'Starter',
                description: '1 user, 5GB storage',
              ),
              ShadcnRadioItem(
                value: 'professional',
                label: 'Professional',
                description: '5 users, 50GB storage',
              ),
              ShadcnRadioItem(
                value: 'enterprise',
                label: 'Enterprise',
                description: 'Unlimited users, 500GB storage',
              ),
            ],
          ),
        ],
      ),
      footer: ShadcnButton(
        onPressed: () {},
        width: double.infinity,
        child: const Text('Upgrade Plan'),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Team Members Card
  // ─────────────────────────────────────────
  Widget _buildTeamMembersCard(TweakcnColors colors) {
    final members = [
      _TeamMember('Sofia Davis', 'm@example.com', 'SD'),
      _TeamMember('Jackson Lee', 'p@example.com', 'JL'),
      _TeamMember('Isabella Nguyen', 'i@example.com', 'IN'),
    ];

    return ShadcnCard(
      title: 'Team Members',
      description: 'Invite your team members to collaborate.',
      content: Column(
        children: members.map((m) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                ShadcnAvatar(initial: m.initial, size: 36),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: colors.foreground,
                        ),
                      ),
                      Text(
                        m.email,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                ShadcnSelect<String>(
                  value: _teamRoles[m.name],
                  onChanged: (val) =>
                      setState(() => _teamRoles[m.name] = val),
                  items: const [
                    ShadcnSelectItem(value: 'owner', label: 'Owner'),
                    ShadcnSelectItem(value: 'member', label: 'Member'),
                    ShadcnSelectItem(value: 'viewer', label: 'Viewer'),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Cookie Settings Card
  // ─────────────────────────────────────────
  Widget _buildCookieSettingsCard(TweakcnColors colors) {
    return ShadcnCard(
      title: 'Cookie Settings',
      description: 'Manage your cookie settings here.',
      content: Column(
        children: [
          ShadcnSwitchWithLabel(
            value: _strictCookies,
            onChanged: (v) => setState(() => _strictCookies = v),
            label: 'Strictly Necessary',
            description: 'These cookies are essential for the website to function.',
          ),
          SizedBox(height: 12.h),
          ShadcnSwitchWithLabel(
            value: _functionalCookies,
            onChanged: (v) => setState(() => _functionalCookies = v),
            label: 'Functional Cookies',
            description: 'These cookies enable personalized features.',
          ),
          SizedBox(height: 12.h),
          ShadcnSwitchWithLabel(
            value: _performanceCookies,
            onChanged: (v) => setState(() => _performanceCookies = v),
            label: 'Performance Cookies',
            description: 'These cookies help improve performance.',
          ),
        ],
      ),
      footer: ShadcnButton(
        onPressed: () {},
        width: double.infinity,
        variant: ShadcnButtonVariant.outline,
        child: const Text('Save preferences'),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Create Account Card
  // ─────────────────────────────────────────
  Widget _buildCreateAccountCard(TweakcnColors colors) {
    return ShadcnCard(
      title: 'Create an account',
      description: 'Enter your information below to create your account.',
      content: Column(
        children: [
          // Social buttons
          Row(
            children: [
              Expanded(
                child: ShadcnButton(
                  variant: ShadcnButtonVariant.outline,
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.g_mobiledata, size: 20.r),
                      SizedBox(width: 4.w),
                      const Text('Google'),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ShadcnButton(
                  variant: ShadcnButtonVariant.outline,
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apple, size: 18.r),
                      SizedBox(width: 4.w),
                      const Text('Apple'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Divider with text
          Row(
            children: [
              Expanded(child: ShadcnSeparator(margin: EdgeInsets.zero)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  'OR CONTINUE WITH',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: colors.mutedForeground,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(child: ShadcnSeparator(margin: EdgeInsets.zero)),
            ],
          ),
          SizedBox(height: 16.h),
          ShadcnInput(
            controller: _nameController,
            label: 'Name',
            placeholder: 'Enter your name',
          ),
          SizedBox(height: 12.h),
          ShadcnInput(
            controller: _emailController,
            label: 'Email',
            placeholder: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 12.h),
          ShadcnInput(
            controller: _passwordController,
            label: 'Password',
            placeholder: 'Create a password',
            obscureText: true,
          ),
        ],
      ),
      footer: ShadcnButton(
        onPressed: () {},
        width: double.infinity,
        child: const Text('Create account'),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Chat Card
  // ─────────────────────────────────────────
  Widget _buildChatCard(TweakcnColors colors) {
    return ShadcnCard(
      padding: EdgeInsets.all(16.r),
      titleWidget: Row(
        children: [
          ShadcnAvatar(initial: 'SD', size: 36),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sofia Davis',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                Text(
                  'm@example.com',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        children: [
          ShadcnSeparator(margin: EdgeInsets.only(bottom: 12.h)),
          ..._chatMessages.map((msg) => ShadcnChatBubble(
                message: msg.text,
                isSent: msg.isSent,
                senderName: msg.isSent ? null : msg.name,
                senderInitial: msg.initial,
              )),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: ShadcnInput(
                  controller: _chatController,
                  placeholder: 'Type your message...',
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              SizedBox(width: 8.w),
              ShadcnButton(
                size: ShadcnButtonSize.icon,
                onPressed: _sendMessage,
                child: Icon(Icons.send, size: 16.r),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatMessages.add(_ChatMessage(text, true, 'You', 'YO'));
      _chatController.clear();
    });
  }

  // ─────────────────────────────────────────
  // tweakcn Info Card
  // ─────────────────────────────────────────
  Widget _buildTweakcnInfoCard(TweakcnColors colors) {
    return ShadcnCard(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  color: colors.primary,
                ),
                child: Icon(Icons.palette, size: 20.r, color: colors.primaryForeground),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'tweakcn',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    Text(
                      'Beautiful themes for shadcn/ui',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Create beautiful, customizable themes for your shadcn/ui projects. Preview components in real-time and export CSS variables.',
            style: TextStyle(
              fontSize: 13.sp,
              color: colors.mutedForeground,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: const [
              ShadcnBadge(label: 'shadcn/ui'),
              ShadcnBadge(label: 'themes', variant: ShadcnBadgeVariant.secondary),
              ShadcnBadge(label: 'CSS', variant: ShadcnBadgeVariant.outline),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Payments Card (Data Table)
  // ─────────────────────────────────────────
  Widget _buildPaymentsCard(TweakcnColors colors) {
    final payments = [
      _Payment('INV001', 'success', 'ken99@example.com', 316.0),
      _Payment('INV002', 'success', 'abe45@example.com', 242.0),
      _Payment('INV003', 'processing', 'monserrat44@example.com', 837.0),
      _Payment('INV004', 'success', 'silas22@example.com', 874.0),
      _Payment('INV005', 'failed', 'carmella@example.com', 721.0),
    ];

    return ShadcnCard(
      title: 'Payments',
      description: 'Manage your recent payments.',
      content: Column(
        children: [
          ShadcnDataTable<_Payment>(
            selectedRows: _selectedPayments,
            onSelectRow: (idx) {
              setState(() {
                if (_selectedPayments.contains(idx)) {
                  _selectedPayments.remove(idx);
                } else {
                  _selectedPayments.add(idx);
                }
              });
            },
            onSelectAll: (selectAll) {
              setState(() {
                if (selectAll) {
                  _selectedPayments.addAll(
                    List.generate(payments.length, (i) => i),
                  );
                } else {
                  _selectedPayments.clear();
                }
              });
            },
            columns: const [
              ShadcnDataColumn(label: 'Status', flex: 2),
              ShadcnDataColumn(label: 'Email', flex: 3),
              ShadcnDataColumn(label: 'Amount', flex: 2),
            ],
            rows: payments.asMap().entries.map((entry) {
              final p = entry.value;
              return ShadcnDataRow<_Payment>(
                data: p,
                cells: [
                  _statusBadge(p.status),
                  Text(
                    p.email,
                    style: TextStyle(fontSize: 12.sp, color: colors.foreground),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${p.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: colors.foreground,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              );
            }).toList(),
          ),
          SizedBox(height: 8.h),
          Text(
            '${_selectedPayments.length} of ${payments.length} row(s) selected.',
            style: TextStyle(fontSize: 11.sp, color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    ShadcnBadgeVariant variant;
    switch (status) {
      case 'success':
        variant = ShadcnBadgeVariant.defaultStyle;
        break;
      case 'processing':
        variant = ShadcnBadgeVariant.secondary;
        break;
      case 'failed':
        variant = ShadcnBadgeVariant.destructive;
        break;
      default:
        variant = ShadcnBadgeVariant.outline;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: ShadcnBadge(label: status, variant: variant),
    );
  }

  // ─────────────────────────────────────────
  // Share Document Card
  // ─────────────────────────────────────────
  Widget _buildShareDocumentCard(TweakcnColors colors) {
    return ShadcnCard(
      title: 'Share this document',
      description: 'Anyone with the link can view this document.',
      content: Column(
        children: [
          // Link field
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'https://example.com/link/to/doc',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: colors.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      const ClipboardData(text: 'https://example.com/link/to/doc'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(Icons.copy, size: 16.r, color: colors.mutedForeground),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'People with access',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: colors.foreground,
            ),
          ),
          SizedBox(height: 8.h),
          ...[
            ('Olivia Martin', 'm@example.com', 'Can edit'),
            ('Isabella Nguyen', 'b@example.com', 'Can view'),
            ('Sofia Davis', 'p@example.com', 'Can view'),
          ].map((person) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    ShadcnAvatar(
                      initial: person.$1.split(' ').map((n) => n[0]).join(),
                      size: 32,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.$1,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: colors.foreground,
                            ),
                          ),
                          Text(
                            person.$2,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      person.$3,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Report Issue Card
  // ─────────────────────────────────────────
  Widget _buildReportIssueCard(TweakcnColors colors) {
    return ShadcnCard(
      title: 'Report an issue',
      description: 'What area are you having problems with?',
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ShadcnSelect<String>(
                  label: 'Area',
                  value: _issueArea,
                  onChanged: (v) => setState(() => _issueArea = v),
                  items: const [
                    ShadcnSelectItem(value: 'team', label: 'Team'),
                    ShadcnSelectItem(value: 'billing', label: 'Billing'),
                    ShadcnSelectItem(value: 'account', label: 'Account'),
                    ShadcnSelectItem(value: 'deployments', label: 'Deployments'),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ShadcnSelect<String>(
                  label: 'Severity',
                  value: _issueSeverity,
                  onChanged: (v) => setState(() => _issueSeverity = v),
                  items: const [
                    ShadcnSelectItem(value: 'low', label: 'Low'),
                    ShadcnSelectItem(value: 'medium', label: 'Medium'),
                    ShadcnSelectItem(value: 'high', label: 'High'),
                    ShadcnSelectItem(value: 'critical', label: 'Critical'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ShadcnInput(
            controller: _issueController,
            label: 'Subject',
            placeholder: 'I need help with...',
          ),
          SizedBox(height: 12.h),
          ShadcnInput(
            label: 'Description',
            placeholder: 'Please include all information relevant to your issue.',
            maxLines: 4,
            minLines: 3,
          ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: ShadcnButton(
              variant: ShadcnButtonVariant.outline,
              onPressed: () {},
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: ShadcnButton(
              onPressed: () {},
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isSent;
  final String name;
  final String initial;

  const _ChatMessage(this.text, this.isSent, this.name, this.initial);
}

class _TeamMember {
  final String name;
  final String email;
  final String initial;

  const _TeamMember(this.name, this.email, this.initial);
}

class _Payment {
  final String id;
  final String status;
  final String email;
  final double amount;

  const _Payment(this.id, this.status, this.email, this.amount);
}
