function td_metrics = calculate_time_domain(rr_ms)
    % CALCULATE_TIME_DOMAIN Computes time-domain HRV metrics.
    %   td_metrics = CALCULATE_TIME_DOMAIN(rr_ms)
    %
    %   Input:
    %       rr_ms - Vector of RR intervals in milliseconds.
    %
    %   Output:
    %       td_metrics - Struct containing the following fields:
    %           .MeanNN - Mean of RR intervals (ms).
    %           .SDNN   - Standard deviation of RR intervals (ms).
    %           .RMSSD  - Root mean square of successive differences (ms).
    %           .pNN50  - Percentage of successive differences > 50 ms (%).

    if isempty(rr_ms) || length(rr_ms) < 2
        error('Input rr_ms must contain at least two values.');
    end

    % MeanNN: Mean of NN (RR) intervals
    td_metrics.MeanNN = mean(rr_ms);

    % SDNN: Standard deviation of all NN intervals
    td_metrics.SDNN = std(rr_ms);

    % Calculate successive differences
    rr_diff_ms = diff(rr_ms);

    % RMSSD: Root mean square of successive differences
    td_metrics.RMSSD = sqrt(mean(rr_diff_ms.^2));

    % pNN50: Percentage of successive differences greater than 50 ms
    nn50_count = sum(abs(rr_diff_ms) > 50);
    td_metrics.pNN50 = (nn50_count / length(rr_diff_ms)) * 100;
end
