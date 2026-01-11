from flask import Flask, render_template, request, jsonify
import pandas as pd
import joblib
import os

app = Flask(__name__)

base_path = os.path.dirname(__file__)
model = joblib.load(os.path.join(base_path, "nephropredict_best_model.pkl"))
scaler = joblib.load(os.path.join(base_path, "nephropredict_scaler.pkl"))
feature_list = joblib.load(os.path.join(base_path, "nephropredict_feature_list.pkl"))

@app.route("/predict", methods=["POST"])
def predict_ckd():
    try:
    
        if request.is_json:
            data = request.get_json()
        else:
           
            data = request.form.to_dict()

        numeric_fields = [
            'Age', 'BMI', 'SystolicBP', 'DiastolicBP', 'SerumCreatinine', 'BUNLevels',
            'GFR', 'HemoglobinLevels', 'ProteinInUrine',
            'SerumElectrolytesSodium', 'SerumElectrolytesPotassium',
            'SerumElectrolytesCalcium', 'SerumElectrolytesPhosphorus', 'FatigueLevels'
        ]
        for field in numeric_fields:
            if field in data:
                data[field] = float(data[field])

        yes_no_fields = ['Smoking', 'AlcoholConsumption', 'Diabetes', 'Hypertension', 'Edema']
        for field in yes_no_fields:
            if field in data:
                data[field] = 1 if str(data[field]).lower() == "yes" else 0

        if "Gender" in data:
            data["Gender"] = 1 if str(data["Gender"]).lower() == "male" else 0

        for col in feature_list:
            if col not in data:
                data[col] = 0

        input_df = pd.DataFrame([data])[feature_list]

        input_scaled = scaler.transform(input_df)
        proba = model.predict_proba(input_scaled)[0][1]
        threshold = 0.5
        prediction_text = "Chronic Kidney Disease Detected" if proba >= threshold else "No CKD Detected"

        return jsonify({
            "prediction": prediction_text,
            "proba": round(proba, 2)
        })

    except Exception as e:
        return jsonify({
            "prediction": "Error",
            "proba": 0.0,
            "error": str(e)
        })

@app.route("/", methods=["GET", "POST"])
def index():
    prediction = None
    proba = None
    if request.method == "POST":
        try:
        
            form = request.form.to_dict()

            numeric_fields = [
                'Age', 'BMI', 'SystolicBP', 'DiastolicBP', 'SerumCreatinine', 'BUNLevels',
                'GFR', 'HemoglobinLevels', 'ProteinInUrine',
                'SerumElectrolytesSodium', 'SerumElectrolytesPotassium',
                'SerumElectrolytesCalcium', 'SerumElectrolytesPhosphorus', 'FatigueLevels'
            ]
            for field in numeric_fields:
                if field in form:
                    form[field] = float(form[field])

            yes_no_fields = ['Smoking', 'AlcoholConsumption', 'Diabetes', 'Hypertension', 'Edema']
            for field in yes_no_fields:
                if field in form:
                    form[field] = 1 if form[field].lower() == "yes" else 0

            if "Gender" in form:
                form["Gender"] = 1 if form["Gender"].lower() == "male" else 0

            for col in feature_list:
                if col not in form:
                    form[col] = 0

            input_df = pd.DataFrame([form])[feature_list]
            input_scaled = scaler.transform(input_df)
            proba = model.predict_proba(input_scaled)[0][1]
            threshold = 0.5
            prediction = "Chronic Kidney Disease Detected" if proba >= threshold else "No CKD Detected"

        except Exception as e:
            prediction = f"Error: {e}"
            proba = 0.0

    return render_template("index.html", prediction=prediction, proba=proba)
  
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
