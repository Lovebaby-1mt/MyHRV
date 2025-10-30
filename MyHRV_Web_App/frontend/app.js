document.addEventListener('DOMContentLoaded', () => {
    const hrUpload = document.getElementById('hr-upload');
    const ecgUpload = document.getElementById('ecg-upload');
    const analyzeButton = document.getElementById('analyze-button');

    let hrFile = null;
    let ecgFile = null;

    hrUpload.addEventListener('change', (e) => {
        hrFile = e.target.files[0];
        validateFiles();
    });

    ecgUpload.addEventListener('change', (e) => {
        ecgFile = e.target.files[0];
        validateFiles();
    });

    function validateFiles() {
        analyzeButton.disabled = !hrFile;
    }

    analyzeButton.addEventListener('click', handleAnalysis);

    async function handleAnalysis() {
        const reportContainer = document.getElementById('report-container');

        if (!hrFile) {
            reportContainer.innerHTML = '<p class="error">Please select an HR file.</p>';
            return;
        }

        reportContainer.innerHTML = '<p>Processing your file...</p>';

        try {
            const hrText = await readFileAsText(hrFile);
            const ecgText = ecgFile ? await readFileAsText(ecgFile) : null;

            const response = await fetch('/analyze_hrv', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ hr_data: hrText, ecg_data: ecgText })
            });

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`Backend error: ${response.status} ${response.statusText}. ${errorText}`);
            }

            const data = await response.json();

            if (data.error) {
                throw new Error(`Analysis error: ${data.error}`);
            }

            generateReport(data.metrics);
            plotPoincare(data.cleaned_rr);
            if (data.ecg) {
                plotECG(data.ecg);
            }


        } catch (error) {
            console.error("An error occurred:", error);
            reportContainer.innerHTML = `<p class="error">An error occurred: ${error.message}</p>`;
        }
    }

    function readFileAsText(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result);
            reader.onerror = () => reject(reader.error);
            reader.readAsText(file);
        });
    }

    function generateReport(metrics) {
        const reportContainer = document.getElementById('report-container');
        let reportHTML = '<h2>HRV Status Report</h2>';

        reportHTML += '<h3>Time-Domain Metrics</h3>';
        const meanHR = 60000 / metrics.HRV_MeanNN;
        reportHTML += `<p>Mean NN (RR): ${metrics.HRV_MeanNN.toFixed(2)} ms (Average Heart Rate: ${meanHR.toFixed(0)} BPM)</p>`;
        if (meanHR > 100) {
            reportHTML += '<p>Status: High heart rate (possible stress, post-exercise, or tachycardia).</p>';
        } else if (meanHR > 80) {
            reportHTML += '<p>Status: Awake, alert, or mild stress state.</p>';
        } else if (meanHR > 60) {
            reportHTML += '<p>Status: Calm, relaxed resting state.</p>';
        } else {
            reportHTML += '<p>Status: Deep relaxation or sleep state.</p>';
        }

        reportHTML += `<p>RMSSD: ${metrics.HRV_RMSSD.toFixed(2)} ms</p>`;
        if (metrics.HRV_RMSSD > 50) {
            reportHTML += '<p>Status: Very active parasympathetic nervous system (good recovery or high endurance).</p>';
        } else if (metrics.HRV_RMSSD > 20) {
            reportHTML += '<p>Status: Parasympathetic activity in a healthy, normal range.</p>';
        } else {
            reportHTML += '<p>Status: Low parasympathetic activity (possible stress, fatigue, or insufficient recovery).</p>';
        }

        reportHTML += '<h3>Frequency-Domain Metrics</h3>';
        reportHTML += `<p>LF/HF Ratio: ${metrics.HRV_LFHF.toFixed(2)}</p>`;
        if (metrics.HRV_LFHF > 2.0) {
            reportHTML += '<p>Status: Sympathetic (stress system) dominance (stress, anxiety, focus).</p>';
        } else if (metrics.HRV_LFHF > 1.0) {
            reportHTML += '<p>Status: Relative balance, slight sympathetic dominance (awake, alert).</p>';
        } else {
            reportHTML += '<p>Status: Parasympathetic (rest system) dominance (relaxation, recovery, drowsiness).</p>';
        }

        reportHTML += '<h3>Non-Linear Metrics (Poincaré)</h3>';
        reportHTML += `<p>SD1: ${metrics.HRV_SD1.toFixed(2)} ms (Short-term variability, parasympathetic assessment)</p>`;
        reportHTML += `<p>SD2: ${metrics.HRV_SD2.toFixed(2)} ms (Long-term variability, overall assessment)</p>`;

        reportContainer.innerHTML = reportHTML;
    }

    function plotPoincare(rr_intervals) {
        const trace = {
            x: rr_intervals.slice(0, -1),
            y: rr_intervals.slice(1),
            mode: 'markers',
            type: 'scatter'
        };
        const layout = {
            title: 'Poincaré Plot',
            xaxis: { title: 'RR(i) (ms)' },
            yaxis: { title: 'RR(i+1) (ms)' }
        };
        Plotly.newPlot('poincare-plot', [trace], layout);
    }

    function plotECG(ecg) {
        const fullTrace = {
            x: ecg.time,
            y: ecg.voltage,
            mode: 'lines',
            type: 'scatter',
            name: 'Full ECG'
        };

        const sliderTrace = {
            x: ecg.time,
            y: ecg.voltage,
            mode: 'lines',
            type: 'scatter',
            name: 'ECG Segment'
        };

        const fullLayout = {
            title: 'ECG Signal Overview'
        };

        const sliderLayout = {
            title: 'ECG Signal Segment (Slide to Zoom)',
            xaxis: {
                rangeslider: {
                    visible: true
                }
            }
        };

        Plotly.newPlot('ecg-plot-full', [fullTrace], fullLayout);
        Plotly.newPlot('ecg-plot-slider', [sliderTrace], sliderLayout);
    }
});
