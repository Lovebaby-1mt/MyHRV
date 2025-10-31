import pandas as pd
import neurokit2 as nk
import plotly.graph_objects as go
import sys
import os
from utils import clean_rr_artifacts_py

def generate_report_html(metrics):
    report_html = '<h2>HRV Status Report</h2>'

    # Time-Domain
    report_html += '<h3>Time-Domain Metrics</h3>'
    mean_hr = 60000 / metrics['HRV_MeanNN']
    report_html += f"<p>Mean NN (RR): {metrics['HRV_MeanNN']:.2f} ms (Average Heart Rate: {mean_hr:.0f} BPM)</p>"
    if mean_hr > 100:
        report_html += '<p>Status: High heart rate (possible stress, post-exercise, or tachycardia).</p>'
    elif mean_hr > 80:
        report_html += '<p>Status: Awake, alert, or mild stress state.</p>'
    elif mean_hr > 60:
        report_html += '<p>Status: Calm, relaxed resting state.</p>'
    else:
        report_html += '<p>Status: Deep relaxation or sleep state.</p>'

    report_html += f"<p>RMSSD: {metrics['HRV_RMSSD']:.2f} ms</p>"
    if metrics['HRV_RMSSD'] > 50:
        report_html += '<p>Status: Very active parasympathetic nervous system (good recovery or high endurance).</p>'
    elif metrics['HRV_RMSSD'] > 20:
        report_html += '<p>Status: Parasympathetic activity in a healthy, normal range.</p>'
    else:
        report_html += '<p>Status: Low parasympathetic activity (possible stress, fatigue, or insufficient recovery).</p>'

    # Frequency-Domain
    report_html += '<h3>Frequency-Domain Metrics</h3>'
    report_html += f"<p>LF/HF Ratio: {metrics['HRV_LFHF']:.2f}</p>"
    if metrics['HRV_LFHF'] > 2.0:
        report_html += '<p>Status: Sympathetic (stress system) dominance (stress, anxiety, focus).</p>'
    elif metrics['HRV_LFHF'] > 1.0:
        report_html += '<p>Status: Relative balance, slight sympathetic dominance (awake, alert).</p>'
    else:
        report_html += '<p>Status: Parasympathetic (rest system) dominance (relaxation, recovery, drowsiness).</p>'

    # Non-Linear
    report_html += '<h3>Non-Linear Metrics (Poincaré)</h3>'
    report_html += f"<p>SD1: {metrics['HRV_SD1']:.2f} ms (Short-term variability, parasympathetic assessment)</p>"
    report_html += f"<p>SD2: {metrics['HRV_SD2']:.2f} ms (Long-term variability, overall assessment)</p>"

    return report_html

def main(hr_file, ecg_file=None):
    # Process HR data
    hr_df = pd.read_csv(hr_file, comment='#', header=0, skipinitialspace=True)
    rr_intervals = hr_df[hr_df['SC'] == 1]['RR'].dropna().tolist()

    rr_intervals_clean = clean_rr_artifacts_py(rr_intervals)

    peaks = nk.intervals_to_peaks(rr_intervals_clean)
    hrv_metrics_df = nk.hrv(peaks, sampling_rate=1000)
    metrics = hrv_metrics_df.to_dict(orient='records')[0]

    # Create plots
    poincare_fig = go.Figure(data=go.Scatter(x=rr_intervals_clean[:-1], y=rr_intervals_clean[1:], mode='markers'))
    poincare_fig.update_layout(title='Poincaré Plot', xaxis_title='RR(i) (ms)', yaxis_title='RR(i+1) (ms)')
    poincare_html = poincare_fig.to_html(full_html=False, include_plotlyjs='cdn')

    ecg_full_html = ""
    ecg_slider_html = ""
    if ecg_file:
        ecg_df = pd.read_csv(ecg_file, comment='#', header=0, skipinitialspace=True)
        downsampled_ecg_df = ecg_df.iloc[::10, :]

        ecg_full_fig = go.Figure(data=go.Scatter(x=downsampled_ecg_df['MS'], y=downsampled_ecg_df['ECG'], mode='lines'))
        ecg_full_fig.update_layout(title='ECG Signal Overview')
        ecg_full_html = ecg_full_fig.to_html(full_html=False, include_plotlyjs=False)

        ecg_slider_fig = go.Figure(data=go.Scatter(x=ecg_df['MS'], y=ecg_df['ECG'], mode='lines'))
        ecg_slider_fig.update_layout(title='ECG Signal Segment (Slide to Zoom)', xaxis_rangeslider_visible=True)
        ecg_slider_html = ecg_slider_fig.to_html(full_html=False, include_plotlyjs=False)

    report_text_html = generate_report_html(metrics)

    # Get the directory of the script
    script_dir = os.path.dirname(os.path.realpath(__file__))
    template_path = os.path.join(script_dir, 'report_template.html')


    with open(template_path, 'r') as f:
        template = f.read()

    final_html = template.format(
        report_text=report_text_html,
        poincare_plot=poincare_html,
        ecg_overview_plot=ecg_full_html,
        ecg_slider_plot=ecg_slider_html
    )

    output_path = os.path.join(script_dir, '..', 'HRV_Report.html')


    with open(output_path, 'w') as f:
        f.write(.final_html)

if __name__ == '__main__':
    hr_file_path = sys.argv[1]
    ecg_file_path = sys.argv[2] if len(sys.argv) > 2 else None
    main(hr_file_path, ecg_file_path)
