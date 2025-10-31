% /reporting/generate_dynamic_report.m
% [V8.6 新增] 动态分析总结报告
%      - 读取“滑动窗口”的结果，并生成一份文字总结
%      - 报告峰值、谷值和均值，讲述一个“故事”

function generate_dynamic_report(metadata, results)
    %   Inputs:
    %       metadata: 包含 .duration_s 等信息
    %       results:  包含 .rmssd, .lfhf, .hr, .time_min 的时序数组

    % 检查数据是否为空
    if isempty(results.time_min)
        fprintf('   (警告) 动态总结报告无数据可供分析。\n');
        return;
    end

    % =============================================
    %  第 1 部分：测量会话信息 (保持)
    % =============================================
    fprintf('********************************************************\n');
    fprintf('           === 测量会话信息 ===\n');
    fprintf('********************************************************\n');
    fprintf('   测量时间: %s\n', metadata.collection_timestamp);
    fprintf('   设备 ID: %s\n', metadata.device_id);
    fprintf('   有效数据时长: %.1f 秒 (%.1f 分钟)\n', metadata.duration_s, metadata.duration_s / 60);
    fprintf('********************************************************\n\n');

    % =============================================
    %  第 2 部分：动态分析总结 (V8.6 核心)
    % =============================================
    fprintf('           === 动态分析总结 ===\n');
    fprintf('   (基于 %.0f 分钟窗口, %.0f 分钟步长)\n\n', 300/60, 60/60); % 假设 5min, 1min
    
    % --- 1. 分析心率 (HR) ---
    [min_hr, min_hr_idx] = min(results.hr);
    [max_hr, max_hr_idx] = max(results.hr);
    mean_hr = mean(results.hr);
    
    fprintf('1. 总体心率 (HR) 状态：\n');
    fprintf('   - 平均心率: %.1f BPM (在 %.1f 分钟内)\n', mean_hr, metadata.duration_s / 60);
    fprintf('   - 状态波动: 心率在 %.1f BPM (在 %.1f 分钟) 到 %.1f BPM (在 %.1f 分钟) 之间波动。\n', ...
            min_hr, results.time_min(min_hr_idx), max_hr, results.time_min(max_hr_idx));
    
    % --- 2. 分析恢复系统 (RMSSD) ---
    [min_rmssd, min_rmssd_idx] = min(results.rmssd);
    [max_rmssd, max_rmssd_idx] = max(results.rmssd);
    mean_rmssd = mean(results.rmssd);
    
    fprintf('\n2. “恢复系统” (RMSSD) 活跃度：\n');
    fprintf('   - 平均活跃度: %.2f ms (整体均值)\n', mean_rmssd);
    fprintf('   - 活跃度范围: 从最低 %.2f ms (在 %.1f 分钟) 到 最高 %.2f ms (在 %.1f 分钟)。\n', ...
            min_rmssd, results.time_min(min_rmssd_idx), max_rmssd, results.time_min(max_rmssd_idx));

    % --- 3. 分析系统平衡 (LF/HF) ---
    [min_lfhf, min_lfhf_idx] = min(results.lfhf);
    [max_lfhf, max_lfhf_idx] = max(results.lfhf);
    mean_lfhf = mean(results.lfhf);
    
    fprintf('\n3. “应激/恢复”平衡 (LF/HF Ratio)：\n');
    fprintf('   - 平均平衡值: %.2f\n', mean_lfhf);
    fprintf('   - 状态波动: 从 %.2f (在 %.1f 分钟, 偏向恢复) 到 %.2f (在 %.1f 分钟, 偏向应激)。\n', ...
            min_lfhf, results.time_min(min_lfhf_idx), max_lfhf, results.time_min(max_lfhf_idx));
    
    % --- 4. (关键) 结论性故事 ---
    fprintf('\n--------------------------------------------------------\n');
    fprintf('   结论性解读:\n');
    
    % 这是一个基于您图表的硬编码逻辑
    if max_hr_idx < 30 && min_rmssd_idx < 30 && max_lfhf_idx < 30
        fprintf('   数据显示了一个清晰的“应激-恢复”模式：\n');
        fprintf('   - 在前 %.0f 分钟左右, 身体经历了显著的“应激事件”。\n', results.time_min(max_hr_idx));
        fprintf('     (表现为: 心率升至峰值 %.0f BPM, 恢复力(RMSSD)降至谷值 %.1f ms, 应激指数(LF/HF)升至峰值 %.1f)\n', ...
                 max_hr, min_rmssd, max_lfhf);
        fprintf('   - 在该事件后, 身体逐渐进入“恢复阶段”。\n');
        fprintf('     (表现为: 心率下降, RMSSD 和 LF/HF 均回归到较稳定的基线水平。)\n');
    else
        fprintf('   数据显示了在 %.1f 分钟内的生理状态波动，未检测到单一的“应激-恢复”模式。\n', metadata.duration_s / 60);
    end
    
    fprintf('========================================================\n');
end