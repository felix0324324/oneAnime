void main() {
  List<String> baseCookies = [
    "e=1781525274; expires=Mon, 15 Jun 2026 12:07:54 GMT; Max-Age=28784; path=/1120/12b.mp4; domain=.v.anime1.me; secure; HttpOnly",
    "p=eyJpc3MiOiJhbmltZTEubWUiLCJleHAiOjE3ODE1MjUyNzQwMDAsImlhdCI6MTc4MTQ5NjQ5MDAwMCwic3ViIjoiLzExMjAvMTJiLm1wNCJ9; expires=Mon, 15 Jun 2026 12:07:54 GMT; Max-Age=28784; path=/1120/12b.mp4; domain=.v.anime1.me; secure; HttpOnly",
    "h=7taJgwJGMWmk5Ccl97iuFA; expires=Mon, 15 Jun 2026 12:07:54 GMT; Max-Age=28784; path=/1120/12b.mp4; domain=.v.anime1.me; secure; HttpOnly"
  ];
  String finalCookie = '';
  String baseCookieString = baseCookies.join('; ');
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
  print(finalCookie);
}