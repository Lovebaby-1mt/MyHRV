from flask import Flask, request, jsonify, send_from_directory
import pandas as pd
import neurokit2 as nk
import io
import os

app = Flask(__name__, static_folder='../frontend')

@app.route('/')
def serve_index():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    return send_from_directory(app.static_folder, path)

@app.route('/analyze_hrv', methods=['POST'])
def analyze_hrv():
    files = request.get_json()
    hr_data = files.get('hr_data')
    ecg_data = files.get('ecg_data')

    if not hr_data:
        return jsonify({"error": "HR data is required"}), 400

    # Process HR data
    hr_df = pd.read_csv(io.StringIO(hr_data), comment='#', header=0)
    if 'SC' in hr_df.columns and 'RR' in hr_df.columns:
        rr_intervals = hr_df[hr_df['SC'] == 1]['RR'].dropna().tolist()
    else:
        if hr_df.shape[1] >= 2:
            rr_intervals = hr_df.iloc[:, 1].dropna().tolist()
        else:
            return jsonify({"error": "Invalid HR data format"}), 400

    if not rr_intervals:
        return jsonify({"error": "No valid RR intervals found"}), 400

    peaks = nk.intervals_to_peaks(rr_intervals)
    hrv_metrics_df = nk.hrv(peaks, sampling_rate=1000)

    response_data = {
        'metrics': hrv_metrics_df.to_dict(orient='records')[0],
        'cleaned_rr': rr_intervals
    }

    # Process ECG data if available
    if ecg_data:
        ecg_df = pd.read_csv(io.StringIO(ecg_data), comment='#', header=0)
        if 'MS' in ecg_df.columns and 'ECG' in ecg_df.columns:
            response_data['ecg'] = {
                'time': ecg_df['MS'].tolist(),
                'voltage': ecg_df['ECG'].tolist()
            }

    return jsonify(response_data)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
