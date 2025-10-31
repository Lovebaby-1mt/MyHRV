% /visualization/plot_dynamic_hrv.m
% 描述: 绘制 HRV 指标随时间变化的动态曲线图
%      - 这是我们“动态时变分析”的最终输出

function plot_dynamic_hrv(results)
    %   Input:
    %       results: 包含 .time_min, .rmssd, .lfhf, .hr 的结构体

    % 创建新图窗
    figure('Name', 'HRV 动态时变分析 (5分钟滑动窗口)');
    
    % 1. 子图1: 恢复系统 (RMSSD)
    subplot(3, 1, 1);
    plot(results.time_min, results.rmssd, 'b-o', 'LineWidth', 1, 'MarkerFaceColor', 'b');
    title('“恢复系统”活跃度 (RMSSD)');
    ylabel('RMSSD (ms)');
    grid on;
    axis tight;

    % 2. 子图2: 核心平衡 (LF/HF Ratio)
    subplot(3, 1, 2);
    plot(results.time_min, results.lfhf, 'r-s', 'LineWidth', 1, 'MarkerFaceColor', 'r');
    title('“应激/恢复”平衡 (LF/HF Ratio)');
    ylabel('LF/HF Ratio');
    grid on;
    axis tight;
    
    % 3. 子图3: 平均心率 (HR)
    subplot(3, 1, 3);
    plot(results.time_min, results.hr, 'k-d', 'LineWidth', 1, 'MarkerFaceColor', 'k');
    title('平均心率 (HR)');
    ylabel('心率 (BPM)');
    xlabel('时间 (分钟)'); % X轴标签只在最下方显示
    grid on;
    axis tight;
    
    fprintf('已生成 HRV 动态时变分析图。\n');
end