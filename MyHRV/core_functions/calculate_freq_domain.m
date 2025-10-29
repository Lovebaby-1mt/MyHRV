function fd_metrics = calculate_freq_domain(rr_ms, timestamps_ms)
    % CALCULATE_FREQ_DOMAIN Computes frequency-domain HRV metrics.
    %   fd_metrics = CALCULATE_FREQ_DOMAIN(rr_ms, timestamps_ms)
    %
    %   Input:
    %       rr_ms         - Vector of RR intervals in milliseconds.
    %       timestamps_ms - Vector of timestamps for each RR interval in ms.
    %
    %   Output:
    %       fd_metrics - Struct containing the following fields:
    %           .VLF_Power    - Power in the VLF band (0.003-0.04 Hz).
    %           .LF_Power     - Power in the LF band (0.04-0.15 Hz).
    %           .HF_Power     - Power in the HF band (0.15-0.4 Hz).
    %           .LF_HF_Ratio  - Ratio of LF to HF power.

    if isempty(rr_ms) || length(rr_ms) < 2
        error('Input rr_ms must contain at least two values.');
    end

    % Convert timestamps from ms to seconds for plomb
    timestamps_s = timestamps_ms / 1000;

    % Use Lomb-Scargle periodogram to handle uneven sampling
    [pxx, f] = plomb(rr_ms - mean(rr_ms), timestamps_s);

    % Define frequency bands
    vlf_band = [0.003 0.04];
    lf_band = [0.04 0.15];
    hf_band = [0.15 0.4];

    % Helper function to integrate power in a given band
    function power = integrate_power(f, pxx, band)
        idx = f >= band(1) & f <= band(2);
        power = trapz(f(idx), pxx(idx));
    end

    % Calculate power in each band
    fd_metrics.VLF_Power = integrate_power(f, pxx, vlf_band);
    fd_metrics.LF_Power = integrate_power(f, pxx, lf_band);
    fd_metrics.HF_Power = integrate_power(f, pxx, hf_band);

    % Calculate LF/HF ratio
    if fd_metrics.HF_Power > 0
        fd_metrics.LF_HF_Ratio = fd_metrics.LF_Power / fd_metrics.HF_Power;
    else
        fd_metrics.LF_HF_Ratio = NaN; % Avoid division by zero
    end
end
