import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  
//static const String baseUrl = "http://10.83.34.48:5000/predict";
static const String baseUrl = "http://10.87.9.48:5000/predict";

  static Future<Map<String, dynamic>> predictCKD(Map<String, dynamic> patientData) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: patientData,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          "prediction": jsonResponse["prediction"],
          "proba": jsonResponse["proba"]
        };
      } else {
        return {
          "prediction": "Server Error: ${response.statusCode}",
          "proba": 0.0
        };
      }
    } catch (e) {
      return {
        "prediction": "Error: $e",
        "proba": 0.0
      };
    }
  }
}
