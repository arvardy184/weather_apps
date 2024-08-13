import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> loadPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final selectedProvince = prefs.getString('selectedProvince') ?? 'jawa-barat';
  final selectedCity = prefs.getString('selectedCity') ?? 'bandung';
  return [selectedProvince, selectedCity];
}

Future<void> savePreferences(String province, String city) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('selectedProvince', province);
  await prefs.setString('selectedCity', city);
}
