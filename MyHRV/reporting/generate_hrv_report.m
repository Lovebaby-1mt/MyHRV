% /reporting/generate_hrv_report.m

function generate_hrv_report(td_metrics, fd_metrics, nl_metrics)
    % generate_hrv_report: 接收 HRV 指标, 并在命令行中打印动态解读报告

    fprintf('=====================================\n');
    fprintf('   HRV 状态总结报告 (动态解读)\n');
    fprintf('=====================================\n\n');

    % --- 1. 时域指标解读 ---
    fprintf('--- 时域指标 (Time-Domain) ---\n');

    % 解读 Mean NN 和 HR
    MeanHRV = 60000 / td_metrics.MeanNN;
    fprintf('Mean NN (RR): %.2f ms (对应平均心率: %.0f BPM)\n', td_metrics.MeanNN, MeanHRV);
    if MeanHRV > 100
        fprintf('   状态: 心率偏高 (可能处于压力、运动后或心动过速范围)。\n');
    elseif MeanHRV > 80
        fprintf('   状态: 清醒、警觉或轻度压力状态。\n');
    elseif MeanHRV > 60
        fprintf('   状态: 平静、放松的静息状态。\n');
    else
        fprintf('   状态: 深度放松或睡眠状态。\n');
    end

    % 解读 RMSSD (副交感神经)
    fprintf('RMSSD:        %.2f ms\n', td_metrics.RMSSD);
    if td_metrics.RMSSD > 50
        fprintf('   状态: 副交感神经系统非常活跃 (恢复良好或高水平耐力)。\n');
    elseif td_metrics.RMSSD > 20
        fprintf('   状态: 副交感神经活动处于健康、正常范围。\n');
    else
        fprintf('   状态: 副交感神经活力偏低 (可能处于压力、疲劳或恢复不足)。\n');
    end

    % 解读 SDNN (总体变异性)
    fprintf('SDNN:         %.2f ms\n', td_metrics.SDNN);
    if td_metrics.SDNN > 70
        fprintf('   状态: 总体变异性很高 (!! 警告: 极高值通常由伪影/异常值引起)。\n');
    elseif td_metrics.SDNN > 30
        fprintf('   状态: 总体变异性处于健康范围 (针对5分钟短时程)。\n');
    else
        fprintf('   状态: 总体变异性偏低 (可能压力过大或自主神经系统功能下降)。\n');
    end

    % --- 2. 频域指标解读 ---
    fprintf('\n--- 频域指标 (Frequency-Domain) ---\n');
    fprintf('LF Power:       %.2f ms^2\n', fd_metrics.LF_Power);
    fprintf('HF Power:       %.2f ms^2\n', fd_metrics.HF_Power);
    fprintf('LF/HF Ratio:   %.2f\n', fd_metrics.LF_HF_Ratio);

    % 解读 LF/HF Ratio (交感/副交感平衡)
    if fd_metrics.LF_HF_Ratio > 2.0
        fprintf('   状态: 交感神经 (压力系统) 明显占优 (压力、焦虑、专注)。\n');
    elseif fd_metrics.LF_HF_Ratio > 1.0
        fprintf('   状态: 相对平衡，交感神经略微占优 (清醒、警觉)。\n');
    else
        fprintf('   状态: 副交感神经 (休息系统) 占优 (放松、恢复、困倦)。\n');
    end

    % --- 3. 非线性指标解读 ---
    fprintf('\n--- 非线性指标 (Poincaré) ---\n');
    fprintf('SD1:           %.2f ms (反映短期变异性, 评估副交感)\n', nl_metrics.SD1);
    fprintf('SD2:           %.2f ms (反映长期变异性, 评估总体)\n', nl_metrics.SD2);

    % --- 4. 总体警告 (基于伪影) ---
    if td_metrics.SDNN > 80 || nl_metrics.SD2 > 120
        fprintf('\n=====================================\n');
        fprintf('!! 关键警告 !!\n');
        fprintf('检测到极高的 SDNN 或 SD2 值。\n');
        fprintf('这强烈表明原始 RR 数据中包含伪影 (Artifacts)。\n');
        fprintf('请优先执行 `preprocessing/clean_rr_artifacts.m` 伪影修正，否则报告的准确性会严重失真。\n');
    end
    fprintf('=====================================\n');
end
