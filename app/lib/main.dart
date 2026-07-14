import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const NephroPredictApp());
}

class NephroPredictApp extends StatelessWidget {
  const NephroPredictApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NephroPredict',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        primaryColor: const Color(0xFF0EA5E9), // Sky 500
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0EA5E9),
          secondary: Color(0xFF10B981), // Emerald 500
          surface: Color(0xFF1E293B), // Slate 800
          error: Color(0xFFEF4444),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF94A3B8), // Slate 400
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF334155), // Slate 700
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Connection Configuration
  String _apiBaseUrl = "http://localhost:5000";

  // Navigation & UI States
  int _currentStep = 0;
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;
  int _currentTab = 0;
  bool _hasStartedAssessment = false;
  List<dynamic> _historyRecords = [];
  bool _loadingHistory = false;

  // Controllers & Form variables
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _gender = "";
  final TextEditingController _bmiController = TextEditingController();
  final TextEditingController _systolicBPController = TextEditingController();
  final TextEditingController _diastolicBPController = TextEditingController();
  String _smoking = "";
  String _alcohol = "";

  // Lab Results
  final TextEditingController _serumCreatinineController =
      TextEditingController();
  final TextEditingController _bunController = TextEditingController();
  final TextEditingController _gfrController = TextEditingController();
  final TextEditingController _hemoglobinController = TextEditingController();
  final TextEditingController _proteinInUrineController =
      TextEditingController();

  // Electrolytes & Symptoms
  final TextEditingController _sodiumController = TextEditingController();
  final TextEditingController _potassiumController = TextEditingController();
  final TextEditingController _calciumController = TextEditingController();
  final TextEditingController _phosphorusController = TextEditingController();
  String _diabetes = "";
  String _hypertension = "";
  String _edema = "";
  double _fatigueLevel = 4.0;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bmiController.dispose();
    _systolicBPController.dispose();
    _diastolicBPController.dispose();
    _serumCreatinineController.dispose();
    _bunController.dispose();
    _gfrController.dispose();
    _hemoglobinController.dispose();
    _proteinInUrineController.dispose();
    _sodiumController.dispose();
    _potassiumController.dispose();
    _calciumController.dispose();
    _phosphorusController.dispose();
    super.dispose();
  }

  // API Call logic
  Future<void> _runInference() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    final payload = {
      "PatientName": _nameController.text.trim(),
      "Age": int.tryParse(_ageController.text) ?? 45,
      "Gender": _gender,
      "BMI": double.tryParse(_bmiController.text) ?? 24.5,
      "SystolicBP": int.tryParse(_systolicBPController.text) ?? 120,
      "DiastolicBP": int.tryParse(_diastolicBPController.text) ?? 80,
      "SerumCreatinine":
          double.tryParse(_serumCreatinineController.text) ?? 1.0,
      "BUNLevels": double.tryParse(_bunController.text) ?? 18.0,
      "GFR": double.tryParse(_gfrController.text) ?? 90.0,
      "HemoglobinLevels": double.tryParse(_hemoglobinController.text) ?? 14.0,
      "ProteinInUrine": double.tryParse(_proteinInUrineController.text) ?? 0.0,
      "SerumElectrolytesSodium":
          double.tryParse(_sodiumController.text) ?? 138.0,
      "SerumElectrolytesPotassium":
          double.tryParse(_potassiumController.text) ?? 4.3,
      "SerumElectrolytesCalcium":
          double.tryParse(_calciumController.text) ?? 9.5,
      "SerumElectrolytesPhosphorus":
          double.tryParse(_phosphorusController.text) ?? 4.0,
      "Smoking": _smoking,
      "AlcoholConsumption": _alcohol,
      "Diabetes": _diabetes,
      "Hypertension": _hypertension,
      "Edema": _edema,
      "FatigueLevels": _fatigueLevel.toInt(),
    };

    try {
      final response = await http
          .post(
            Uri.parse("$_apiBaseUrl/predict"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _predictionResult = jsonDecode(response.body);
        });
      } else {
        _showErrorSnackBar(
          "Server returned error code: ${response.statusCode}",
        );
      }
    } catch (e) {
      _showErrorSnackBar("Failed to connect to API backend: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loadingHistory = true;
    });

    try {
      final response = await http
          .get(
            Uri.parse("$_apiBaseUrl/history"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _historyRecords = data['history'] ?? [];
          });
        } else {
          _showErrorSnackBar("Failed to load history: ${data['error']}");
        }
      } else {
        _showErrorSnackBar(
          "Server returned error code: ${response.statusCode}",
        );
      }
    } catch (e) {
      _showErrorSnackBar("Failed to connect to backend: $e");
    } finally {
      setState(() {
        _loadingHistory = false;
      });
    }
  }

  Future<void> _deleteRecord(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse("$_apiBaseUrl/history/$id"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (!mounted) return;
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Record deleted successfully"),
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _fetchHistory();
        } else {
          _showErrorSnackBar("Failed to delete record: ${data['error']}");
        }
      } else {
        _showErrorSnackBar("Server returned error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("Failed to connect to backend: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSettingsDialog() {
    final settingsController = TextEditingController(text: _apiBaseUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Connection Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Flask API Base URL:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: settingsController,
                decoration: const InputDecoration(
                  hintText: "e.g. http://localhost:5000",
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "💡 Note:\n- Use http://10.0.2.2:5000 for Android Emulator.\n- Use http://localhost:5000 for iOS or Web browser.\n- Use local IP (e.g. http://192.168.x.x:5000) for physical mobile devices.",
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _apiBaseUrl = settingsController.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("API Base URL set to: $_apiBaseUrl"),
                    backgroundColor: Colors.teal,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _predictionResult = null;
      _hasStartedAssessment = false;
      _nameController.clear();
      _ageController.clear();
      _gender = "";
      _bmiController.clear();
      _systolicBPController.clear();
      _diastolicBPController.clear();
      _smoking = "";
      _alcohol = "";
      _serumCreatinineController.clear();
      _bunController.clear();
      _gfrController.clear();
      _hemoglobinController.clear();
      _proteinInUrineController.clear();
      _sodiumController.clear();
      _potassiumController.clear();
      _calciumController.clear();
      _phosphorusController.clear();
      _diabetes = "";
      _hypertension = "";
      _edema = "";
      _fatigueLevel = 4.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.health_and_safety, color: Color(0xFF0EA5E9)),
            const SizedBox(width: 10),
            Text(
              "NephroPredict",
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Settings",
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 650 : double.infinity,
            ),
            child: _currentTab == 1
                ? _buildHistoryView(theme)
                : Form(
                    key: _formKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _predictionResult != null
                          ? _buildResultCard(theme)
                          : _isLoading
                          ? _buildLoadingCard(theme)
                          : !_hasStartedAssessment
                          ? _buildWelcomeCard(theme)
                          : _buildFormCard(theme),
                    ),
                  ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
          if (index == 1) {
            _fetchHistory();
          }
        },
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF0EA5E9),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: "Evaluate",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open_outlined),
            label: "History",
          ),
        ],
      ),
    );
  }

  // --- Step 1: Form View ---
  Widget _buildFormCard(ThemeData theme) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("CKD Risk Assessment", style: theme.textTheme.headlineMedium),
            const SizedBox(height: 5),
            const Text(
              "Provide the patient's parameters to estimate Chronic Kidney Disease risk.",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 25),

            // Custom Visual Tab Indicators
            _buildStepIndicators(),
            const SizedBox(height: 25),

            // Animated Form Steps content
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _buildCurrentFormStep(theme),
            ),
            const SizedBox(height: 30),

            // Navigation Actions
            _buildNavigationButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicators() {
    List<String> stepTitles = ["Vitals", "Lab Tests", "Symptoms"];
    return Row(
      children: List.generate(3, (index) {
        bool isActive = _currentStep == index;
        bool isDone = _currentStep > index;
        return Expanded(
          child: InkWell(
            onTap: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _currentStep = index;
                });
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF0EA5E9)
                        : isDone
                        ? const Color(0xFF10B981)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stepTitles[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Colors.white
                        : isDone
                        ? const Color(0xFF10B981)
                        : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentFormStep(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildVitalsStep(theme);
      case 1:
        return _buildLabsStep(theme);
      case 2:
        return _buildSymptomsStep(theme);
      default:
        return Container();
    }
  }

  // Form Step 1: Vitals & Demographics
  Widget _buildVitalsStep(ThemeData theme) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Demographics & Base Metrics"),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Age",
                  suffixText: "yrs",
                  helperText: "Range: 1 - 120",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final numVal = int.tryParse(val);
                  if (numVal == null) return "Invalid";
                  if (numVal < 1 || numVal > 120) return "Must be 1 - 120";
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: _bmiController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "BMI",
                  suffixText: "kg/m²",
                  helperText: "Range: 10 - 50",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final numVal = double.tryParse(val);
                  if (numVal == null) return "Invalid";
                  if (numVal < 10.0 || numVal > 50.0) return "Must be 10 - 50";
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          "Gender",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 8),
        _buildChoiceChips(
          values: ["Male", "Female"],
          currentValue: _gender,
          onSelected: (val) => setState(() => _gender = val),
        ),
        const SizedBox(height: 25),
        _buildSectionHeader("Blood Pressure (BP)"),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _systolicBPController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Systolic BP",
                  suffixText: "mmHg",
                  helperText: "Range: 80 - 200",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final numVal = int.tryParse(val);
                  if (numVal == null) return "Invalid";
                  if (numVal < 80 || numVal > 200) return "Must be 80 - 200";
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: _diastolicBPController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Diastolic BP",
                  suffixText: "mmHg",
                  helperText: "Range: 50 - 120",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final numVal = int.tryParse(val);
                  if (numVal == null) return "Invalid";
                  if (numVal < 50 || numVal > 120) return "Must be 50 - 120";
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        _buildSectionHeader("Lifestyle Risk Factors"),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Smoker",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildChoiceChips(
                    values: ["yes", "no"],
                    currentValue: _smoking,
                    onSelected: (val) => setState(() => _smoking = val),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Alcohol",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildChoiceChips(
                    values: ["yes", "no"],
                    currentValue: _alcohol,
                    onSelected: (val) => setState(() => _alcohol = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Form Step 2: Lab Results
  Widget _buildLabsStep(ThemeData theme) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Kidney Function Indicators"),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _serumCreatinineController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Serum Creatinine",
                  suffixText: "mg/dL",
                  helperText: "Range: 0.5 - 15.0",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final numVal = double.tryParse(val);
                  if (numVal == null) return "Invalid";
                  if (numVal < 0.5 || numVal > 15.0)
                    return "Must be 0.5 - 15.0";
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: _gfrController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "GFR Rate",
                  suffixText: "mL/min",
                  helperText: "Range: 10 - 120",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final numVal = double.tryParse(val);
                  if (numVal == null) return "Invalid";
                  if (numVal < 10.0 || numVal > 120.0)
                    return "Must be 10 - 120";
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _bunController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "BUN Levels",
                  suffixText: "mg/dL",
                  helperText: "Range: 5 - 50",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final numVal = double.tryParse(val);
                  if (numVal == null) return "Invalid";
                  if (numVal < 5.0 || numVal > 50.0) return "Must be 5 - 50";
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: _proteinInUrineController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Protein In Urine",
                  suffixText: "g/day",
                  helperText: "Range: 0.0 - 10.0",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final numVal = double.tryParse(val);
                  if (numVal == null) return "Invalid";
                  if (numVal < 0.0 || numVal > 10.0)
                    return "Must be 0.0 - 10.0";
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSectionHeader("Blood Metrics"),
        const SizedBox(height: 15),
        TextFormField(
          controller: _hemoglobinController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Hemoglobin",
            suffixText: "g/dL",
            helperText: "Range: 5.0 - 17.0",
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return "Required";
            final numVal = double.tryParse(val);
            if (numVal == null) return "Invalid";
            if (numVal < 5.0 || numVal > 17.0) return "Must be 5.0 - 17.0";
            return null;
          },
        ),
      ],
    );
  }

  // Form Step 3: Electrolytes & Symptoms
  Widget _buildSymptomsStep(ThemeData theme) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Electrolytes (Serum levels)"),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _sodiumController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Sodium (Na)",
                  suffixText: "mEq/L",
                  helperText: "Range: 120 - 155",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final numVal = double.tryParse(val);
                  if (numVal == null) return "Invalid";
                  if (numVal < 120.0 || numVal > 155.0)
                    return "Must be 120 - 155";
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: _potassiumController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Potassium (K)",
                  suffixText: "mEq/L",
                  helperText: "Range: 2.5 - 6.5",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final numVal = double.tryParse(val);
                  if (numVal == null) return "Invalid";
                  if (numVal < 2.5 || numVal > 6.5) return "Must be 2.5 - 6.5";
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _calciumController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Calcium (Ca)",
                  suffixText: "mg/dL",
                  helperText: "Range: 6.0 - 11.0",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final numVal = double.tryParse(val);
                  if (numVal == null) return "Invalid";
                  if (numVal < 6.0 || numVal > 11.0)
                    return "Must be 6.0 - 11.0";
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: _phosphorusController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Phosphorus (P)",
                  suffixText: "mg/dL",
                  helperText: "Range: 2.0 - 6.0",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  final numVal = double.tryParse(val);
                  if (numVal == null) return "Invalid";
                  if (numVal < 2.0 || numVal > 6.0) return "Must be 2.0 - 6.0";
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        _buildSectionHeader("Co-morbidities & Physical Symptoms"),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Diabetes",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildChoiceChips(
                    values: ["yes", "no"],
                    currentValue: _diabetes,
                    onSelected: (val) => setState(() => _diabetes = val),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hypertension",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildChoiceChips(
                    values: ["yes", "no"],
                    currentValue: _hypertension,
                    onSelected: (val) => setState(() => _hypertension = val),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          "Edema (Swelling)",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 8),
        _buildChoiceChips(
          values: ["yes", "no"],
          currentValue: _edema,
          onSelected: (val) => setState(() => _edema = val),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Fatigue Level",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Text(
              "${_fatigueLevel.toInt()} / 10",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
        Slider(
          value: _fatigueLevel,
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: const Color(0xFF0EA5E9),
          onChanged: (val) {
            setState(() {
              _fatigueLevel = val;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0EA5E9),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildChoiceChips({
    required List<String> values,
    required String currentValue,
    required Function(String) onSelected,
  }) {
    return Row(
      children: values.map((val) {
        bool selected = currentValue == val;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () => onSelected(val),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(10),
                  border: selected
                      ? Border.all(color: Colors.white24, width: 1.5)
                      : null,
                ),
                child: Text(
                  val.toUpperCase(),
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _currentStep--;
              });
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text("Back"),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
          )
        else
          const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _currentStep < 2
              ? () {
                  if (_formKey.currentState!.validate()) {
                    if (_currentStep == 0) {
                      if (_gender.isEmpty) {
                        _showErrorSnackBar("Please select Gender");
                        return;
                      }
                      if (_smoking.isEmpty) {
                        _showErrorSnackBar("Please select Smoking status");
                        return;
                      }
                      if (_alcohol.isEmpty) {
                        _showErrorSnackBar(
                          "Please select Alcohol Consumption status",
                        );
                        return;
                      }
                    }
                    setState(() {
                      _currentStep++;
                    });
                  }
                }
              : () {
                  if (_formKey.currentState!.validate()) {
                    if (_diabetes.isEmpty) {
                      _showErrorSnackBar("Please select Diabetes status");
                      return;
                    }
                    if (_hypertension.isEmpty) {
                      _showErrorSnackBar("Please select Hypertension status");
                      return;
                    }
                    if (_edema.isEmpty) {
                      _showErrorSnackBar("Please select Edema status");
                      return;
                    }
                    _runInference();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _currentStep < 2
                ? const Color(0xFF38BDF8)
                : const Color(0xFF10B981),
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentStep < 2 ? "Continue" : "Predict CKD",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Icon(
                _currentStep < 2 ? Icons.arrow_forward : Icons.science_outlined,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Step 2: Loading State View ---
  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surface,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 50, horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 5),
            SizedBox(height: 25),
            Text(
              "Analyzing Kidney Metrics...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Communicating with NephroPredict ML Engine",
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 3: Result View ---
  Widget _buildResultCard(ThemeData theme) {
    final result = _predictionResult!;
    bool hasCKD = result['prediction'] == 1;
    double probability = result['probability'] ?? 0.0;
    String advice = result['advice'] ?? '';
    String predictionText = result['prediction_text'] ?? '';

    Color statusColor = hasCKD
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    IconData statusIcon = hasCKD
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;

    return Card(
      elevation: 12,
      shadowColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Icon(statusIcon, color: statusColor, size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    "ASSESSMENT REPORT",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _nameController.text.trim(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Premium Radial Progress Gauge
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: probability,
                    strokeWidth: 14,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${(probability * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "CKD Probability",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 35),

            // Custom Rounded Label Card for diagnosis result
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    predictionText.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasCKD ? "HIGH RISK DETECTED" : "LOW RISK / NORMAL",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Medical Advice Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF38BDF8),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      advice,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),

            // Reset Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155), // Slate 700
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _resetForm,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Evaluate New Patient",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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

  Widget _buildWelcomeCard(ThemeData theme) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.health_and_safety_outlined,
              size: 72,
              color: Color(0xFF0EA5E9),
            ),
            const SizedBox(height: 20),
            Text(
              "Welcome to NephroPredict",
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Begin a new patient evaluation to estimate the risk of Chronic Kidney Disease (CKD) based on clinical and laboratory findings.",
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Patient Name",
                prefixIcon: Icon(Icons.person),
                hintText: "Enter full name",
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return "Required";
                return null;
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _hasStartedAssessment = true;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Start Patient Assessment",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView(ThemeData theme) {
    if (_loadingHistory) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading clinical history..."),
            ],
          ),
        ),
      );
    }

    if (_historyRecords.isEmpty) {
      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_open_outlined,
                size: 64,
                color: Colors.white24,
              ),
              const SizedBox(height: 20),
              Text(
                "No Saved Patient Records",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "When you run a CKD risk assessment, the patient profile and prediction report will be stored here.",
                style: TextStyle(color: Colors.white38, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentTab = 0;
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Run Assessment Now"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Patient Database",
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF0EA5E9)),
                  onPressed: _fetchHistory,
                  tooltip: "Refresh database",
                ),
              ],
            ),
            const SizedBox(height: 15),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _historyRecords.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final record = _historyRecords[index];
                final name = record['name'] ?? 'Anonymous';
                final timestamp = record['timestamp'] ?? '';
                final double probability = (record['probability'] ?? 0.0)
                    .toDouble();
                final int prediction = record['prediction'] ?? 0;
                final bool hasCKD = prediction == 1;

                Color statusColor = hasCKD
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981);
                String formattedDate = _formatTimestamp(timestamp);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    child: Text(
                      "${(probability * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    "Date: $formattedDate\nRisk: ${hasCKD ? 'High Risk' : 'Low Risk'}",
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.analytics_outlined,
                          color: Color(0xFF38BDF8),
                        ),
                        tooltip: "View full report",
                        onPressed: () => _showRecordDetailsDialog(record),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        tooltip: "Delete record",
                        onPressed: () =>
                            _showDeleteConfirmation(record['id'], name),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return 'N/A';
    try {
      final parts = timestamp.split(' ');
      if (parts.isNotEmpty) {
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          return "${dateParts[2]}/${dateParts[1]}/${dateParts[0]}";
        }
      }
      return timestamp;
    } catch (_) {
      return timestamp;
    }
  }

  void _showRecordDetailsDialog(Map<String, dynamic> record) {
    final name = record['name'] ?? 'Anonymous';
    final double probability = (record['probability'] ?? 0.0).toDouble();
    final bool hasCKD = (record['prediction'] ?? 0) == 1;
    final formattedDate = _formatTimestamp(record['timestamp'] ?? '');

    Color statusColor = hasCKD
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF1E293B),
          title: Row(
            children: [
              Icon(
                hasCKD
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: statusColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Assessment Date: $formattedDate",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Calculated CKD Probability:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${(probability * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Demographics & Vitals",
                    style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  _buildDetailRow("Age", "${record['age']} yrs"),
                  _buildDetailRow("Gender", "${record['gender']}"),
                  _buildDetailRow("BMI", "${record['bmi']} kg/m²"),
                  _buildDetailRow(
                    "Blood Pressure",
                    "${record['systolic_bp']}/${record['diastolic_bp']} mmHg",
                  ),
                  _buildDetailRow("Smoker", "${record['smoking']}"),
                  _buildDetailRow("Alcohol Usage", "${record['alcohol']}"),
                  const SizedBox(height: 20),
                  const Text(
                    "Laboratory Tests",
                    style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  _buildDetailRow(
                    "Serum Creatinine",
                    "${record['serum_creatinine']} mg/dL",
                  ),
                  _buildDetailRow(
                    "GFR Filtration Rate",
                    "${record['gfr']} mL/min",
                  ),
                  _buildDetailRow(
                    "BUN Levels",
                    "${record['bun_levels']} mg/dL",
                  ),
                  _buildDetailRow(
                    "Protein In Urine",
                    "${record['protein_in_urine']} g/day",
                  ),
                  _buildDetailRow("Hemoglobin", "${record['hemoglobin']} g/dL"),
                  const SizedBox(height: 20),
                  const Text(
                    "Electrolytes & Comorbidities",
                    style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  _buildDetailRow(
                    "Sodium (Na) / Potassium (K)",
                    "${record['sodium']} / ${record['potassium']} mEq/L",
                  ),
                  _buildDetailRow(
                    "Calcium (Ca) / Phosphorus (P)",
                    "${record['calcium']} / ${record['phosphorus']} mg/dL",
                  ),
                  _buildDetailRow("Diabetes Presence", "${record['diabetes']}"),
                  _buildDetailRow(
                    "Hypertension Status",
                    "${record['hypertension']}",
                  ),
                  _buildDetailRow("Edema (Swelling)", "${record['edema']}"),
                  _buildDetailRow("Fatigue Score", "${record['fatigue']} / 10"),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF334155),
              ),
              child: const Text("Close", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(dynamic id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Delete Record"),
          content: Text(
            "Are you sure you want to delete the clinical record for $name?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (id is int) {
                  _deleteRecord(id);
                } else if (id is String) {
                  final parsedId = int.tryParse(id);
                  if (parsedId != null) {
                    _deleteRecord(parsedId);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
