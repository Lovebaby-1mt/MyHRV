% ============== main_analysis_STATIC.m ==============
% (V7.2 存档版本)
% 描述: 对“整个时程”进行“一次性”静态分析
%      - 加载数据 (V3, 带元数据)
%      - 清理伪影 (V7)
%      - 线性去趋势 (V7)
%      - 计算“静态平均”指标
%      - 调用“静态报告”函数 (V7.2)

clear; clc; close all;

% 1. 添加子文件夹到路径
addpath('preprocessing');
addpath('visualization');
addpath('core_functions');
addpath('reporting');

% 2. 定义文件路径
rr_file_path = 'HR_2025.10.27_19.30.36.txt';
ecg_file_path = 'ECG_2025.10.27_19.30.36.txt';

% 3. 加载数据 (使用 V3 带元数据)
try
    % (注意: 我们将原始数据保存在 _raw 中)
    rr_data_raw = load_rr_data(rr_file_path);
    ecg_data = load_ecg_data(ecg_file_path);
catch ME
    disp('!!! 数据加载失败 !!!');
    rethrow(ME);
end

% 4. 预处理 - 伪影修正
disp('正在修正 RR 数据中的伪影...');
% (我们将清理后的数据存入 _clean 结构体)
rr_data_clean = clean_rr_artifacts(rr_data_raw);
% (函数内部会自动打印修正了多少个点)


% 5. 数据导入“健全性检查” (10 秒图)
plot_duration_ms = 10000;
plot_duration_s = plot_duration_ms / 1000;
figure('Name', '数据导入检查 (前 10 秒)');
% 子图1: ECG
subplot(2, 1, 1);
ecg_indices = ecg_data.timestamps_ms <= plot_duration_ms;
plot(ecg_data.timestamps_ms(ecg_indices) / 1000, ecg_data.voltage_mv(ecg_indices));
title(sprintf('ECG 信号 (前 %.0f 秒)', plot_duration_s));
xlabel('时间 (秒)');
ylabel('电压 (mV)');
grid on;
axis tight;
% 子图2: RR 间期 (使用清理后的数据)
subplot(2, 1, 2);
rr_indices = rr_data_clean.timestamps_ms <= plot_duration_ms;
plot(rr_data_clean.timestamps_ms(rr_indices) / 1000, rr_data_clean.rr_ms_clean(rr_indices), 'o-');
title(sprintf('RR 间期序列图 (前 %.0f 秒)', plot_duration_s));
xlabel('时间 (秒)');
ylabel('RR 间期 (ms)');
grid on;
axis tight;
disp('数据加载和初步可视化完成。');

% 6. (V7 核心) 对“整个” RR 序列进行去趋势处理
disp('正在对 RR 序列进行去趋势处理...');
% (我们将去趋势后的数据存入 _detrended 结构体)
rr_data_detrended = detrend_rr_sequence(rr_data_clean);
disp('去趋势处理完成。');


% 7. (V7 核心) 计算 HRV 指标 (一次性)
disp('正在计算 HRV 指标...');
% (学术重点)
% 时域 (SDNN) 和 非线性 (SD2) 必须在“去趋势”后的数据上计算
td_metrics = calculate_time_domain(rr_data_detrended.rr_ms_detrended);
nl_metrics = plot_poincare(rr_data_detrended.rr_ms_detrended); % (这会生成 静态庞加莱图)

% 频域 (LF/HF) 必须在“未去趋势”的数据上计算
fd_metrics = calculate_freq_domain(rr_data_clean.rr_ms_clean, rr_data_clean.timestamps_ms);

disp('HRV 指标计算完成。');

% 8. (V7 核心) 生成并打印“静态”HRV 报告
fprintf('正在生成 HRV 静态报告...\n');
% (调用我们 V7.2 的存档函数)
generate_hrv_report_V7_2_STATIC(rr_data_raw.metadata, td_metrics, fd_metrics, nl_metrics);


% 9. (可选) 动态回放完整的 ECG 信号
% -----------------------------------------------------------------
drawnow; % (关键) 强制 MATLAB 在 input() 之前先画图
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

fprintf('静态分析流程结束。\n');