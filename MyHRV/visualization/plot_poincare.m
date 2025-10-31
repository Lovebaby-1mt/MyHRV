function nl_metrics = plot_poincare(rr_ms)
    % PLOT_POINCARE Creates a Poincaré plot and calculates non-linear HRV metrics.
    %   nl_metrics = PLOT_POINCARE(rr_ms)
    %
    %   Input:
    %       rr_ms - Vector of RR intervals in milliseconds.
    %
    %   Output:
    %       nl_metrics - Struct containing the following fields:
    %           .SD1 - Standard deviation of the short-term variability (ms).
    %           .SD2 - Standard deviation of the long-term variability (ms).
    %
    %   Also creates a Poincaré plot figure.

    if isempty(rr_ms) || length(rr_ms) < 2
        error('Input rr_ms must contain at least two values.');
    end

    % Prepare data for Poincaré plot (RRn vs RRn+1)
    rr_n = rr_ms(1:end-1);
    rr_n_plus_1 = rr_ms(2:end);

    % Calculate SD1 and SD2
    % SD1: Reflects short-term variability
    nl_metrics.SD1 = std(rr_n - rr_n_plus_1) / sqrt(2);
    % SD2: Reflects long-term variability
    nl_metrics.SD2 = std(rr_n + rr_n_plus_1) / sqrt(2);

    % Create the Poincaré plot
    figure('Name', 'Poincaré Plot');
    plot(rr_n, rr_n_plus_1, '.');
    xlabel('RR_n (ms)');
    ylabel('RR_{n+1} (ms)');
    title('Poincaré Plot of RR Intervals');
    axis equal;
    grid on;

    % Add SD1/SD2 ellipse for visualization
    hold on;
    mean_rr = mean(rr_ms);
    ellipse_angle = pi/4;
    t = linspace(0, 2*pi, 100);
    x_ellipse = mean_rr + nl_metrics.SD2 * cos(t) * cos(ellipse_angle) - nl_metrics.SD1 * sin(t) * sin(ellipse_angle);
    y_ellipse = mean_rr + nl_metrics.SD2 * cos(t) * sin(ellipse_angle) + nl_metrics.SD1 * sin(t) * cos(ellipse_angle);
    plot(x_ellipse, y_ellipse, 'r-', 'LineWidth', 2);
    legend('RR Intervals', 'SD1/SD2 Ellipse');
    hold off;
end
