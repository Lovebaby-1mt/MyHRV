from flask import Flask, request, jsonify, send_from_directory
import pandas as pd
import neurokit2 as nk
import io
import os

app = Flask(__name__, static_folder=os.path.abspath('MyHRV_Web_App/frontend'))

@app.route('/')
def serve_index():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    return send_from_directory(app.static_folder, path)

@app.route('/analyze_hrv', methods=['POST'])
def analyze_hrv():
    data = request.data.decode('utf-8')

    # Use io.StringIO to treat the string data as a file
    df = pd.read_csv(io.StringIO(data), comment='#', header=0)

    # Filter for SC == 1 and get the RR intervals
    rr_intervals = df[df['SC'] == 1]['RR'].tolist()

    # Clean the RR intervals
    cleaned_rr = nk.hrv_clean(rr_intervals, sampling_rate=1000)

    # Calculate HRV metrics using NeuroKit2 on the cleaned RR intervals
    hrv_metrics_df = nk.hrv(cleaned_rr, sampling_rate=1000)

    # Prepare the response
    response_data = {
        'metrics': hrv_metrics_df.to_dict(orient='records')[0],
        'cleaned_rr': cleaned_rr.tolist()
    }

    return jsonify(response_data)

if __name__ == '__main__':
    app.run(debug=True)
