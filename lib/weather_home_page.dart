import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'weather_services.dart';
import 'preferences.dart';
import 'utils.dart';

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  String selectedProvince = 'jawa-barat';
  String selectedCity = 'bandung';
  Map<String, dynamic> weatherData = {};
  List<String> provinces = [];
  List<String> cities = [];
  bool isLoading = true;
  DateTime issueDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchProvinces();
    print('Init state: $selectedProvince, $selectedCity');
  }

  Future<void> _loadPreferences() async {
    final prefs = await loadPreferences();
    setState(() {
      selectedProvince = prefs[0];
      selectedCity = prefs[1];
      print('Loading preferences: $selectedProvince, $selectedCity');
    });
  }

  Future<void> _savePreferences() async {
    await savePreferences(selectedProvince, selectedCity);
    print('Saving preferences: $selectedProvince, $selectedCity');
  }

  Future<void> _fetchProvinces() async {
    final List<String> fetchedProvinces = await fetchProvinces();
    setState(() {
      provinces = fetchedProvinces;
      print("Fetching provinces: $provinces");
    });
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    final List<String> fetchedCities = await fetchCities(selectedProvince);
    setState(() {
      cities = fetchedCities;
      print("Fetching cities: $cities");
      if (cities.isNotEmpty) {
        selectedCity = cities.first;
      }
    });
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      isLoading = true;
    });

    final fetchedWeatherData = await fetchWeatherData(selectedProvince, selectedCity);
    setState(() {
      weatherData = fetchedWeatherData;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade300, Colors.blue.shade100],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    lottieImage(),
                    _buildCurrentWeather(),
                    _buildHourlyForecast(),
                    
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
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            icon: Icon(Icons.arrow_drop_down),
            hint: Text('Select province'),
            isExpanded: true,
            value: selectedProvince,
            items: provinces.map((String province) {
              return DropdownMenuItem<String>(
                value: province,
                child: Text(province),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedProvince = newValue;
                });
                _fetchCities();
                _savePreferences();
              }
            },
          ),
          DropdownButton<String>(
            isExpanded: true,
            value: selectedCity,
            items: cities.map((String city) {
              return DropdownMenuItem<String>(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedCity = newValue;
                });
                _fetchWeatherData();
                _savePreferences();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    final currentWeather = weatherData['params'].firstWhere((param) => param['id'] == 'weather');
    final currentTemp = weatherData['params'].firstWhere((param) => param['id'] == 't');
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
  }

  Widget _buildHourlyForecast() {
    final hourlyWeather = weatherData['params'].firstWhere((param) => param['id'] == 'weather');
    final hourlyTemp = weatherData['params'].firstWhere((param) => param['id'] == 't');

    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyWeather['times'].length,
        itemBuilder: (context, index) {
          final weather = hourlyWeather['times'][index];
          final temp = hourlyTemp['times'][index];
          final time = parseIssueDate(weather['datetime']);

          return Card(
            color: Colors.white.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$time'),
                  Icon(getWeatherIcon(weather['code'])),
                  Text('${temp['celcius']}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  
}
