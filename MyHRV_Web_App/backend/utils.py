
import numpy as np

def clean_rr_artifacts_py(rr_raw, half_window=5, threshold=0.20):
    """
    Cleans artifacts from RR interval data using a moving window median filter.
    Ported from the MATLAB implementation.
    """
    rr_clean = list(rr_raw)  # Work on a copy
    num_corrected = 0
    for i in range(half_window, len(rr_raw) - half_window):
        window_indices = list(range(i - half_window, i)) + list(range(i + 1, i + half_window + 1))
        window = [rr_raw[j] for j in window_indices]

        # Correct median calculation for lists
        median_val = np.median(window)

        if abs(rr_raw[i] - median_val) > (median_val * threshold):
            rr_clean[i] = median_val
            num_corrected += 1

    print(f"Artifact correction complete. Corrected {num_corrected} points.")
    return rr_clean
