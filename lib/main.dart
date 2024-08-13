import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App - Arvan',
      theme: ThemeData(
        fontFamily: GoogleFonts.openSans().fontFamily,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WeatherHomePage(),
    );
  }
}

class WeatherController extends GetxController {
  var selectedProvince = 'dki-jakarta'.obs;
  var selectedCity = 'Jakarta Pusat'.obs;
  var provinces = <String>[].obs;
  var cities = <String>[].obs;
  var isLoadingCities = false.obs;
  var weatherData = Rx<Map<String, dynamic>>({});
  var isLoadingWeather = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPreferences();
    fetchProvinces();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    selectedProvince.value =
        prefs.getString('selectedProvince') ?? 'jawa-barat';
    selectedCity.value = prefs.getString('selectedCity') ?? 'bandung';
    fetchCities();
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedProvince', selectedProvince.value);
    await prefs.setString('selectedCity', selectedCity.value);
  }

  Future<void> fetchProvinces() async {
    final String response = await rootBundle.loadString('assets/provinsi.txt');
    provinces.value = response.split('\n').map((line) => line.trim()).toList();
    print(provinces);
  }

Future<void> fetchCities() async {
  isLoadingCities.value = true;
  final response = await http.get(Uri.parse(
      'https://cuaca-gempa-rest-api.vercel.app/weather/${selectedProvince.value.toLowerCase().replaceAll(' ', '-')}'));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final areas = data['data']['areas'];
    List<String> cityList =
        areas.map<String>((area) => area['description'].toString()).toList();

    cities.value = cityList;
    if (cities.isNotEmpty && !cities.contains(selectedCity.value)) {
      selectedCity.value = cities.first;
    }
  } else {
    print('Failed to fetch cities, status code: ${response.statusCode}');
    cities.value = []; // Clear the cities list if the fetch fails
  }
  isLoadingWeather.value = false;
}
  Future<void> fetchWeatherData() async {
    isLoadingWeather.value = true;
    final response = await http.get(Uri.parse(
        'https://cuaca-gempa-rest-api.vercel.app/weather/${selectedProvince.value.toLowerCase().replaceAll(' ', '-')}/${selectedCity.value.toLowerCase().replaceAll(' ', '-')}'));

    if (response.statusCode == 200) {
      weatherData.value = json.decode(response.body)['data'];
    } else {
      print('Failed to load weather data');
    }
    isLoadingWeather.value = false;
  }

  void changeProvince(String province) {
  selectedProvince.value = province;
  selectedCity.value = ''; // Clear the selected city
  fetchCities();
  savePreferences();
}

  void changeCity(String city) {
    selectedCity.value = city;
    fetchWeatherData();
    savePreferences();
  }
}

class WeatherHomePage extends StatelessWidget {
  final WeatherController controller = Get.put(WeatherController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade400, Colors.blue.shade300],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingWeather.value) {
                    return Center(child: CircularProgressIndicator());
                  } else if (controller.weatherData.value.isEmpty) {
                    return Center(child: Text('No data available'));
                  } else {
                    return Column(
                      children: [
                        lottieImage(),
                        _buildCurrentWeather(),
                        Container(
                          
                          child: _buildHourlyForecast(),
                        )

                        //add padding
                      ],
                    );
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget lottieImage() {
    return Lottie.asset('assets/weather.json', width: 200);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         Obx(() => DropdownButton<String>(
  isExpanded: true,
  alignment: AlignmentDirectional.centerStart,
  autofocus: true,
  underline: Container(),
  icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
  dropdownColor: Colors.white,
  value: controller.provinces.contains(controller.selectedProvince.value) 
      ? controller.selectedProvince.value 
      : (controller.provinces.isNotEmpty ? controller.provinces.first : null),
  items: controller.provinces.map((String province) {
    return DropdownMenuItem<String>(
      value: province,
      child: Text(province),
    );
  }).toList(),
  onChanged: (String? newValue) {
    if (newValue != null) {
      controller.changeProvince(newValue);
    }
  },
)),
       Obx(
  () => controller.isLoadingCities.value
      ? CircularProgressIndicator()
      : DropdownButton<String>(
          isExpanded: true,
          alignment: AlignmentDirectional.centerStart,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
          dropdownColor: Colors.white,
          underline: Container(),
          value: controller.cities.contains(controller.selectedCity.value)
              ? controller.selectedCity.value
              : (controller.cities.isNotEmpty ? controller.cities.first : null),
          items: controller.cities.map((String city) {
            return DropdownMenuItem<String>(
              value: city,
              child: Text(city),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              controller.changeCity(newValue);
            }
          },
        ),
),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    return Obx(() {
      final weatherData = controller.weatherData.value;
      final currentWeather =
          weatherData['params'].firstWhere((param) => param['id'] == 'weather');
      final currentTemp =
          weatherData['params'].firstWhere((param) => param['id'] == 't');
      final currentTime = DateTime.now();

      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${currentTemp['times'][0]['celcius']}',
              style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            Text(
              currentWeather['times'][0]['name'],
              style: TextStyle(fontSize: 24),
            ),
            Text(
              '${DateFormat('EEEE, d MMMM').format(currentTime)}',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    });
  }

  String _parseIssueDate(String timestamp) {
    try {
      String datePart = timestamp.substring(0, 8);
      String timePart = timestamp.substring(8, 12);
      String formattedString = datePart +
          "T" +
          timePart.substring(0, 2) +
          ":" +
          timePart.substring(2, 4);
      DateTime dateTime = DateTime.parse(formattedString);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      print('Failed to parse issue date: $e');
      return '';
    }
  }

  Widget _buildHourlyForecast() {
    return Obx(() {
      final weatherData = controller.weatherData.value;
      final hourlyWeather =
          weatherData['params'].firstWhere((param) => param['id'] == 'weather');
      final hourlyTemp =
          weatherData['params'].firstWhere((param) => param['id'] == 't');

      return Container(
     decoration: BoxDecoration(
       borderRadius: BorderRadius.circular(16.0),
     ),
        height: 140,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: hourlyWeather['times'].length,
            itemBuilder: (context, index) {
              final weather = hourlyWeather['times'][index];
              final temp = hourlyTemp['times'][index];
              final time = _parseIssueDate(weather['datetime']);
              return Card(
               
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(time),
                      Icon(getWeatherIcon(weather['code'])),
                      Text('${temp['celcius']}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  IconData getWeatherIcon(String code) {
    switch (code) {
      case '0':
        return Icons.wb_sunny;
      case '1':
        return Icons.beach_access;
      case '2':
        return Icons.wb_cloudy;
      case '3':
      return Icons.cloud;
      case '4':
        return Icons.cloud;
      default:
        return Icons.wb_cloudy;
    }
  }
}
