% ============== main_analysis.m ==============
% 描述: 主运行脚本，用于加载、分析和可视化 HRV 数据
% [更新 v2] 将 ECG 和 RR 图表统一为显示前 10 秒的数据
% =============================================

clear; clc; close all;

% 1. 添加子文件夹到路径 (确保模块化)
addpath('preprocessing');
addpath('visualization');
addpath('core_functions');

% 2. 定义文件路径
rr_file_path = 'HR_2025.10.27_19.30.36.txt';
ecg_file_path = 'ECG_2025.10.27_19.30.36.txt';

% 3. 加载数据 (调用我们刚创建的函数)
try
    rr_data = load_rr_data(rr_file_path);
    ecg_data = load_ecg_data(ecg_file_path);
catch ME
    % 如果加载失败，显示错误并停止
    disp('!!! 数据加载失败 !!!');
    rethrow(ME);
end

% 4. 数据导入“健全性检查” (Sanity Check)
%    在进行复杂分析前，先快速绘图查看数据是否正确

% --- 更新：统一设置显示时长 ---
plot_duration_ms = 10000; % 设置为 10000 毫秒 (10秒)
plot_duration_s = plot_duration_ms / 1000;

figure('Name', '数据导入检查 (前 10 秒)');

% 子图1: 绘制一小段 ECG 信号
subplot(2, 1, 1);
% 找到 10 秒内的 ECG 样本索引
ecg_indices = ecg_data.timestamps_ms <= plot_duration_ms;
plot(ecg_data.timestamps_ms(ecg_indices) / 1000, ecg_data.voltage_mv(ecg_indices));
title(sprintf('ECG 信号 (前 %.0f 秒)', plot_duration_s));
xlabel('时间 (秒)');
ylabel('电压 (mV)');
grid on;
axis tight; % 自动调整坐标轴

% 子图2: 绘制 RR 间期序列图 (Tachogram)
subplot(2, 1, 2);
% --- 更新：只绘制 10 秒内的 RR 点 ---
% 找到 10 秒内的 RR 点索引
rr_indices = rr_data.timestamps_ms <= plot_duration_ms;
plot(rr_data.timestamps_ms(rr_indices) / 1000, rr_data.rr_ms(rr_indices), 'o-');
title(sprintf('RR 间期序列图 (前 %.0f 秒)', plot_duration_s));
xlabel('时间 (秒)');
ylabel('RR 间期 (ms)');
grid on;
axis tight; % 自动调整坐标轴

disp('数据加载和初步可视化完成。');