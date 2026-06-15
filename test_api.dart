import 'package:dio/dio.dart';

void main() async {
  String token = "%7B%22c%22%3A%221120%22%2C%22e%22%3A%2212b%22%2C%22t%22%3A1781496474%2C%22p%22%3A0%2C%22s%22%3A%220dae38e13b6f18514f24034dbc4b7710%22%7D";
  final res = await Dio().post('https://v.anime1.me/api',
      data: 'd=$token',
      options: Options(contentType: 'application/x-www-form-urlencoded'));
  
  List<String>? cookies = res.headers['set-cookie'];
  print(cookies);
  
  String finalCookie = '';
  if (cookies != null) {
    String baseCookieString = cookies.join('; ');
    baseCookieString.split('; ').forEach((cookieString) {
      if (cookieString.contains('=')) {
        List<String> cookieParts = cookieString.split('=');
        if (cookieParts[0] == 'e' ||
            cookieParts[0] == 'p' ||
            cookieParts[0] == 'h' ||
            cookieParts[0].startsWith('_ga')) {
          finalCookie = '$finalCookie${cookieParts[0]}=${cookieParts[1]}; ';
        }
      }
    });
  }
  print(finalCookie);
}