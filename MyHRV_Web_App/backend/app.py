from flask import Flask, request, jsonify, send_from_directory
import pandas as pd
import neurokit2 as nk
import io
import os

# The static folder is relative to the execution path of this script.
# Since app.py is in 'backend', the frontend is one level up and then into 'frontend'.
app = Flask(__name__, static_folder='../frontend')

@app.route('/')
def serve_index():
    return send_from_directory(app.static_folder, 'index.html')

# This route is necessary to serve any other static files like CSS or JS if they were separate.
@app.route('/<path:path>')
def serve_static(path):
    # Security note: In a production app, ensure 'path' is sanitized.
    # For this simple app, it's okay.
    return send_from_directory(app.static_folder, path)

@app.route('/analyze_hrv', methods=['POST'])
def analyze_hrv():
    data = request.data.decode('utf-8')

    # Use io.StringIO to treat the string data as a file
    # We explicitly name columns because the file might not have a header row after comments
    df = pd.read_csv(io.StringIO(data), comment='#', header=0)

    # Filter for SC == 1 (Skin Contact is true) and get the RR intervals
    if 'SC' in df.columns and 'RR' in df.columns:
        rr_intervals = df[df['SC'] == 1]['RR'].dropna().tolist()
    else:
        # Fallback if columns are not named as expected
        # This is a simple fallback, a real app should handle this more gracefully
        # Assuming the second column is RR if no headers are found.
        if df.shape[1] >= 2:
            rr_intervals = df.iloc[:, 1].dropna().tolist()
        else:
            return jsonify({"error": "Invalid data format"}), 400

    if not rr_intervals:
        return jsonify({"error": "No valid RR intervals found"}), 400

    # Convert RR intervals to peak locations
    peaks = nk.intervals_to_peaks(rr_intervals)

    # Calculate HRV metrics using the peaks
    hrv_metrics_df = nk.hrv(peaks, sampling_rate=1000)

    # For the Poincare plot, we'll just use the filtered list for now.
    cleaned_rr = rr_intervals

    # Prepare the response
    response_data = {
        'metrics': hrv_metrics_df.to_dict(orient='records')[0],
        'cleaned_rr': cleaned_rr
    }

    return jsonify(response_data)

if __name__ == '__main__':
    try:
        # Running from 'backend' dir, so host needs to be 0.0.0.0 to be accessible from browser
        # Port is 5000 by default.
        app.run(debug=True, host='0.0.0.0')
    except Exception as e:
        print(f"Failed to start server: {e}")
