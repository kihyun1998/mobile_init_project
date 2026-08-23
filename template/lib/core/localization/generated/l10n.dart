// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `tweakcn`
  String get appTitle {
    return Intl.message('tweakcn', name: 'appTitle', desc: '', args: []);
  }

  /// `Total Revenue`
  String get totalRevenue {
    return Intl.message(
      'Total Revenue',
      name: 'totalRevenue',
      desc: '',
      args: [],
    );
  }

  /// `+20.1% from last month`
  String get revenueChange {
    return Intl.message(
      '+20.1% from last month',
      name: 'revenueChange',
      desc: '',
      args: [],
    );
  }

  /// `Subscriptions`
  String get subscriptions {
    return Intl.message(
      'Subscriptions',
      name: 'subscriptions',
      desc: '',
      args: [],
    );
  }

  /// `+180.1% from last month`
  String get subscriptionsChange {
    return Intl.message(
      '+180.1% from last month',
      name: 'subscriptionsChange',
      desc: '',
      args: [],
    );
  }

  /// `Move Goal`
  String get moveGoal {
    return Intl.message('Move Goal', name: 'moveGoal', desc: '', args: []);
  }

  /// `Set your daily activity goal.`
  String get moveGoalDescription {
    return Intl.message(
      'Set your daily activity goal.',
      name: 'moveGoalDescription',
      desc: '',
      args: [],
    );
  }

  /// `CALORIES/DAY`
  String get caloriesPerDay {
    return Intl.message(
      'CALORIES/DAY',
      name: 'caloriesPerDay',
      desc: '',
      args: [],
    );
  }

  /// `Exercise Minutes`
  String get exerciseMinutes {
    return Intl.message(
      'Exercise Minutes',
      name: 'exerciseMinutes',
      desc: '',
      args: [],
    );
  }

  /// `Your exercise minutes are ahead of where you normally are.`
  String get exerciseMinutesDescription {
    return Intl.message(
      'Your exercise minutes are ahead of where you normally are.',
      name: 'exerciseMinutesDescription',
      desc: '',
      args: [],
    );
  }

  /// `This Year`
  String get thisYear {
    return Intl.message('This Year', name: 'thisYear', desc: '', args: []);
  }

  /// `Last Year`
  String get lastYear {
    return Intl.message('Last Year', name: 'lastYear', desc: '', args: []);
  }

  /// `Jan`
  String get monthJan {
    return Intl.message('Jan', name: 'monthJan', desc: '', args: []);
  }

  /// `Feb`
  String get monthFeb {
    return Intl.message('Feb', name: 'monthFeb', desc: '', args: []);
  }

  /// `Mar`
  String get monthMar {
    return Intl.message('Mar', name: 'monthMar', desc: '', args: []);
  }

  /// `Apr`
  String get monthApr {
    return Intl.message('Apr', name: 'monthApr', desc: '', args: []);
  }

  /// `May`
  String get monthMay {
    return Intl.message('May', name: 'monthMay', desc: '', args: []);
  }

  /// `Jun`
  String get monthJun {
    return Intl.message('Jun', name: 'monthJun', desc: '', args: []);
  }

  /// `Upgrade your plan`
  String get upgradePlan {
    return Intl.message(
      'Upgrade your plan',
      name: 'upgradePlan',
      desc: '',
      args: [],
    );
  }

  /// `You're currently on the free plan. Upgrade to unlock more features.`
  String get upgradePlanDescription {
    return Intl.message(
      'You\'re currently on the free plan. Upgrade to unlock more features.',
      name: 'upgradePlanDescription',
      desc: '',
      args: [],
    );
  }

  /// `Starter`
  String get planStarter {
    return Intl.message('Starter', name: 'planStarter', desc: '', args: []);
  }

  /// `1 user, 5GB storage`
  String get planStarterDesc {
    return Intl.message(
      '1 user, 5GB storage',
      name: 'planStarterDesc',
      desc: '',
      args: [],
    );
  }

  /// `Professional`
  String get planProfessional {
    return Intl.message(
      'Professional',
      name: 'planProfessional',
      desc: '',
      args: [],
    );
  }

  /// `5 users, 50GB storage`
  String get planProfessionalDesc {
    return Intl.message(
      '5 users, 50GB storage',
      name: 'planProfessionalDesc',
      desc: '',
      args: [],
    );
  }

  /// `Enterprise`
  String get planEnterprise {
    return Intl.message(
      'Enterprise',
      name: 'planEnterprise',
      desc: '',
      args: [],
    );
  }

  /// `Unlimited users, 500GB storage`
  String get planEnterpriseDesc {
    return Intl.message(
      'Unlimited users, 500GB storage',
      name: 'planEnterpriseDesc',
      desc: '',
      args: [],
    );
  }

  /// `Upgrade Plan`
  String get upgradePlanButton {
    return Intl.message(
      'Upgrade Plan',
      name: 'upgradePlanButton',
      desc: '',
      args: [],
    );
  }

  /// `Team Members`
  String get teamMembers {
    return Intl.message(
      'Team Members',
      name: 'teamMembers',
      desc: '',
      args: [],
    );
  }

  /// `Invite your team members to collaborate.`
  String get teamMembersDescription {
    return Intl.message(
      'Invite your team members to collaborate.',
      name: 'teamMembersDescription',
      desc: '',
      args: [],
    );
  }

  /// `Owner`
  String get roleOwner {
    return Intl.message('Owner', name: 'roleOwner', desc: '', args: []);
  }

  /// `Member`
  String get roleMember {
    return Intl.message('Member', name: 'roleMember', desc: '', args: []);
  }

  /// `Viewer`
  String get roleViewer {
    return Intl.message('Viewer', name: 'roleViewer', desc: '', args: []);
  }

  /// `Cookie Settings`
  String get cookieSettings {
    return Intl.message(
      'Cookie Settings',
      name: 'cookieSettings',
      desc: '',
      args: [],
    );
  }

  /// `Manage your cookie settings here.`
  String get cookieSettingsDescription {
    return Intl.message(
      'Manage your cookie settings here.',
      name: 'cookieSettingsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Strictly Necessary`
  String get strictlyNecessary {
    return Intl.message(
      'Strictly Necessary',
      name: 'strictlyNecessary',
      desc: '',
      args: [],
    );
  }

  /// `These cookies are essential for the website to function.`
  String get strictlyNecessaryDesc {
    return Intl.message(
      'These cookies are essential for the website to function.',
      name: 'strictlyNecessaryDesc',
      desc: '',
      args: [],
    );
  }

  /// `Functional Cookies`
  String get functionalCookies {
    return Intl.message(
      'Functional Cookies',
      name: 'functionalCookies',
      desc: '',
      args: [],
    );
  }

  /// `These cookies enable personalized features.`
  String get functionalCookiesDesc {
    return Intl.message(
      'These cookies enable personalized features.',
      name: 'functionalCookiesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Performance Cookies`
  String get performanceCookies {
    return Intl.message(
      'Performance Cookies',
      name: 'performanceCookies',
      desc: '',
      args: [],
    );
  }

  /// `These cookies help improve performance.`
  String get performanceCookiesDesc {
    return Intl.message(
      'These cookies help improve performance.',
      name: 'performanceCookiesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Save preferences`
  String get savePreferences {
    return Intl.message(
      'Save preferences',
      name: 'savePreferences',
      desc: '',
      args: [],
    );
  }

  /// `Create an account`
  String get createAccount {
    return Intl.message(
      'Create an account',
      name: 'createAccount',
      desc: '',
      args: [],
    );
  }

  /// `Enter your information below to create your account.`
  String get createAccountDescription {
    return Intl.message(
      'Enter your information below to create your account.',
      name: 'createAccountDescription',
      desc: '',
      args: [],
    );
  }

  /// `Google`
  String get google {
    return Intl.message('Google', name: 'google', desc: '', args: []);
  }

  /// `Apple`
  String get apple {
    return Intl.message('Apple', name: 'apple', desc: '', args: []);
  }

  /// `OR CONTINUE WITH`
  String get orContinueWith {
    return Intl.message(
      'OR CONTINUE WITH',
      name: 'orContinueWith',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message('Name', name: 'name', desc: '', args: []);
  }

  /// `Enter your name`
  String get namePlaceholder {
    return Intl.message(
      'Enter your name',
      name: 'namePlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message('Email', name: 'email', desc: '', args: []);
  }

  /// `name@example.com`
  String get emailPlaceholder {
    return Intl.message(
      'name@example.com',
      name: 'emailPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Create a password`
  String get passwordPlaceholder {
    return Intl.message(
      'Create a password',
      name: 'passwordPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Create account`
  String get createAccountButton {
    return Intl.message(
      'Create account',
      name: 'createAccountButton',
      desc: '',
      args: [],
    );
  }

  /// `Type your message...`
  String get typeMessage {
    return Intl.message(
      'Type your message...',
      name: 'typeMessage',
      desc: '',
      args: [],
    );
  }

  /// `Beautiful themes for shadcn/ui`
  String get tweakcnSubtitle {
    return Intl.message(
      'Beautiful themes for shadcn/ui',
      name: 'tweakcnSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Create beautiful, customizable themes for your shadcn/ui projects. Preview components in real-time and export CSS variables.`
  String get tweakcnDescription {
    return Intl.message(
      'Create beautiful, customizable themes for your shadcn/ui projects. Preview components in real-time and export CSS variables.',
      name: 'tweakcnDescription',
      desc: '',
      args: [],
    );
  }

  /// `Payments`
  String get payments {
    return Intl.message('Payments', name: 'payments', desc: '', args: []);
  }

  /// `Manage your recent payments.`
  String get paymentsDescription {
    return Intl.message(
      'Manage your recent payments.',
      name: 'paymentsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get statusHeader {
    return Intl.message('Status', name: 'statusHeader', desc: '', args: []);
  }

  /// `Email`
  String get emailHeader {
    return Intl.message('Email', name: 'emailHeader', desc: '', args: []);
  }

  /// `Amount`
  String get amountHeader {
    return Intl.message('Amount', name: 'amountHeader', desc: '', args: []);
  }

  /// `{count} of {total} row(s) selected.`
  String rowsSelected(int count, int total) {
    return Intl.message(
      '$count of $total row(s) selected.',
      name: 'rowsSelected',
      desc: '',
      args: [count, total],
    );
  }

  /// `Share this document`
  String get shareDocument {
    return Intl.message(
      'Share this document',
      name: 'shareDocument',
      desc: '',
      args: [],
    );
  }

  /// `Anyone with the link can view this document.`
  String get shareDocumentDescription {
    return Intl.message(
      'Anyone with the link can view this document.',
      name: 'shareDocumentDescription',
      desc: '',
      args: [],
    );
  }

  /// `People with access`
  String get peopleWithAccess {
    return Intl.message(
      'People with access',
      name: 'peopleWithAccess',
      desc: '',
      args: [],
    );
  }

  /// `Can edit`
  String get canEdit {
    return Intl.message('Can edit', name: 'canEdit', desc: '', args: []);
  }

  /// `Can view`
  String get canView {
    return Intl.message('Can view', name: 'canView', desc: '', args: []);
  }

  /// `Link copied!`
  String get linkCopied {
    return Intl.message('Link copied!', name: 'linkCopied', desc: '', args: []);
  }

  /// `Report an issue`
  String get reportIssue {
    return Intl.message(
      'Report an issue',
      name: 'reportIssue',
      desc: '',
      args: [],
    );
  }

  /// `What area are you having problems with?`
  String get reportIssueDescription {
    return Intl.message(
      'What area are you having problems with?',
      name: 'reportIssueDescription',
      desc: '',
      args: [],
    );
  }

  /// `Area`
  String get area {
    return Intl.message('Area', name: 'area', desc: '', args: []);
  }

  /// `Team`
  String get areaTeam {
    return Intl.message('Team', name: 'areaTeam', desc: '', args: []);
  }

  /// `Billing`
  String get areaBilling {
    return Intl.message('Billing', name: 'areaBilling', desc: '', args: []);
  }

  /// `Account`
  String get areaAccount {
    return Intl.message('Account', name: 'areaAccount', desc: '', args: []);
  }

  /// `Deployments`
  String get areaDeployments {
    return Intl.message(
      'Deployments',
      name: 'areaDeployments',
      desc: '',
      args: [],
    );
  }

  /// `Severity`
  String get severity {
    return Intl.message('Severity', name: 'severity', desc: '', args: []);
  }

  /// `Low`
  String get severityLow {
    return Intl.message('Low', name: 'severityLow', desc: '', args: []);
  }

  /// `Medium`
  String get severityMedium {
    return Intl.message('Medium', name: 'severityMedium', desc: '', args: []);
  }

  /// `High`
  String get severityHigh {
    return Intl.message('High', name: 'severityHigh', desc: '', args: []);
  }

  /// `Critical`
  String get severityCritical {
    return Intl.message(
      'Critical',
      name: 'severityCritical',
      desc: '',
      args: [],
    );
  }

  /// `Subject`
  String get subject {
    return Intl.message('Subject', name: 'subject', desc: '', args: []);
  }

  /// `I need help with...`
  String get subjectPlaceholder {
    return Intl.message(
      'I need help with...',
      name: 'subjectPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get descriptionLabel {
    return Intl.message(
      'Description',
      name: 'descriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Please include all information relevant to your issue.`
  String get descriptionPlaceholder {
    return Intl.message(
      'Please include all information relevant to your issue.',
      name: 'descriptionPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Submit`
  String get submit {
    return Intl.message('Submit', name: 'submit', desc: '', args: []);
  }

  /// `Theme Mode`
  String get themeMode {
    return Intl.message('Theme Mode', name: 'themeMode', desc: '', args: []);
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `Light`
  String get lightTheme {
    return Intl.message('Light', name: 'lightTheme', desc: '', args: []);
  }

  /// `Dark`
  String get darkTheme {
    return Intl.message('Dark', name: 'darkTheme', desc: '', args: []);
  }

  /// `English`
  String get english {
    return Intl.message('English', name: 'english', desc: '', args: []);
  }

  /// `Korean`
  String get korean {
    return Intl.message('Korean', name: 'korean', desc: '', args: []);
  }

  /// `Home`
  String get tabHome {
    return Intl.message('Home', name: 'tabHome', desc: '', args: []);
  }

  /// `Search`
  String get tabSearch {
    return Intl.message('Search', name: 'tabSearch', desc: '', args: []);
  }

  /// `Profile`
  String get tabProfile {
    return Intl.message('Profile', name: 'tabProfile', desc: '', args: []);
  }

  /// `Calendar`
  String get calendar {
    return Intl.message('Calendar', name: 'calendar', desc: '', args: []);
  }

  /// `Pick a date.`
  String get calendarDescription {
    return Intl.message(
      'Pick a date.',
      name: 'calendarDescription',
      desc: '',
      args: [],
    );
  }

  /// `Date Picker`
  String get datePicker {
    return Intl.message('Date Picker', name: 'datePicker', desc: '', args: []);
  }

  /// `Choose a single date or a range.`
  String get datePickerDescription {
    return Intl.message(
      'Choose a single date or a range.',
      name: 'datePickerDescription',
      desc: '',
      args: [],
    );
  }

  /// `Due date`
  String get dueDate {
    return Intl.message('Due date', name: 'dueDate', desc: '', args: []);
  }

  /// `Period`
  String get stayPeriod {
    return Intl.message('Period', name: 'stayPeriod', desc: '', args: []);
  }

  /// `Pick a date`
  String get pickADate {
    return Intl.message('Pick a date', name: 'pickADate', desc: '', args: []);
  }

  /// `Pick a date range`
  String get pickADateRange {
    return Intl.message(
      'Pick a date range',
      name: 'pickADateRange',
      desc: '',
      args: [],
    );
  }

  /// `Login to your account`
  String get loginTitle {
    return Intl.message(
      'Login to your account',
      name: 'loginTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email below to login to your account`
  String get loginDescription {
    return Intl.message(
      'Enter your email below to login to your account',
      name: 'loginDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enter your password`
  String get loginPasswordPlaceholder {
    return Intl.message(
      'Enter your password',
      name: 'loginPasswordPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Forgot your password?`
  String get forgotPassword {
    return Intl.message(
      'Forgot your password?',
      name: 'forgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get loginButton {
    return Intl.message('Login', name: 'loginButton', desc: '', args: []);
  }

  /// `Login with Google`
  String get loginWithGoogle {
    return Intl.message(
      'Login with Google',
      name: 'loginWithGoogle',
      desc: '',
      args: [],
    );
  }

  /// `Don't have an account?`
  String get noAccount {
    return Intl.message(
      'Don\'t have an account?',
      name: 'noAccount',
      desc: '',
      args: [],
    );
  }

  /// `Sign up`
  String get signUp {
    return Intl.message('Sign up', name: 'signUp', desc: '', args: []);
  }

  /// `Checkbox`
  String get checkboxTitle {
    return Intl.message('Checkbox', name: 'checkboxTitle', desc: '', args: []);
  }

  /// `A control that toggles between checked and unchecked.`
  String get checkboxDescription {
    return Intl.message(
      'A control that toggles between checked and unchecked.',
      name: 'checkboxDescription',
      desc: '',
      args: [],
    );
  }

  /// `Accept terms and conditions`
  String get acceptTerms {
    return Intl.message(
      'Accept terms and conditions',
      name: 'acceptTerms',
      desc: '',
      args: [],
    );
  }

  /// `By clicking this checkbox, you agree to the terms and conditions.`
  String get acceptTermsDescription {
    return Intl.message(
      'By clicking this checkbox, you agree to the terms and conditions.',
      name: 'acceptTermsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enable notifications`
  String get enableNotifications {
    return Intl.message(
      'Enable notifications',
      name: 'enableNotifications',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ko'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
