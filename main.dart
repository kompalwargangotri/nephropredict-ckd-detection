import 'package:flutter/material.dart';
import 'api_service.dart';

void main() => runApp(NephroPredictApp());

class NephroPredictApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NephroPredict',
      theme: ThemeData(
        primaryColor: Color(0xFF003366),
        scaffoldBackgroundColor: Color(0xFFF2F7FF),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  @override
  _PredictionPageState createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  // Controllers for numeric inputs
  final Map<String, TextEditingController> controllers = {
    'Age': TextEditingController(text: "45"),
    'BMI': TextEditingController(text: "24.5"),
    'SystolicBP': TextEditingController(text: "120"),
    'DiastolicBP': TextEditingController(text: "80"),
    'SerumCreatinine': TextEditingController(text: "1.0"),
    'BUNLevels': TextEditingController(text: "18.0"),
    'GFR': TextEditingController(text: "90.0"),
    'HemoglobinLevels': TextEditingController(text: "14.0"),
    'ProteinInUrine': TextEditingController(text: "0.0"),
    'SerumElectrolytesSodium': TextEditingController(text: "138.0"),
    'SerumElectrolytesPotassium': TextEditingController(text: "4.3"),
    'SerumElectrolytesCalcium': TextEditingController(text: "9.5"),
    'SerumElectrolytesPhosphorus': TextEditingController(text: "4.0"),
    'FatigueLevels': TextEditingController(text: "4"),
  };

  // Dropdown fields
  String gender = "Male";
  String smoking = "no";
  String alcohol = "no";
  String diabetes = "no";
  String hypertension = "no";
  String edema = "no";

  String prediction = "";
  double proba = 0.0;
  bool loading = false;

  Future<void> submit() async {
    setState(() => loading = true);

    Map<String, dynamic> data = {
      ...controllers.map((key, value) => MapEntry(key, value.text)),
      "Gender": gender,
      "Smoking": smoking,
      "AlcoholConsumption": alcohol,
      "Diabetes": diabetes,
      "Hypertension": hypertension,
      "Edema": edema,
    };

    final response = await ApiService.predictCKD(data);

    setState(() {
      prediction = response["prediction"];
      proba = response["proba"];
      loading = false;
    });
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildDropdown(String label, String value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: value,
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🩺 NephroPredict"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "🌿 Early Detection of Chronic Kidney Disease",
              style: TextStyle(fontSize: 18, color: Color(0xFF003366), fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            // Two-column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      buildTextField("Age (years)", controllers['Age']!),
                      buildDropdown("Gender", gender, ["Male", "Female"], (val) => setState(() => gender = val!)),
                      buildTextField("BMI", controllers['BMI']!),
                      buildTextField("Systolic BP", controllers['SystolicBP']!),
                      buildTextField("Diastolic BP", controllers['DiastolicBP']!),
                      buildTextField("Serum Creatinine", controllers['SerumCreatinine']!),
                      buildTextField("BUN Levels", controllers['BUNLevels']!),
                      buildTextField("GFR", controllers['GFR']!),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      buildTextField("Hemoglobin", controllers['HemoglobinLevels']!),
                      buildTextField("Protein in Urine", controllers['ProteinInUrine']!),
                      buildTextField("Sodium", controllers['SerumElectrolytesSodium']!),
                      buildTextField("Potassium", controllers['SerumElectrolytesPotassium']!),
                      buildTextField("Calcium", controllers['SerumElectrolytesCalcium']!),
                      buildTextField("Phosphorus", controllers['SerumElectrolytesPhosphorus']!),
                      buildDropdown("Smoking", smoking, ["yes", "no"], (val) => setState(() => smoking = val!)),
                      buildDropdown("Alcohol", alcohol, ["yes", "no"], (val) => setState(() => alcohol = val!)),
                      buildDropdown("Diabetes", diabetes, ["yes", "no"], (val) => setState(() => diabetes = val!)),
                      buildDropdown("Hypertension", hypertension, ["yes", "no"], (val) => setState(() => hypertension = val!)),
                      buildDropdown("Edema", edema, ["yes", "no"], (val) => setState(() => edema = val!)),
                      buildTextField("Fatigue (1-10)", controllers['FatigueLevels']!),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : submit,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Color(0xFF0066cc),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: loading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("🔍 Predict CKD", style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 20),

            if (prediction.isNotEmpty)
              Card(
                color: prediction == "No CKD Detected" ? Colors.green[100] : Colors.red[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text("📊 Prediction: $prediction",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (prediction != "Error")
                        Text("Probability: ${(proba * 100).toStringAsFixed(1)}%",
                            style: TextStyle(fontSize: 16)),
                      if (prediction == "No CKD Detected")
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            "Your kidney parameters appear healthy. Keep maintaining a balanced lifestyle!",
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (prediction != "No CKD Detected")
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            "⚠️ Please consult a nephrologist for further diagnosis and management.",
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
