import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/localization/generated/l10n.dart';
import '../core/localization/provider/language_provider.dart';
import '../core/localization/provider/locale_state_provider.dart';
import '../core/theme/foundation/app_mode.dart';
import '../core/theme/provider/theme_provider.dart';
import '../core/theme/tweakcn_theme.g.dart';
import '../ui/components/shadcn_avatar.dart';
import '../ui/components/shadcn_badge.dart';
import '../ui/components/shadcn_button.dart';
import '../ui/components/shadcn_calendar.dart';
import '../ui/components/shadcn_card.dart';
import '../ui/components/shadcn_chat_bubble.dart';
import '../ui/components/shadcn_checkbox.dart';
import '../ui/components/shadcn_date_picker.dart';
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
  // Checkbox
  bool _acceptTerms = false;
  bool _acceptTermsWithNote = true;

  // Login form
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Create Account form
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Chat
  final _chatController = TextEditingController();
  final List<_ChatMessage> _chatMessages = [
    const _ChatMessage('Hi, how can I help you today?', false, 'Sofia', 'SD'),
    const _ChatMessage(
      'Hey, I\'m having trouble with my account.',
      true,
      'You',
      'YO',
    ),
    const _ChatMessage('What seems to be the problem?', false, 'Sofia', 'SD'),
    const _ChatMessage('I can\'t log in to my account.', true, 'You', 'YO'),
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

  // Calendar / Date Picker
  final _today = DateTime.now();
  late DateTime _calendarMonth = DateTime(_today.year, _today.month);
  late DateTime? _calendarSelected = _today;
  DateTime? _pickedDate;
  DateTimeRange? _pickedRange;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
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
    final s = ref.watch(languageProvider);
    final locale = ref.watch(localeStateProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          s.appTitle,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: colors.foreground,
          ),
        ),
        actions: [
          // 지원 언어가 하나뿐이면 눌러도 아무 일이 없다. 그런 버튼은 두지 않는다.
          if (LocaleState.supportedLocales.length > 1)
            IconButton(
              onPressed: () =>
                  ref.read(localeStateProvider.notifier).toggleLocale(),
              icon: Text(
                locale.languageCode.toUpperCase(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
            ),
          IconButton(
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            icon: Icon(
              mode == AppMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
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
            _buildRevenueCard(colors, s),
            SizedBox(height: 12.h),
            _buildSubscriptionsCard(colors, s),
            SizedBox(height: 12.h),
            _buildMoveGoalCard(colors, s),
            SizedBox(height: 12.h),
            _buildExerciseMinutesCard(colors, s),
            SizedBox(height: 12.h),
            _buildUpgradePlanCard(colors, s),
            SizedBox(height: 12.h),
            _buildTeamMembersCard(colors, s),
            SizedBox(height: 12.h),
            _buildCookieSettingsCard(colors, s),
            SizedBox(height: 12.h),
            _buildCalendarCard(colors, s),
            SizedBox(height: 12.h),
            _buildDatePickerCard(colors, s),
            SizedBox(height: 12.h),
            _buildCheckboxCard(colors, s),
            SizedBox(height: 12.h),
            _buildLoginCard(colors, s),
            SizedBox(height: 12.h),
            _buildCreateAccountCard(colors, s),
            SizedBox(height: 12.h),
            _buildChatCard(colors, s),
            SizedBox(height: 12.h),
            _buildTweakcnInfoCard(colors, s),
            SizedBox(height: 12.h),
            _buildPaymentsCard(colors, s),
            SizedBox(height: 12.h),
            _buildShareDocumentCard(colors, s),
            SizedBox(height: 12.h),
            _buildReportIssueCard(colors, s),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Revenue Card (Line Chart)
  // ─────────────────────────────────────────
  Widget _buildRevenueCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      title: s.totalRevenue,
      description: s.revenueChange,
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
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
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
                    dotData: const FlDotData(show: false),
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
  Widget _buildSubscriptionsCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      title: s.subscriptions,
      description: s.subscriptionsChange,
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
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
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
  Widget _buildMoveGoalCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      title: s.moveGoal,
      description: s.moveGoalDescription,
      content: Column(
        children: [
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleButton(
                icon: Icons.remove,
                colors: colors,
                onTap: () =>
                    setState(() => _moveGoal = max(100, _moveGoal - 10)),
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
                    s.caloriesPerDay,
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
                onTap: () =>
                    setState(() => _moveGoal = min(1000, _moveGoal + 10)),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 80.h,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                barGroups: List.generate(7, (i) {
                  final heights = [0.4, 0.6, 0.3, 0.8, 0.5, 0.7, 0.9];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: heights[i] * _moveGoal / 350,
                        color: colors.chart1.withValues(
                          alpha: 0.6 + heights[i] * 0.4,
                        ),
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
  Widget _buildExerciseMinutesCard(TweakcnColors colors, S s) {
    final monthLabels = [
      s.monthJan,
      s.monthFeb,
      s.monthMar,
      s.monthApr,
      s.monthMay,
      s.monthJun,
    ];

    return ShadcnCard(
      title: s.exerciseMinutes,
      description: s.exerciseMinutesDescription,
      content: SizedBox(
        height: 200.h,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24.h,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < monthLabels.length) {
                      return Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          monthLabels[idx],
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
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
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
                dotData: const FlDotData(show: false),
              ),
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
                dotData: const FlDotData(show: false),
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
          Text(
            s.thisYear,
            style: TextStyle(fontSize: 11.sp, color: colors.mutedForeground),
          ),
          SizedBox(width: 16.w),
          _legendDot(colors.chart2),
          SizedBox(width: 4.w),
          Text(
            s.lastYear,
            style: TextStyle(fontSize: 11.sp, color: colors.mutedForeground),
          ),
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
  Widget _buildUpgradePlanCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      title: s.upgradePlan,
      description: s.upgradePlanDescription,
      content: Column(
        children: [
          ShadcnRadioGroup<String>(
            value: _selectedPlan,
            onChanged: (val) => setState(() => _selectedPlan = val),
            items: [
              ShadcnRadioItem(
                value: 'starter',
                label: s.planStarter,
                description: s.planStarterDesc,
              ),
              ShadcnRadioItem(
                value: 'professional',
                label: s.planProfessional,
                description: s.planProfessionalDesc,
              ),
              ShadcnRadioItem(
                value: 'enterprise',
                label: s.planEnterprise,
                description: s.planEnterpriseDesc,
              ),
            ],
          ),
        ],
      ),
      footer: ShadcnButton(
        onPressed: () {},
        width: double.infinity,
        child: Text(s.upgradePlanButton),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Team Members Card
  // ─────────────────────────────────────────
  Widget _buildTeamMembersCard(TweakcnColors colors, S s) {
    final members = [
      const _TeamMember('Sofia Davis', 'm@example.com', 'SD'),
      const _TeamMember('Jackson Lee', 'p@example.com', 'JL'),
      const _TeamMember('Isabella Nguyen', 'i@example.com', 'IN'),
    ];

    return ShadcnCard(
      title: s.teamMembers,
      description: s.teamMembersDescription,
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
                  onChanged: (val) => setState(() => _teamRoles[m.name] = val),
                  items: [
                    ShadcnSelectItem(value: 'owner', label: s.roleOwner),
                    ShadcnSelectItem(value: 'member', label: s.roleMember),
                    ShadcnSelectItem(value: 'viewer', label: s.roleViewer),
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
  Widget _buildCookieSettingsCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      title: s.cookieSettings,
      description: s.cookieSettingsDescription,
      content: Column(
        children: [
          ShadcnSwitchWithLabel(
            value: _strictCookies,
            onChanged: (v) => setState(() => _strictCookies = v),
            label: s.strictlyNecessary,
            description: s.strictlyNecessaryDesc,
          ),
          SizedBox(height: 12.h),
          ShadcnSwitchWithLabel(
            value: _functionalCookies,
            onChanged: (v) => setState(() => _functionalCookies = v),
            label: s.functionalCookies,
            description: s.functionalCookiesDesc,
          ),
          SizedBox(height: 12.h),
          ShadcnSwitchWithLabel(
            value: _performanceCookies,
            onChanged: (v) => setState(() => _performanceCookies = v),
            label: s.performanceCookies,
            description: s.performanceCookiesDesc,
          ),
        ],
      ),
      footer: ShadcnButton(
        onPressed: () {},
        width: double.infinity,
        variant: ShadcnButtonVariant.outline,
        child: Text(s.savePreferences),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Calendar Card
  // ─────────────────────────────────────────
  Widget _buildCalendarCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      title: s.calendar,
      description: s.calendarDescription,
      content: ShadcnCalendar(
        month: _calendarMonth,
        selected: _calendarSelected,
        onDaySelected: (day) => setState(() {
          _calendarSelected = day;
          // 이웃 달 칸을 눌렀으면 그 달로 따라간다. 고른 날이 화면 밖으로
          // 나가버리면 무엇을 골랐는지 보이지 않는다.
          _calendarMonth = DateTime(day.year, day.month);
        }),
        onMonthChanged: (month) => setState(() => _calendarMonth = month),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Date Picker Card
  // ─────────────────────────────────────────
  Widget _buildDatePickerCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      title: s.datePicker,
      description: s.datePickerDescription,
      content: Column(
        children: [
          ShadcnDatePicker.single(
            label: s.dueDate,
            placeholder: s.pickADate,
            value: _pickedDate,
            onChanged: (date) => setState(() => _pickedDate = date),
          ),
          SizedBox(height: 12.h),
          ShadcnDatePicker.range(
            label: s.stayPeriod,
            placeholder: s.pickADateRange,
            value: _pickedRange,
            onChanged: (range) => setState(() => _pickedRange = range),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Checkbox Card
  // ─────────────────────────────────────────
  //
  // shadcn 의 checkbox-demo 가 보여주는 세 상태를 그대로 옮긴다
  // (registry/new-york-v4/examples/checkbox-demo.tsx): 기본 / 체크됨 + 설명 /
  // 비활성. 이 블록이 생기기 전에는 `ShadcnCheckbox` 가 앱 어디에도 쓰이지
  // 않아서 빌더 미리보기로 확인할 방법이 없었다.
  Widget _buildCheckboxCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      title: s.checkboxTitle,
      description: s.checkboxDescription,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadcnCheckbox(
            value: _acceptTerms,
            onChanged: (v) => setState(() => _acceptTerms = v),
            label: s.acceptTerms,
          ),
          SizedBox(height: 16.h),
          ShadcnCheckbox(
            value: _acceptTermsWithNote,
            onChanged: (v) => setState(() => _acceptTermsWithNote = v),
            label: s.acceptTerms,
          ),
          Padding(
            padding: EdgeInsets.only(left: 24.w, top: 4.h),
            child: Text(
              s.acceptTermsDescription,
              style: TextStyle(fontSize: 12.sp, color: colors.mutedForeground),
            ),
          ),
          SizedBox(height: 16.h),
          ShadcnCheckbox(
            value: false,
            onChanged: (_) {},
            label: s.enableNotifications,
            disabled: true,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Login Card
  // ─────────────────────────────────────────
  //
  // shadcn 의 login-01 블록 구성을 따른다
  // (registry/new-york-v4/blocks/login-01/components/login-form.tsx).
  // **체크박스가 없는 것이 원본이다** — login-01~05 어디에도 "로그인 유지" 가
  // 없다. 링크는 예제라 실제로 이동하지 않는다. 라우팅을 끌어들이면 예제
  // 페이지가 앱 구조에 묶여서 빌더 미리보기가 그만큼 무거워진다.
  Widget _buildLoginCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      title: s.loginTitle,
      description: s.loginDescription,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadcnInput(
            controller: _loginEmailController,
            label: s.email,
            placeholder: s.emailPlaceholder,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 12.h),
          // 라벨과 "잊으셨나요?" 가 한 줄에 놓이는 것이 원본이다. ShadcnInput 의
          // label 을 쓰면 그 줄을 컴포넌트가 독점하므로 label 을 비우고 직접 짠다.
          Row(
            children: [
              Text(
                s.password,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: colors.foreground,
                ),
              ),
              SizedBox(width: 8.w),
              // Flexible + ellipsis 가 없으면 이 줄이 넘친다. 긴 번역이나 큰 글자
              // 배율에서 라벨과 링크가 같은 줄을 다투기 때문이다 — 캘린더 제목
              // 줄에서 이미 같은 것으로 한 번 터졌다 (#23).
              Flexible(
                child: GestureDetector(
                  onTap: () {},
                  child: Text(
                    s.forgotPassword,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: colors.mutedForeground,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.mutedForeground,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ShadcnInput(
            controller: _loginPasswordController,
            placeholder: s.loginPasswordPlaceholder,
            obscureText: true,
          ),
          SizedBox(height: 16.h),
          ShadcnButton(
            onPressed: () {},
            width: double.infinity,
            child: Text(s.loginButton),
          ),
          SizedBox(height: 8.h),
          ShadcnButton(
            onPressed: () {},
            width: double.infinity,
            variant: ShadcnButtonVariant.outline,
            child: Text(s.loginWithGoogle),
          ),
          SizedBox(height: 12.h),
          // Row 가 아니라 Wrap 이다. 두 조각이 한 줄에 안 들어가면 넘치는 대신
          // 줄을 바꾼다 — 번역 길이가 언어마다 다르고 글자 배율도 사용자가 정한다.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4.w,
            children: [
              Text(
                s.noAccount,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: colors.mutedForeground,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  s.signUp,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: colors.foreground,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Create Account Card
  // ─────────────────────────────────────────
  Widget _buildCreateAccountCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      title: s.createAccount,
      description: s.createAccountDescription,
      content: Column(
        children: [
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
                      Text(s.google),
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
                      Text(s.apple),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              const Expanded(child: ShadcnSeparator(margin: EdgeInsets.zero)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  s.orContinueWith,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: colors.mutedForeground,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Expanded(child: ShadcnSeparator(margin: EdgeInsets.zero)),
            ],
          ),
          SizedBox(height: 16.h),
          ShadcnInput(
            controller: _nameController,
            label: s.name,
            placeholder: s.namePlaceholder,
          ),
          SizedBox(height: 12.h),
          ShadcnInput(
            controller: _emailController,
            label: s.email,
            placeholder: s.emailPlaceholder,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 12.h),
          ShadcnInput(
            controller: _passwordController,
            label: s.password,
            placeholder: s.passwordPlaceholder,
            obscureText: true,
          ),
        ],
      ),
      footer: ShadcnButton(
        onPressed: () {},
        width: double.infinity,
        child: Text(s.createAccountButton),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Chat Card
  // ─────────────────────────────────────────
  Widget _buildChatCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      padding: EdgeInsets.all(16.r),
      titleWidget: Row(
        children: [
          const ShadcnAvatar(initial: 'SD', size: 36),
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
          ..._chatMessages.map(
            (msg) => ShadcnChatBubble(
              message: msg.text,
              isSent: msg.isSent,
              senderName: msg.isSent ? null : msg.name,
              senderInitial: msg.initial,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: ShadcnInput(
                  controller: _chatController,
                  placeholder: s.typeMessage,
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
  Widget _buildTweakcnInfoCard(TweakcnColors colors, S s) {
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
                child: Icon(
                  Icons.palette,
                  size: 20.r,
                  color: colors.primaryForeground,
                ),
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
                      s.tweakcnSubtitle,
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
            s.tweakcnDescription,
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
              ShadcnBadge(
                label: 'themes',
                variant: ShadcnBadgeVariant.secondary,
              ),
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
  Widget _buildPaymentsCard(TweakcnColors colors, S s) {
    final payments = [
      const _Payment('INV001', 'success', 'ken99@example.com', 316.0),
      const _Payment('INV002', 'success', 'abe45@example.com', 242.0),
      const _Payment('INV003', 'processing', 'monserrat44@example.com', 837.0),
      const _Payment('INV004', 'success', 'silas22@example.com', 874.0),
      const _Payment('INV005', 'failed', 'carmella@example.com', 721.0),
    ];

    return ShadcnCard(
      title: s.payments,
      description: s.paymentsDescription,
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
            columns: [
              ShadcnDataColumn(label: s.statusHeader, flex: 2),
              ShadcnDataColumn(label: s.emailHeader, flex: 3),
              ShadcnDataColumn(label: s.amountHeader, flex: 2),
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
            s.rowsSelected(_selectedPayments.length, payments.length),
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
  Widget _buildShareDocumentCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      title: s.shareDocument,
      description: s.shareDocumentDescription,
      content: Column(
        children: [
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
                    style: TextStyle(fontSize: 12.sp, color: colors.foreground),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      const ClipboardData(
                        text: 'https://example.com/link/to/doc',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.linkCopied),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy,
                    size: 16.r,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            s.peopleWithAccess,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: colors.foreground,
            ),
          ),
          SizedBox(height: 8.h),
          ...[
            ('Olivia Martin', 'm@example.com', s.canEdit),
            ('Isabella Nguyen', 'b@example.com', s.canView),
            ('Sofia Davis', 'p@example.com', s.canView),
          ].map(
            (person) => Padding(
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
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Report Issue Card
  // ─────────────────────────────────────────
  Widget _buildReportIssueCard(TweakcnColors colors, S s) {
    return ShadcnCard(
      title: s.reportIssue,
      description: s.reportIssueDescription,
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ShadcnSelect<String>(
                  label: s.area,
                  value: _issueArea,
                  onChanged: (v) => setState(() => _issueArea = v),
                  items: [
                    ShadcnSelectItem(value: 'team', label: s.areaTeam),
                    ShadcnSelectItem(value: 'billing', label: s.areaBilling),
                    ShadcnSelectItem(value: 'account', label: s.areaAccount),
                    ShadcnSelectItem(
                      value: 'deployments',
                      label: s.areaDeployments,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ShadcnSelect<String>(
                  label: s.severity,
                  value: _issueSeverity,
                  onChanged: (v) => setState(() => _issueSeverity = v),
                  items: [
                    ShadcnSelectItem(value: 'low', label: s.severityLow),
                    ShadcnSelectItem(value: 'medium', label: s.severityMedium),
                    ShadcnSelectItem(value: 'high', label: s.severityHigh),
                    ShadcnSelectItem(
                      value: 'critical',
                      label: s.severityCritical,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ShadcnInput(
            controller: _issueController,
            label: s.subject,
            placeholder: s.subjectPlaceholder,
          ),
          SizedBox(height: 12.h),
          ShadcnInput(
            label: s.descriptionLabel,
            placeholder: s.descriptionPlaceholder,
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
              child: Text(s.cancel),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: ShadcnButton(onPressed: () {}, child: Text(s.submit)),
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
