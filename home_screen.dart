import 'package:flutter/material.dart';
import '../api_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();

  final ageController = TextEditingController();
  final bpController = TextEditingController();

  String rbcValue = "normal";

  bool isLoading = false;

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    Map<String, dynamic> inputData = {
      "age": int.parse(ageController.text),
      "bp": int.parse(bpController.text),
      "rbc": rbcValue,
    };

    String result = await ApiService.predictCKD(inputData);

    setState(() => isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CKD Prediction"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: "Age",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: bpController,
                decoration: const InputDecoration(
                  labelText: "Blood Pressure",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField(
                value: rbcValue,
                items: ["normal", "abnormal"]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toUpperCase()),
                        ))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: "Red Blood Cells",
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => rbcValue = v!),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: isLoading ? null : _predict,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Predict"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
