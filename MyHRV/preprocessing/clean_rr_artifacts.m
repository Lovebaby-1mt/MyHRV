function rr_data_out = clean_rr_artifacts(rr_data_in)
    % CLEAN_RR_ARTIFACTS Cleans artifacts from RR interval data.
    %   rr_data_out = CLEAN_RR_ARTIFACTS(rr_data_in) uses a moving window
    %   median filter to identify and correct artifacts in the RR interval series.
    %
    %   Input:
    %       rr_data_in - A struct containing the raw RR data in the field '.rr_ms'.
    %
    %   Output:
    %       rr_data_out - The input struct with an added field '.rr_ms_clean'
    %                     containing the artifact-corrected RR series.
    %
    %   Algorithm:
    %   For each RR interval, it is compared to the median of the 5 preceding
    %   and 5 succeeding intervals. If the interval deviates from this median
    %   by more than 20%, it is considered an artifact and is replaced by
    %   the calculated median value.

    % --- Parameters ---
    half_window = 5;   % Number of points before and after the current point
    threshold = 0.20;  % 20% deviation threshold

    % --- Implementation ---
    rr_raw = rr_data_in.rr_ms;
    rr_clean = rr_raw; % Initialize the clean array with the raw data
    num_corrected = 0; % Counter for corrected artifacts

    % Iterate through the data, avoiding the edges where a full window is not available
    for i = (half_window + 1):(length(rr_raw) - half_window)
        % Define the window of surrounding points (5 before, 5 after)
        window_indices = [(i - half_window):(i - 1), (i + 1):(i + half_window)];
        window = rr_raw(window_indices);

        % Calculate the median of the surrounding points
        median_val = median(window);

        % Check if the current point deviates from the median by the threshold
        if abs(rr_raw(i) - median_val) > (median_val * threshold)
            % If it's an artifact, replace it with the median value
            rr_clean(i) = median_val;
            num_corrected = num_corrected + 1;
        end
    end

    % Add the cleaned data as a new field to the output struct
    rr_data_out = rr_data_in;
    rr_data_out.rr_ms_clean = rr_clean;

    fprintf('  伪影修正完成。检测并修正了 %d 个点。\n', num_corrected);
end
