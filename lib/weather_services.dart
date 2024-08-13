import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

Future<List<String>> fetchProvinces() async {
  final String response = await rootBundle.loadString('assets/provinsi.txt');
  return response.split('\n').map((line) => line.trim()).toList();
}

Future<List<String>> fetchCities(String province) async {
  final response = await http.get(Uri.parse('https://cuaca-gempa-rest-api.vercel.app/weather/${province.toLowerCase().replaceAll(' ', '-')}'));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final areas = data['data']['areas'];
    List<String> cityList = areas.map<String>((area) => area['description'].toString()).toList();
    return cityList;
  } else {
    throw Exception('Failed to fetch cities');
  }
}

Future<Map<String, dynamic>> fetchWeatherData(String province, String city) async {
  final response = await http.get(Uri.parse('https://cuaca-gempa-rest-api.vercel.app/weather/${province.toLowerCase().replaceAll(' ', '-')}/${city.toLowerCase().replaceAll(' ', '-')}'));

  if (response.statusCode == 200) {
    return json.decode(response.body)['data'];
  } else {
    throw Exception('Failed to fetch weather data');
  }
}
