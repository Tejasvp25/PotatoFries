import 'dart:convert';

import 'package:android_flutter_settings/android_flutter_settings.dart';
import 'package:flutter/material.dart';
import 'package:potato_fries/app_native/resources.dart';
import 'package:potato_fries/data/constants.dart';
import 'package:potato_fries/data/debugging.dart';
import 'package:potato_fries/utils/methods.dart';

class AppInfoProvider extends ChangeNotifier {
  AppInfoProvider() {
    loadData();
  }

  int _pageIndex = 0;
  Color _accentDark = Colors.lightBlueAccent;
  Color _accentLight = Colors.blueAccent;
  Map<String, dynamic> _hostVersion = {
    'MAJOR': 0,
    'MINOR': 0,
    'PATCH': '0',
    'BUILD': 0,
  };
  var _debug = DEBUG();
  String device;
  String model;
  String exactBuild;
  String dish;
  String type;

  bool _flag1 = false;
  int _flag2 = 0;
  bool _flag3 = false;
  bool _flag4 = false;

  Map globalSysTheme = Map();

  set pageIndex(int val) {
    _pageIndex = val;
    notifyListeners();
  }

  set accentDark(Color val) {
    _accentDark = val;
    notifyListeners();
  }

  set accentLight(Color val) {
    _accentLight = val;
    notifyListeners();
  }

  setFlag1() {
    _flag1 = !_flag1;
    if (!_flag1) _resetFlags();
    notifyListeners();
  }

  _resetFlags() {
    _flag1 = false;
    _flag2 = 0;
    _flag3 = false;
    // flag4 controls disco settings. Do not reset!
  }

  set flag2(int val) {
    _flag2 = val;
    if (!_flag1) {
      _flag2 = 0;
      return;
    }
    if (val == 0 || val > 5) _resetFlags();
    notifyListeners();
  }

  setFlag3() {
    if (!_flag3) {
      _flag3 = true;
      notifyListeners();
    }
  }

  setFlag4() async {
    if (_flag2 == 3 && !_flag4) {
      _flag4 = isCompatible('3.1.7');
      if (_flag4) {
        await AndroidFlutterSettings.setProp(
          'persist.sys.theme.accent_disco',
          '0',
        );
        notifyListeners();
      }
    }
  }

  loadFlag4() async {
    if (isCompatible('3.1.7')) {
      var _disco = await AndroidFlutterSettings.getProp(
              'persist.sys.theme.accent_disco') ??
          "";
      _flag4 = _disco != "";
    }
  }

  Color get accentDark => _accentDark;

  Color get accentLight => _accentLight;

  int get pageIndex => _pageIndex;

  Map get hostVersion => _debug.versionSpoof ?? _hostVersion;

  bool get flag1 => _flag1;

  int get flag2 => _flag2;

  bool get flag3 => _flag3;

  bool get flag4 => _flag4 && isCompatible('3.1.7');

  bool isCompatible(String version, {String max, bool strict = false}) =>
      (!strict && _debug.versionCheckDisabled) ||
      isVersionCompatible(version, hostVersion, max: max);

  void loadTheme({bool notifyNeeded = true}) async {
    String theme = await AndroidFlutterSettings.getString(
          'theme_customization_overlay_packages',
          SettingType.SECURE,
        ) ??
        '{}';
    globalSysTheme = jsonDecode(theme);
    if (notifyNeeded) notifyListeners();
  }

  void setTheme(String key, String value) async {
    if (value == null)
      globalSysTheme.remove(key);
    else
      globalSysTheme[key] = value;
    await AndroidFlutterSettings.putString(
      'theme_customization_overlay_packages',
      jsonEncode(globalSysTheme),
      SettingType.SECURE,
    );
    notifyListeners();
  }

  int getIconShapeIndex() =>
      shapesPackages.indexOf(globalSysTheme[OVERLAY_CATEGORY_SHAPE]) ?? 0;

  void setIconShape(int index) => setTheme(
        OVERLAY_CATEGORY_SHAPE,
        shapesPackages[index],
      );

  int getIconPackIndex() {
    List l = globalSysTheme[OVERLAY_CATEGORY_ICON_ANDROID]?.split('.');
    if (l == null) return 0;
    l.removeLast();
    return iconPackPrefixes.indexOf(l.join('.')) ?? 0;
  }

  void setIconPack(int index) {
    List packages;
    if (iconPackPrefixes[index] == null)
      packages = [null, null, null];
    else
      packages = [
        iconPackPrefixes[index] + '.settings',
        iconPackPrefixes[index] + '.systemui',
        iconPackPrefixes[index] + '.android',
      ];
    setTheme(OVERLAY_CATEGORY_ICON_SETTINGS, packages[0]);
    setTheme(OVERLAY_CATEGORY_ICON_SYSUI, packages[1]);
    setTheme(OVERLAY_CATEGORY_ICON_ANDROID, packages[2]);
  }

  // App Debug API
  String setVersionOverride(Map newVer) {
    if (newVer != null &&
        newVer.containsKey('PATCH') &&
        (newVer['PATCH'] is int)) newVer['PATCH'] = newVer['PATCH'].toString();
    String ret;
    if (!isVersionValid(newVer)) {
      _debug.versionSpoof = null;
      ret = "Invalid version! Disabling override.";
    } else {
      _debug.versionSpoof = newVer;
    }
    loadFlag4();
    notifyListeners();
    return ret;
  }

  Map getVersionOverride() => _debug.versionSpoof;

  void setVersionCheckDisabled(bool disable) {
    _debug.versionCheckDisabled = disable;
    loadFlag4();
    notifyListeners();
  }

  bool isVersionCheckDisabled() => _debug.versionCheckDisabled;

  void setCompatCheckDisabled(bool disable) {
    _debug.compatCheckDisabled = disable;
    loadFlag4();
    notifyListeners();
  }

  bool isCompatCheckDisabled() => _debug.compatCheckDisabled;

  void loadData() async {
    _accentDark = Color(await Resources.getAccentDark());
    _accentLight = Color(await Resources.getAccentLight());
    // Populate version details
    String verNum = await AndroidFlutterSettings.getProp('ro.potato.vernum');
    _hostVersion = parseVerNum(verNum);
    loadTheme(notifyNeeded: false);
    device = await AndroidFlutterSettings.getProp('ro.potato.device');
    model = await AndroidFlutterSettings.getProp('ro.product.model');
    exactBuild = await AndroidFlutterSettings.getProp('ro.potato.version');
    dish = await AndroidFlutterSettings.getProp('ro.potato.dish');
    switch (
        await AndroidFlutterSettings.getProp('ro.potato.branding.version')) {
      case "Official":
        type = "Official";
        break;
      case "Mashed":
        type = "Mashed (Official Beta)";
        break;
      default:
        type = "Community";
    }
    loadFlag4();
    notifyListeners();
  }
}
