% /visualization/plot_state_space.m
% [V8.5.1 改进版] 绘制 "生理状态空间" 图
%      - 聚焦于清晰的轨迹和关键信息，提高美观度和可读性
%      - 删除了混乱的箭头，改为平滑轨迹线
%      - 优化了颜色和标签位置

function plot_state_space(results)
    %   Input:
    %       results: 包含 .rmssd, .lfhf, .hr, .time_min 的结构体

    % 1. 提取数据
    rmssd = results.rmssd;
    lfhf = results.lfhf;
    hr = results.hr;
    t_min = results.time_min;
    
    % 检查数据是否为空
    if isempty(rmssd) || isempty(lfhf) || isempty(hr) || length(rmssd) < 2
        fprintf('   (警告) 状态空间图的数据不足或为空，跳过绘制。\n');
        return;
    end
    
    % 2. 创建新图窗
    figure('Name', 'HRV 生理状态空间轨迹 (时间演变)', 'Units', 'normalized', 'Position', [0.1 0.1 0.7 0.7]);
    ax = gca;
    hold(ax, 'on'); 
    
    % 3. (关键改进) 绘制带有时间颜色渐变的轨迹线
    %    我们将使用时间 (t_min) 来作为线条的颜色，表示时间进程
    %    或者，更直观地，用 HR 来做点的颜色，而线条颜色是固定或时间渐变
    %    我们这里选择用 HR 做点的颜色，线条用统一的灰色或时间渐变

    % 为了平滑轨迹，我们先对 RMSSD 和 LF/HF 进行简单的移动平均
    % (可选：如果数据点已经很平滑，可以跳过)
    window_smooth = 3; % 3个点 (3分钟) 的移动平均
    rmssd_smooth = movmean(rmssd, window_smooth);
    lfhf_smooth = movmean(lfhf, window_smooth);
    
    % 绘制轨迹点，颜色表示 HR，大小表示 RMSSD (可选)
    % 这里我们用颜色表示 HR
    scatter(rmssd_smooth, lfhf_smooth, 80, hr, 'filled', 'MarkerEdgeColor', [0.5 0.5 0.5], 'LineWidth', 0.5, 'DisplayName', '生理状态点 (颜色:HR)');
    
    % 绘制连接轨迹的线，用时间渐变色
    % 可以创建基于时间的颜色矩阵
    time_norm = (t_min - min(t_min)) / (max(t_min) - min(t_min)); % 归一化时间到 0-1
    cmap_time = colormap(ax, cool); % 使用 'cool' 色彩映射表示时间，从蓝色到粉色
    
    for i = 1:length(rmssd_smooth)-1
        idx_color = max(1, min(size(cmap_time, 1), round(time_norm(i) * size(cmap_time, 1))));
        plot(ax, rmssd_smooth(i:i+1), lfhf_smooth(i:i+1), '-', 'Color', cmap_time(idx_color, :), 'LineWidth', 1.5);
    end

    % 4. 添加颜色条 (Colorbar)，表示 HR
    cb = colorbar;
    ylabel(cb, '平均心率 (BPM)');
    colormap(ax, 'jet'); % HR 的颜色条使用 'jet'，与 scatter 对应
    
    % 5. 标记开始点和结束点
    plot(ax, rmssd_smooth(1), lfhf_smooth(1), 'o', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'DisplayName', '开始点');
    text(ax, rmssd_smooth(1), lfhf_smooth(1), sprintf('  开始 (%.1f min)', t_min(1)), 'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontWeight', 'bold');
    
    plot(ax, rmssd_smooth(end), lfhf_smooth(end), 's', 'MarkerSize', 12, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'DisplayName', '结束点');
    text(ax, rmssd_smooth(end), lfhf_smooth(end), sprintf('  结束 (%.1f min)', t_min(end)), 'VerticalAlignment', 'top', 'FontSize', 10, 'FontWeight', 'bold');

    % (可选) 标记关键事件点 (例如 HR 峰值或 RMSSD 谷值)
    [~, max_hr_idx] = max(hr);
    if max_hr_idx ~= 1 && max_hr_idx ~= length(hr)
        plot(ax, rmssd_smooth(max_hr_idx), lfhf_smooth(max_hr_idx), '^', 'MarkerSize', 12, 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'DisplayName', 'HR峰值');
        text(ax, rmssd_smooth(max_hr_idx), lfhf_smooth(max_hr_idx), sprintf('  HR峰值 (%.1f min)\n%.0f BPM', t_min(max_hr_idx), hr(max_hr_idx)), 'VerticalAlignment', 'top', 'FontSize', 9);
    end
    
    [~, min_rmssd_idx] = min(rmssd);
    if min_rmssd_idx ~= 1 && min_rmssd_idx ~= length(rmssd) && min_rmssd_idx ~= max_hr_idx % 避免重复标记
        plot(ax, rmssd_smooth(min_rmssd_idx), lfhf_smooth(min_rmssd_idx), 'v', 'MarkerSize', 12, 'MarkerFaceColor', 'c', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'DisplayName', 'RMSSD谷值');
        text(ax, rmssd_smooth(min_rmssd_idx), lfhf_smooth(min_rmssd_idx), sprintf('  RMSSD谷值 (%.1f min)\n%.1f ms', t_min(min_rmssd_idx), rmssd(min_rmssd_idx)), 'VerticalAlignment', 'bottom', 'FontSize', 9);
    end

    % 6. 设置坐标轴和标签
    xlabel('“恢复系统”活跃度 (RMSSD, ms)', 'FontSize', 12);
    ylabel('“应激/恢复”平衡 (LF/HF Ratio)', 'FontSize', 12);
    title('生理状态空间轨迹 (5分钟窗口) - HRV 动态演变', 'FontSize', 14, 'FontWeight', 'bold');
    
    grid on;
    % 调整轴范围，稍微超出数据范围，避免文字重叠
    x_margin = (max(rmssd) - min(rmssd)) * 0.1;
    y_margin = (max(lfhf) - min(lfhf)) * 0.1;
    xlim([min(rmssd)-x_margin, max(rmssd)+x_margin]);
    ylim([min(lfhf)-y_margin, max(lfhf)+y_margin]);
    
    % 7. (关键改进) 象限文本调整：移到图外侧或角落
    text(ax.XLim(1) + 0.05 * (ax.XLim(2) - ax.XLim(1)), ax.YLim(2) - 0.05 * (ax.YLim(2) - ax.YLim(1)), ...
         '高应激区 (低RMSSD, 高LF/HF)', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', ...
         'Color', 'red', 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.6]); % 半透明背景
    
    text(ax.XLim(2) - 0.05 * (ax.XLim(2) - ax.XLim(1)), ax.YLim(1) + 0.05 * (ax.YLim(2) - ax.YLim(1)), ...
         '高恢复区 (高RMSSD, 低LF/HF)', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', ...
         'Color', 'blue', 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.6]);
    
    hold(ax, 'off');
    
    % 8. 增加图例
    % legend(ax, 'Location', 'best'); % 自动放置图例
    
    fprintf('已生成改进后的“生理状态空间”图。\n');
end