from flask import Flask, request, jsonify, send_from_directory
import pandas as pd
import neurokit2 as nk
import numpy as np
import io
import os
from utils import clean_rr_artifacts_py

app = Flask(__name__, static_folder='../frontend')

@app.route('/')
def serve_index():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    return send_from_directory(app.static_folder, path)

@app.route('/analyze_hrv', methods=['POST'])
def analyze_hrv():
    try:
        files = request.get_json()
        hr_data = files.get('hr_data')
        ecg_data = files.get('ecg_data')

        if not hr_data:
            return jsonify({"error": "HR data is required"}), 400

        # Process HR data
        hr_df = pd.read_csv(io.StringIO(hr_data), comment='#', header=0, skipinitialspace=True)
        if 'SC' in hr_df.columns and 'RR' in hr_df.columns:
            rr_intervals = hr_df[hr_df['SC'] == 1]['RR'].dropna().tolist()
        else:
            if hr_df.shape[1] >= 2:
                rr_intervals = hr_df.iloc[:, 1].dropna().tolist()
            else:
                return jsonify({"error": "Invalid HR data format"}), 400

        if not rr_intervals:
            return jsonify({"error": "No valid RR intervals found"}), 400

        rr_intervals_clean = clean_rr_artifacts_py(rr_intervals)

        # --- (V8.6 Port) Moving Window Analysis ---
        def moving_window_analysis(rr_ms, window_sec=300, step_sec=60):
            timestamps_ms = np.cumsum(rr_ms)
            total_duration_sec = timestamps_ms[-1] / 1000 if len(timestamps_ms) > 0 else 0

            results = {
                'time_min': [], 'rmssd': [], 'lfhf': [], 'hr': []
            }

            for t_start_sec in range(0, int(total_duration_sec - window_sec) + 1, step_sec):
                t_end_sec = t_start_sec + window_sec

                window_indices = [i for i, ts in enumerate(timestamps_ms) if (ts / 1000 >= t_start_sec) and (ts / 1000 < t_end_sec)]

                if len(window_indices) < 60:
                    continue

                rr_window = [rr_ms[i] for i in window_indices]

                try:
                    peaks_window = nk.intervals_to_peaks(rr_window)
                    hrv_window = nk.hrv(peaks_window, sampling_rate=1000)

                    results['time_min'].append((t_start_sec + t_end_sec) / 2 / 60)
                    results['rmssd'].append(hrv_window['HRV_RMSSD'].iloc[0])
                    results['lfhf'].append(hrv_window['HRV_LFHF'].iloc[0])
                    results['hr'].append(60000 / hrv_window['HRV_MeanNN'].iloc[0])
                except Exception as e:
                    print(f"Skipping window due to error: {e}")
                    continue

            return results

        dynamic_results = moving_window_analysis(rr_intervals_clean)
        # --- End of Port ---

        # Calculate overall static metrics as before
        peaks = nk.intervals_to_peaks(rr_intervals_clean)
        hrv_metrics_df = nk.hrv(peaks, sampling_rate=1000)

        response_data = {
            'metrics': hrv_metrics_df.to_dict(orient='records')[0],
            'cleaned_rr': rr_intervals_clean,
            'dynamic_metrics': dynamic_results
        }

        # Process ECG data if available
        if ecg_data:
            ecg_df = pd.read_csv(io.StringIO(ecg_data), comment='#', header=0, skipinitialspace=True)
            if 'MS' in ecg_df.columns and 'ECG' in ecg_df.columns:
                downsampled_ecg_df = ecg_df.iloc[::10, :]
                response_data['ecg'] = {
                    'time': ecg_df['MS'].tolist(),
                    'voltage': ecg_df['ECG'].tolist(),
                    'downsampled_time': downsampled_ecg_df['MS'].tolist(),
                    'downsampled_voltage': downsampled_ecg_df['ECG'].tolist()
                }

        return jsonify(response_data)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": "An internal server error occurred."}), 500


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
