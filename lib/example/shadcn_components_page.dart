import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/provider/theme_provider.dart';
import '../ui/components/shadcn_button.dart';
import '../ui/components/shadcn_input.dart';
import '../ui/components/shadcn_switch.dart';

class ShadcnComponentsPage extends ConsumerStatefulWidget {
  const ShadcnComponentsPage({super.key});

  @override
  ConsumerState<ShadcnComponentsPage> createState() =>
      _ShadcnComponentsPageState();
}

class _ShadcnComponentsPageState extends ConsumerState<ShadcnComponentsPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _textAreaController = TextEditingController();

  bool _switchValue1 = false;
  bool _switchValue2 = true;
  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _textController.dispose();
    _passwordController.dispose();
    _textAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.color;
    final font = ref.font;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'shadcn/ui Components',
          style: font.responsive(context, font.boldText18).copyWith(
                color: colors.onBackground,
              ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            icon: Icon(
              ref.theme.mode.name == 'light'
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: colors.onBackground,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Buttons',
              [
                _buildButtonRow('Default', [
                  ShadcnButton(
                    onPressed: () => _showMessage('Default button pressed'),
                    child: Text('Default'),
                  ),
                  ShadcnButton(
                    variant: ShadcnButtonVariant.secondary,
                    onPressed: () => _showMessage('Secondary button pressed'),
                    child: Text('Secondary'),
                  ),
                ]),
                SizedBox(height: 8.h),
                _buildButtonRow('Outline & Ghost', [
                  ShadcnButton(
                    variant: ShadcnButtonVariant.outline,
                    onPressed: () => _showMessage('Outline button pressed'),
                    child: Text('Outline'),
                  ),
                  ShadcnButton(
                    variant: ShadcnButtonVariant.ghost,
                    onPressed: () => _showMessage('Ghost button pressed'),
                    child: Text('Ghost'),
                  ),
                ]),
                SizedBox(height: 8.h),
                _buildButtonRow('Destructive & Link', [
                  ShadcnButton(
                    variant: ShadcnButtonVariant.destructive,
                    onPressed: () => _showMessage('Destructive button pressed'),
                    child: Text('Destructive'),
                  ),
                  ShadcnButton(
                    variant: ShadcnButtonVariant.link,
                    onPressed: () => _showMessage('Link button pressed'),
                    child: Text('Link'),
                  ),
                ]),
                SizedBox(height: 8.h),
                _buildButtonRow('Sizes & States', [
                  ShadcnButton(
                    size: ShadcnButtonSize.sm,
                    onPressed: () => _showMessage('Small button pressed'),
                    child: Text('Small'),
                  ),
                  ShadcnButton(
                    size: ShadcnButtonSize.lg,
                    onPressed: () => _showMessage('Large button pressed'),
                    child: Text('Large'),
                  ),
                ]),
                SizedBox(height: 8.h),
                _buildButtonRow('Loading & Disabled', [
                  ShadcnButton(
                    isLoading: _isLoading,
                    onPressed: () => _toggleLoading(),
                    child: Text(_isLoading ? 'Loading...' : 'Toggle Loading'),
                  ),
                  ShadcnButton(
                    disabled: true,
                    onPressed: () {},
                    child: Text('Disabled'),
                  ),
                ]),
              ],
            ),
            SizedBox(height: 24.h),
            _buildSection(
              'Inputs',
              [
                ShadcnInput(
                  controller: _textController,
                  label: 'Email',
                  placeholder: 'Enter your email',
                  helperText: 'We\'ll never share your email.',
                ),
                SizedBox(height: 16.h),
                ShadcnInput(
                  controller: _passwordController,
                  label: 'Password',
                  placeholder: 'Enter your password',
                  obscureText: !_passwordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: colors.mutedForeground,
                      size: 20.r,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                SizedBox(height: 16.h),
                ShadcnInput(
                  label: 'Disabled Input',
                  placeholder: 'This input is disabled',
                  enabled: false,
                ),
                SizedBox(height: 16.h),
                ShadcnInput(
                  label: 'Input with Error',
                  placeholder: 'Enter something',
                  errorText: 'This field is required',
                ),
                SizedBox(height: 16.h),
                ShadcnTextArea(
                  controller: _textAreaController,
                  label: 'Description',
                  placeholder: 'Enter a description...',
                  helperText: 'Maximum 500 characters',
                  maxLength: 500,
                ),
              ],
            ),
            SizedBox(height: 24.h),
            _buildSection(
              'Switches',
              [
                ShadcnSwitchWithLabel(
                  value: _switchValue1,
                  onChanged: (value) {
                    setState(() {
                      _switchValue1 = value;
                    });
                  },
                  label: 'Enable notifications',
                  description:
                      'Receive notifications about your account activity',
                ),
                SizedBox(height: 16.h),
                ShadcnSwitchWithLabel(
                  value: _switchValue2,
                  onChanged: (value) {
                    setState(() {
                      _switchValue2 = value;
                    });
                  },
                  label: 'Marketing emails',
                  description: 'Receive emails about new products and features',
                ),
                SizedBox(height: 16.h),
                ShadcnSwitchWithLabel(
                  value: false,
                  onChanged: null,
                  label: 'Disabled switch',
                  description: 'This switch is disabled',
                  disabled: true,
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Simple Switch',
                      style:
                          font.responsive(context, font.mediumText14).copyWith(
                                color: colors.onSurface,
                              ),
                    ),
                    ShadcnSwitch(
                      value: _switchValue1,
                      onChanged: (value) {
                        setState(() {
                          _switchValue1 = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final colors = ref.color;
    final font = ref.font;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: font.responsive(context, font.boldText20).copyWith(
                color: colors.onBackground,
              ),
        ),
        SizedBox(height: 12.h),
        ...children,
      ],
    );
  }

  Widget _buildButtonRow(String subtitle, List<Widget> buttons) {
    final colors = ref.color;
    final font = ref.font;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: font.responsive(context, font.mediumText14).copyWith(
                color: colors.mutedForeground,
              ),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: buttons,
        ),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleLoading() {
    setState(() {
      _isLoading = !_isLoading;
    });

    if (_isLoading) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }
}
