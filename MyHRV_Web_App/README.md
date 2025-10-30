# MyHRV Web Application

This project is a full-stack web application that provides Heart Rate Variability (HRV) analysis. It is a migration of an original MATLAB-based tool to a more accessible web-based platform.

## Overview

The application allows users to upload a text file containing RR interval data. The backend, built with Python and Flask, processes this data using the NeuroKit2 library to calculate various HRV metrics. The frontend, a simple HTML page with JavaScript, then displays a detailed, human-readable interpretation of these metrics and visualizes the data with a Poincaré plot.

## Features

-   **Backend**: A Python API built with Flask.
    -   Uses the powerful `NeuroKit2` library for accurate, scientific-grade HRV analysis, including artifact correction.
    -   Parses `.txt` files containing RR interval data.
    -   Returns a comprehensive set of time-domain, frequency-domain, and non-linear HRV metrics in JSON format.
-   **Frontend**: A lightweight web interface.
    -   Built with plain HTML, CSS, and JavaScript.
    -   Allows users to upload their RR data file directly in the browser.
    -   Dynamically generates an interpretive report based on the analysis results.
    -   Visualizes the RR intervals using a Poincaré plot created with `Plotly.js`.

## Getting Started

### Prerequisites

-   Python 3.x
-   pip (Python package installer)

### Backend Setup

1.  **Navigate to the backend directory:**
    ```bash
    cd MyHRV_Web_App/backend
    ```

2.  **Install the required Python packages:**
    ```bash
    pip install -r requirements.txt
    ```

3.  **Run the Flask server:**
    ```bash
    python app.py
    ```
    The server will start on `http://127.0.0.1:5000`.

### Frontend Usage

1.  Ensure the backend server is running.

2.  Open a web browser and navigate to:
    [http://127.0.0.1:5000/](http://127.0.0.1:5000/)

3.  Click the "Choose File" button and select a `.txt` file containing your RR interval data. The file should be in the following format:
    ```
    # Optional comments preceded by #
    HR, RR, MS, SC
    0, 878, 878, 0
    77, 853, 1731, 1
    76, 836, 2567, 1
    ...
    ```
    The analysis requires the `RR` (RR interval in milliseconds) and `SC` (Skin Contact status) columns. Rows where `SC` is `0` will be filtered out.

4.  Once the file is selected, the analysis will run automatically. The HRV report and Poincaré plot will be displayed on the page.
