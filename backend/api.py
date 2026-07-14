# NephroPredict: CKD Prediction Flask API

from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import joblib
import os
import sqlite3

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes (to allow mobile/web access)

# Load Model and Preprocessing Tools
base_path = os.path.dirname(__file__)
db_path = os.getenv("NEPHROPREDICT_DB_PATH", os.path.join(base_path, "nephropredict.db"))
model = joblib.load(os.path.join(base_path, "nephropredict_best_model.pkl"))
scaler = joblib.load(os.path.join(base_path, "nephropredict_scaler.pkl"))
feature_list = joblib.load(os.path.join(base_path, "nephropredict_feature_list.pkl"))

# Initialize Database
def init_db():
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS patient_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age REAL,
            gender TEXT,
            bmi REAL,
            systolic_bp REAL,
            diastolic_bp REAL,
            serum_creatinine REAL,
            bun_levels REAL,
            gfr REAL,
            protein_in_urine REAL,
            sodium REAL,
            potassium REAL,
            calcium REAL,
            phosphorus REAL,
            hemoglobin REAL,
            smoking TEXT,
            alcohol TEXT,
            diabetes TEXT,
            hypertension TEXT,
            edema TEXT,
            fatigue REAL,
            probability REAL,
            prediction INTEGER,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

init_db()

@app.route('/', methods=['GET'])
def index():
    return jsonify({
        "status": "online",
        "message": "NephroPredict CKD Prediction API is running successfully. Please send POST requests to /predict to perform inference."
    })

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.json or {}

        # Extract inputs matching the original Streamlit application
        age = float(data.get('Age', 45))
        gender = data.get('Gender', 'Male')
        bmi = float(data.get('BMI', 24.5))
        systolic_bp = float(data.get('SystolicBP', 120))
        diastolic_bp = float(data.get('DiastolicBP', 80))
        serum_creatinine = float(data.get('SerumCreatinine', 1.0))
        bun_levels = float(data.get('BUNLevels', 18.0))
        gfr = float(data.get('GFR', 90.0))
        hemoglobin_levels = float(data.get('HemoglobinLevels', 14.0))
        protein_in_urine = float(data.get('ProteinInUrine', 0.0))

        sodium = float(data.get('SerumElectrolytesSodium', 138.0))
        potassium = float(data.get('SerumElectrolytesPotassium', 4.3))
        calcium = float(data.get('SerumElectrolytesCalcium', 9.5))
        phosphorus = float(data.get('SerumElectrolytesPhosphorus', 4.0))
        smoking = data.get('Smoking', 'no')
        alcohol = data.get('AlcoholConsumption', 'no')
        diabetes = data.get('Diabetes', 'no')
        hypertension = data.get('Hypertension', 'no')
        edema = data.get('Edema', 'no')
        fatigue = float(data.get('FatigueLevels', 4))

        # Construct full input dictionary mapping to model requirements
        input_dict = {
            'Age': age,
            'Gender': 1 if gender.lower() == "male" else 0,
            'Ethnicity': 0,
            'SocioeconomicStatus': 0,
            'EducationLevel': 0,
            'BMI': bmi,
            'Smoking': 1 if smoking.lower() == "yes" else 0,
            'AlcoholConsumption': 1 if alcohol.lower() == "yes" else 0,
            'PhysicalActivity': 1,
            'DietQuality': 1,
            'SleepQuality': 1,
            'FamilyHistoryKidneyDisease': 0,
            'FamilyHistoryHypertension': 0,
            'FamilyHistoryDiabetes': 0,
            'PreviousAcuteKidneyInjury': 0,
            'UrinaryTractInfections': 0,
            'SystolicBP': systolic_bp,
            'DiastolicBP': diastolic_bp,
            'FastingBloodSugar': 90,
            'HbA1c': 5.5,
            'SerumCreatinine': serum_creatinine,
            'BUNLevels': bun_levels,
            'GFR': gfr,
            'ProteinInUrine': protein_in_urine,
            'ACR': 10,
            'SerumElectrolytesSodium': sodium,
            'SerumElectrolytesPotassium': potassium,
            'SerumElectrolytesCalcium': calcium,
            'SerumElectrolytesPhosphorus': phosphorus,
            'HemoglobinLevels': hemoglobin_levels,
            'CholesterolTotal': 180,
            'CholesterolLDL': 100,
            'CholesterolHDL': 50,
            'CholesterolTriglycerides': 120,
            'ACEInhibitors': 0,
            'Diuretics': 0,
            'NSAIDsUse': 0,
            'Statins': 0,
            'AntidiabeticMedications': 0,
            'Edema': 1 if edema.lower() == "yes" else 0,
            'FatigueLevels': fatigue,
            'NauseaVomiting': 0,
            'MuscleCramps': 0,
            'Itching': 0,
            'QualityOfLifeScore': 7,
            'HeavyMetalsExposure': 0,
            'OccupationalExposureChemicals': 0,
            'WaterQuality': 1,
            'MedicalCheckupsFrequency': 2,
            'MedicationAdherence': 1,
            'HealthLiteracy': 1
        }

        input_df = pd.DataFrame([input_dict])

        # Ensure all columns in feature_list exist in the input dataframe
        for col in feature_list:
            if col not in input_df.columns:
                input_df[col] = 0
        input_df = input_df[feature_list]

        # Scale values using loaded scaler
        input_scaled = scaler.transform(input_df)

        # Predict probability of class 1 (CKD positive)
        proba = model.predict_proba(input_scaled)[0][1]

        # Threshold calculation matching streamlit client logic
        threshold = 0.6
        pred = 1 if proba >= threshold else 0

        # Save to database
        patient_name = data.get('PatientName', 'Anonymous')
        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO patient_records (
                    name, age, gender, bmi, systolic_bp, diastolic_bp,
                    serum_creatinine, bun_levels, gfr, protein_in_urine,
                    sodium, potassium, calcium, phosphorus, hemoglobin,
                    smoking, alcohol, diabetes, hypertension, edema,
                    fatigue, probability, prediction
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                patient_name, age, gender, bmi, systolic_bp, diastolic_bp,
                serum_creatinine, bun_levels, gfr, protein_in_urine,
                sodium, potassium, calcium, phosphorus, hemoglobin_levels,
                smoking, alcohol, diabetes, hypertension, edema,
                fatigue, float(proba), int(pred)
            ))
            conn.commit()
            conn.close()
        except Exception as db_err:
            print(f"Database insertion failed: {db_err}")

        return jsonify({
            'success': True,
            'probability': float(proba),
            'prediction': int(pred),
            'prediction_text': "Chronic Kidney Disease Detected" if pred == 1 else "No CKD Detected",
            'advice': "Please consult a nephrologist for further diagnosis and management." if pred == 1 else "Your kidney parameters appear healthy. Keep maintaining a balanced lifestyle!"
        })

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/history', methods=['GET'])
def get_history():
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM patient_records ORDER BY timestamp DESC")
        rows = cursor.fetchall()
        columns = [column[0] for column in cursor.description]
        results = [dict(zip(columns, row)) for row in rows]
        conn.close()
        return jsonify({
            'success': True,
            'history': results
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/history/<int:record_id>', methods=['DELETE'])
def delete_record(record_id):
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("DELETE FROM patient_records WHERE id = ?", (record_id,))
        conn.commit()
        conn.close()
        return jsonify({
            'success': True,
            'message': 'Record deleted successfully'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    # Listen on all local interfaces, port 5000
    app.run(host='0.0.0.0', port=5000, debug=os.getenv('FLASK_DEBUG', '0') == '1')
