enum HiveKey {
  boxSettings('init_box_settings'),
  locale('locale'),
  theme('theme'),
  ;

  final String key;

  const HiveKey(this.key);
}
