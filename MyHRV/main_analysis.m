% ============== main_analysis.m (V8.4 - 渲染修复版) ==============
% 描述: 修正了 V8.3 中 input() 阻塞绘图渲染的问题
%      - 在 input() 之前加入了 drawnow
% =============================================================

clear; clc; close all;

% 1. 添加子文件夹到路径 (保持不变)
addpath('preprocessing');
addpath('visualization');
addpath('core_functions');
addpath('reporting');

% 2. 定义文件路径 (保持不变)
rr_file_path = 'HR_2025.10.27_19.30.36.txt';
ecg_file_path = 'ECG_2025.10.27_19.30.36.txt';

% 3. 加载数据 (保持不变)
try
    rr_data_raw = load_rr_data(rr_file_path);
    ecg_data = load_ecg_data(ecg_file_path);
catch ME
    disp('!!! 数据加载失败 !!!');
    rethrow(ME);
end

% 4. 预处理 - 伪影修正 (保持不变)
disp('正在修正 RR 数据中的伪影...');
rr_data_clean = clean_rr_artifacts(rr_data_raw);


% 5. 动态时变分析 (Moving Window Analysis)
fprintf('\n正在执行 (5分钟窗口, 1分钟步长) 的动态时变分析...\n');

% (5.1 ~ 5.4 保持不变)
window_size_sec = 300; 
step_size_sec = 60;    
t_ms = rr_data_clean.timestamps_ms; 
t_sec = t_ms / 1000;
rr_ms_clean = rr_data_clean.rr_ms_clean;
total_duration_sec = rr_data_raw.metadata.duration_s;
n_windows = floor((total_duration_sec - window_size_sec) / step_size_sec) + 1;
if n_windows < 1
    n_windows = 1; 
end
results.time_min = zeros(n_windows, 1);
results.rmssd = zeros(n_windows, 1);
results.lfhf = zeros(n_windows, 1);
results.hr = zeros(n_windows, 1);
result_idx = 1; 

for t_start_sec = 0 : step_size_sec : (total_duration_sec - window_size_sec)
    t_end_sec = t_start_sec + window_size_sec;
    if isempty(t_sec)
        break; 
    end
    idx_window = find(t_sec >= t_start_sec & t_sec < t_end_sec);
    if length(idx_window) < 60
        fprintf('   跳过时间窗口 %.1f - %.1f min (数据点不足)。\n', t_start_sec/60, t_end_sec/60);
        continue;
    end
    t_window_ms = t_ms(idx_window);           
    rr_window_clean = rr_ms_clean(idx_window); 
    t_window_sec_norm = (t_window_ms - t_window_ms(1)) / 1000;
    rr_window_detrended = detrend_window(t_window_sec_norm, rr_window_clean);
    td_metrics = calculate_time_domain(rr_window_detrended);
    t_window_ms_norm = t_window_ms - t_window_ms(1); 
    fd_metrics = calculate_freq_domain(rr_window_clean, t_window_ms_norm);
    results.time_min(result_idx) = (t_start_sec + t_end_sec) / 2 / 60; 
    results.rmssd(result_idx) = td_metrics.RMSSD;
    results.lfhf(result_idx) = fd_metrics.LF_HF_Ratio;
    results.hr(result_idx) = 60000 / td_metrics.MeanNN;
    result_idx = result_idx + 1;
end

% 5.5 清理未使用的预分配空间 (保持不变)
results.time_min = results.time_min(1:result_idx-1);
results.rmssd = results.rmssd(1:result_idx-1);
results.lfhf = results.lfhf(1:result_idx-1);
results.hr = results.hr(1:result_idx-1);

fprintf('动态分析完成，共计算了 %d 个数据窗口。\n', result_idx-1);

% 6. (V8.6 修正) 绘制图表 + 生成动态总结报告
if (result_idx-1) > 0
    % 6.1 (保留) 绘制“细节图” (3个子图)
    plot_dynamic_hrv(results); 
    
    % 6.2 (保留) 绘制“组会总结图” (2D 状态空间)
    plot_state_space(results); 

    fprintf('   (提示) 动态曲线图 和 状态空间图 已生成。\n');
    
    % 6.3 (V8.6 新增) 生成最终的“动态分析总结”文本报告
    fprintf('\n正在生成动态分析总结...\n');
    generate_dynamic_report(rr_data_raw.metadata, results); % <-- (V8.6 新增)
    
    % (V8.4 关键修正)
    drawnow; 
    
else
    fprintf('   (警告) 没有计算出任何有效的数据窗口，无法生成动态图表。\n');
end

% 7. (可选) 动态回放完整的 ECG 信号 (保持不变)
choice = input('\n是否要动态回放完整的 ECG 信号? (y/n) [n]: ', 's');
if isempty(choice)
    choice = 'n'; % 默认不播放
end
if strcmpi(choice, 'y')
    disp('正在启动 ECG 动态回放...');
    plot_scrolling_ecg(ecg_data, 10); 
    disp('动态回放完成。');
else
    disp('跳过 ECG 动态回放。');
end

fprintf('分析流程结束。\n');