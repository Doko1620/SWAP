// ignore: camel_case_types
class weather{

  final String cityName;
  final double temperature;
  final String mainWeather;

  weather({
    required this.cityName,
    required this.temperature,
    required this.mainWeather,
  });

  factory weather.fromJson(Map<String, dynamic> json){
    return weather(
      cityName: json['name'], 
      temperature: json['main']['temp'].toDouble(), 
      mainWeather: json['weather'][0]['main'],
      );
  }
}
