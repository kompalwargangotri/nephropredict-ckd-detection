# NephroPredict: CKD Prediction Web App

import streamlit as st
import pandas as pd
import joblib
import os

# Page Configuration

st.set_page_config(page_title=" NephroPredict", layout="centered", page_icon="💊")

# Custom Styling (CSS)

st.markdown("""
    <style>
        .main {
            background-color: #f2f7ff;
            padding: 25px;
            border-radius: 12px;
        }
        h1, h2, h3 {
            color: #003366;
            text-align: center;
        }
        .stButton>button {
            background-color: #0066cc;
            color: white;
            border-radius: 10px;
            height: 3em;
            width: 100%;
            font-size: 18px;
        }
        .stButton>button:hover {
            background-color: #004c99;
        }
        .footer {
            text-align: center;
            color: #666;
            margin-top: 50px;
            font-size: 14px;
        }
    </style>
""", unsafe_allow_html=True)

# Load Model and Preprocessing Tools

base_path = os.path.dirname(__file__)
model = joblib.load(os.path.join(base_path, "nephropredict_best_model.pkl"))
scaler = joblib.load(os.path.join(base_path, "nephropredict_scaler.pkl"))
label_encoders = joblib.load(os.path.join(base_path, "nephropredict_label_encoders.pkl"))
feature_list = joblib.load(os.path.join(base_path, "nephropredict_feature_list.pkl"))

# Page Header

st.title("🩺 NephroPredict")
st.markdown("### 🌿 Early Detection of Chronic Kidney Disease using Machine Learning")
st.write("### Enter patient health data below to predict CKD risk.")
st.markdown("---")

# Input Section

st.subheader("📋 Patient Health Information")

col1, col2 = st.columns(2)

with col1:
    Age = st.number_input("Age (years)", 1, 120, 45)
    Gender = st.selectbox("Gender", ["Male", "Female"])
    BMI = st.number_input("Body Mass Index (BMI)", 10.0, 50.0, 24.5)
    SystolicBP = st.number_input("Systolic BP (mmHg)", 80, 200, 120)
    DiastolicBP = st.number_input("Diastolic BP (mmHg)", 50, 120, 80)
    SerumCreatinine = st.number_input("Serum Creatinine (mg/dL)", 0.5, 15.0, 1.0)
    BUNLevels = st.number_input("Blood Urea Nitrogen (mg/dL)", 5.0, 50.0, 18.0)
    GFR = st.number_input("Glomerular Filtration Rate (GFR)", 10.0, 120.0, 90.0)
    HemoglobinLevels = st.number_input("Hemoglobin (g/dL)", 5.0, 17.0, 14.0)
    ProteinInUrine = st.number_input("Protein in Urine (g/day)", 0.0, 10.0, 0.0)

with col2:
    SerumElectrolytesSodium = st.number_input("Sodium (mEq/L)", 120.0, 155.0, 138.0)
    SerumElectrolytesPotassium = st.number_input("Potassium (mEq/L)", 2.5, 6.5, 4.3)
    SerumElectrolytesCalcium = st.number_input("Calcium (mg/dL)", 6.0, 11.0, 9.5)
    SerumElectrolytesPhosphorus = st.number_input("Phosphorus (mg/dL)", 2.0, 6.0, 4.0)
    Smoking = st.selectbox("Smoking", ["yes", "no"])
    AlcoholConsumption = st.selectbox("Alcohol Consumption", ["yes", "no"])
    Diabetes = st.selectbox("Diabetes", ["yes", "no"])
    Hypertension = st.selectbox("Hypertension", ["yes", "no"])
    Edema = st.selectbox("Edema (Swelling)", ["yes", "no"])
    FatigueLevels = st.slider("Fatigue Level (1-10)", 1, 10, 4)

st.markdown("---")

# Prediction Logic with Probability Threshold

if st.button("🔍 Predict CKD Status"):
    try:
        # Construct input dictionary
        input_dict = {
            'Age': Age,
            'Gender': 1 if Gender == "Male" else 0,
            'Ethnicity': 0,
            'SocioeconomicStatus': 0,
            'EducationLevel': 0,
            'BMI': BMI,
            'Smoking': 1 if Smoking == "yes" else 0,
            'AlcoholConsumption': 1 if AlcoholConsumption == "yes" else 0,
            'PhysicalActivity': 1,
            'DietQuality': 1,
            'SleepQuality': 1,
            'FamilyHistoryKidneyDisease': 0,
            'FamilyHistoryHypertension': 0,
            'FamilyHistoryDiabetes': 0,
            'PreviousAcuteKidneyInjury': 0,
            'UrinaryTractInfections': 0,
            'SystolicBP': SystolicBP,
            'DiastolicBP': DiastolicBP,
            'FastingBloodSugar': 90,
            'HbA1c': 5.5,
            'SerumCreatinine': SerumCreatinine,
            'BUNLevels': BUNLevels,
            'GFR': GFR,
            'ProteinInUrine': ProteinInUrine,
            'ACR': 10,
            'SerumElectrolytesSodium': SerumElectrolytesSodium,
            'SerumElectrolytesPotassium': SerumElectrolytesPotassium,
            'SerumElectrolytesCalcium': SerumElectrolytesCalcium,
            'SerumElectrolytesPhosphorus': SerumElectrolytesPhosphorus,
            'HemoglobinLevels': HemoglobinLevels,
            'CholesterolTotal': 180,
            'CholesterolLDL': 100,
            'CholesterolHDL': 50,
            'CholesterolTriglycerides': 120,
            'ACEInhibitors': 0,
            'Diuretics': 0,
            'NSAIDsUse': 0,
            'Statins': 0,
            'AntidiabeticMedications': 0,
            'Edema': 1 if Edema == "yes" else 0,
            'FatigueLevels': FatigueLevels,
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

        # Ensuring all features are present
        for col in feature_list:
            if col not in input_df.columns:
                input_df[col] = 0
        input_df = input_df[feature_list]

        # Scale and predict
        input_scaled = scaler.transform(input_df)
        proba = model.predict_proba(input_scaled)[0][1]
        threshold = 0.6  # Adjust this to tune sensitivity
        pred = 1 if proba >= threshold else 0

        st.markdown("---")
        st.subheader("📊 Prediction Result")
        st.write(f"**Model Confidence (CKD Probability): {proba:.2f}**")

        if pred == 1:
            st.error("🩸 **Chronic Kidney Disease Detected**")
            st.warning("⚠️ Please consult a nephrologist for further diagnosis and management.")
        else:
            st.success("✅ **No CKD Detected**")
            st.balloons()
            st.info("Your kidney parameters appear healthy. Keep maintaining a balanced lifestyle!")

    except Exception as e:
        st.error(f"An error occurred: {e}")

# Footer

st.markdown("---")
