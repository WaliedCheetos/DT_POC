import 'package:http/http.dart' as http;

class FetchData {
  Future<http.Response> fetchDataViaHttp(String url) async {
    return await http.get(url);
  }

  Future<http.Response> fetchData(String url) {
    return http.get(Uri.https(url, ''));
  }
}
