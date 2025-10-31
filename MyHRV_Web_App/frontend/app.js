document.addEventListener('DOMContentLoaded', () => {
    const hrUpload = document.getElementById('hr-upload');
    const ecgUpload = document.getElementById('ecg-upload');
    const analyzeButton = document.getElementById('analyze-button');
    const loader = document.getElementById('loader');

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

        gsap.set(".loader-dot", { y: 0, opacity: 1 });
        loader.style.display = 'flex';
        gsap.to(".loader-dot", {
            y: -20,
            stagger: {
                each: 0.1,
                repeat: -1,
                yoyo: true
            },
            ease: "power1.inOut"
        });
        analyzeButton.disabled = true;
        reportContainer.innerHTML = '<p>Processing your file...</p>';

        // Clear previous plots
        Plotly.purge('poincare-plot');
        Plotly.purge('ecg-plot-full');
        Plotly.purge('ecg-plot-slider');
        Plotly.purge('dynamic-hrv-plot');
        Plotly.purge('state-space-plot');


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

            if (data.dynamic_metrics && data.dynamic_metrics.time_min.length > 0) {
                plotDynamicHRV(data.dynamic_metrics);
                plotStateSpace(data.dynamic_metrics);
            }

            plotPoincare(data.cleaned_rr);
            if (data.ecg) {
                plotECG(data.ecg);
            }


        } catch (error) {
            console.error("An error occurred:", error);
            reportContainer.innerHTML = `<p class="error">An error occurred: ${error.message}</p>`;
        } finally {
            gsap.to(loader, {
                duration: 0.5,
                opacity: 0,
                onComplete: () => {
                    loader.style.display = 'none';
                    gsap.set(loader, { opacity: 1 }); // Reset for next time
                }
            });
            analyzeButton.disabled = !hrFile;
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

        reportHTML += '<div class="report-section"><h3>Time-Domain Metrics</h3>';
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
        reportHTML += '</div>';

        reportHTML += '<div class="report-section">';
        reportHTML += `<p>RMSSD: ${metrics.HRV_RMSSD.toFixed(2)} ms</p>`;
        if (metrics.HRV_RMSSD > 50) {
            reportHTML += '<p>Status: Very active parasympathetic nervous system (good recovery or high endurance).</p>';
        } else if (metrics.HRV_RMSSD > 20) {
            reportHTML += '<p>Status: Parasympathetic activity in a healthy, normal range.</p>';
        } else {
            reportHTML += '<p>Status: Low parasympathetic activity (possible stress, fatigue, or insufficient recovery).</p>';
        }
        reportHTML += '</div>';

        reportHTML += '<div class="report-section"><h3>Frequency-Domain Metrics</h3>';
        reportHTML += `<p>LF/HF Ratio: ${metrics.HRV_LFHF.toFixed(2)}</p>`;
        if (metrics.HRV_LFHF > 2.0) {
            reportHTML += '<p>Status: Sympathetic (stress system) dominance (stress, anxiety, focus).</p>';
        } else if (metrics.HRV_LFHF > 1.0) {
            reportHTML += '<p>Status: Relative balance, slight sympathetic dominance (awake, alert).</p>';
        } else {
            reportHTML += '<p>Status: Parasympathetic (rest system) dominance (relaxation, recovery, drowsiness).</p>';
        }
        reportHTML += '</div>';

        reportHTML += '<div class="report-section"><h3>Non-Linear Metrics (Poincaré)</h3>';
        reportHTML += `<p>SD1: ${metrics.HRV_SD1.toFixed(2)} ms (Short-term variability, parasympathetic assessment)</p>`;
        reportHTML += `<p>SD2: ${metrics.HRV_SD2.toFixed(2)} ms (Long-term variability, overall assessment)</p>`;
        reportHTML += '</div>';

        reportContainer.innerHTML = reportHTML;

        gsap.from(".report-section", {
            duration: 0.5,
            y: 20,
            opacity: 0,
            stagger: 0.2,
            ease: "power1.out"
        });
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
        gsap.from("#poincare-plot", { duration: 0.5, opacity: 0, delay: 0.5 });
    }

    function plotECG(ecg) {
        const fullTrace = {
            x: ecg.downsampled_time,
            y: ecg.downsampled_voltage,
            mode: 'lines',
            type: 'scatter',
            name: 'Full ECG'
        };

        const sliderTrace = {
            x: ecg.time,
            y: ecg.voltage,
            mode: 'lines',
            type: 'scatter',
            name: 'ECG Segment',
            line: {
                color: '#2ecc71',
                width: 2
            }
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
        gsap.from("#ecg-plot-full", { duration: 0.5, opacity: 0, delay: 0.7 });

        Plotly.newPlot('ecg-plot-slider', [sliderTrace], sliderLayout).then(() => {
            const svg = document.querySelector('#ecg-plot-slider .main-svg');
            const path = svg.querySelector('.scatterlayer .trace path');
            if (path) {
                gsap.from(path, {
                    duration: 2,
                    drawSVG: 0,
                    ease: "power1.inOut"
                });
            }
        });
        gsap.from("#ecg-plot-slider", { duration: 0.5, opacity: 0, delay: 0.9 });
    }

    function plotDynamicHRV(metrics) {
        const trace1 = {
            x: metrics.time_min,
            y: metrics.hr,
            mode: 'lines+markers',
            name: 'Heart Rate (BPM)',
            yaxis: 'y1'
        };

        const trace2 = {
            x: metrics.time_min,
            y: metrics.rmssd,
            mode: 'lines+markers',
            name: 'RMSSD (ms)',
            yaxis: 'y2'
        };

        const trace3 = {
            x: metrics.time_min,
            y: metrics.lfhf,
            mode: 'lines+markers',
            name: 'LF/HF Ratio',
            yaxis: 'y3'
        };

        const layout = {
            title: 'Dynamic Time-Variant HRV Metrics',
            xaxis: { title: 'Time (minutes)' },
            yaxis: { title: 'Heart Rate (BPM)', titlefont: { color: '#1f77b4' }, tickfont: { color: '#1f77b4' } },
            yaxis2: {
                title: 'RMSSD (ms)',
                titlefont: { color: '#ff7f0e' },
                tickfont: { color: '#ff7f0e' },
                overlaying: 'y',
                side: 'right'
            },
            yaxis3: {
                title: 'LF/HF Ratio',
                titlefont: { color: '#2ca02c' },
                tickfont: { color: '#2ca02c' },
                overlaying: 'y',
                side: 'right',
                position: 0.95
            },
            legend: { x: 1.1, y: 1 }
        };

        Plotly.newPlot('dynamic-hrv-plot', [trace1, trace2, trace3], layout);
        gsap.from("#dynamic-hrv-plot", { duration: 0.5, opacity: 0, delay: 0.6 });
    }

    function plotStateSpace(metrics) {
        const trace = {
            x: metrics.rmssd,
            y: metrics.lfhf,
            mode: 'markers+lines',
            type: 'scatter',
            marker: {
                color: metrics.time_min,
                colorscale: 'Viridis',
                showscale: true,
                colorbar: {
                    title: 'Time (min)'
                }
            }
        };

        const layout = {
            title: 'HRV State Space (RMSSD vs. LF/HF)',
            xaxis: { title: 'RMSSD (ms)' },
            yaxis: { title: 'LF/HF Ratio' },
            hovermode: 'closest'
        };

        Plotly.newPlot('state-space-plot', [trace], layout);
        gsap.from("#state-space-plot", { duration: 0.5, opacity: 0, delay: 0.8 });
    }
});
