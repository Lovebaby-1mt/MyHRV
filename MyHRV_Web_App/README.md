# MyHRV Web Application

This project is a full-stack web application that provides Heart Rate Variability (HRV) analysis. It is a migration of an original MATLAB-based tool to a more accessible web-based platform.

## Overview

This project provides two main functionalities:

1.  **Interactive Web Application**: A real-time analysis tool where you can upload HR and ECG files and see the results immediately in your browser.
2.  **Static Report Generator**: A command-line script that generates a standalone, portable HTML file containing a full HRV and ECG analysis report.

## 1. Interactive Web Application

### Features

-   **Backend**: A Python API built with Flask.
    -   Uses the powerful `NeuroKit2` library for accurate, scientific-grade HRV analysis.
    -   Parses `.txt` files for both HR and ECG data.
    -   Returns a comprehensive set of HRV metrics and ECG data in JSON format.
-   **Frontend**: A modern, two-column web interface.
    -   Left panel for uploading files and controlling the analysis.
    -   Right panel for displaying results, including a textual report and interactive plots.
    -   Visualizes ECG data with both a full overview and a zoomable, sliding window view.
    -   Features smooth animations and a loading indicator for a better user experience.

### Getting Started

#### Prerequisites

-   Python 3.x
-   pip (Python package installer)

#### Backend Setup

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
2.  Open a web browser and navigate to: [http://127.0.0.1:5000/](http://127.0.0.1:5000/)
3.  Use the dedicated buttons to upload your HR file and, optionally, your ECG file.
4.  Click the "Analyze" button to start the analysis. The results will appear on the right.

---

## 2. Static Report Generator

This tool is useful for creating permanent, shareable reports from your data without needing to run the web server.

### How to Use

1.  **Make sure you have installed the requirements** (see Backend Setup above).

2.  **Run the script from your terminal:**
    Navigate to the `MyHRV_Web_App/backend` directory and run the `generate_report.py` script, providing the path to your HR file and, optionally, your ECG file as command-line arguments.

    ```bash
    cd MyHRV_Web_App/backend
    python generate_report.py <path_to_hr_file.txt> [path_to_ecg_file.txt]
    ```

    **Example:**
    ```bash
    python generate_report.py ../../MyHRV/HR_2025.10.27_19.30.36.txt ../../MyHRV/ECG_2025.10.27_19.30.36.txt
    ```

3.  **View the Report:**
    A file named `HRV_Report.html` will be created inside the `MyHRV_Web_App` directory. You can open this file directly in any web browser to view the complete, static analysis report.
