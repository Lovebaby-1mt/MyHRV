% /reporting/generate_hrv_report.m
% [V7.2] 增加了“会话信息”板块
%      - 函数签名改变：增加了 (metadata) 作为第一个参数
%      - 在报告最上方打印 测量时间, 设备ID, 和 数据时长

function generate_hrv_report(metadata, td_metrics, fd_metrics, nl_metrics)
    % (V7.2) 函数签名已改变，第一个参数是 metadata
    
    % =============================================
    %  (新增) 第 0 部分：会话信息
    % =============================================
    fprintf('********************************************************\n');
    fprintf('           === 测量会话信息 ===\n');
    fprintf('********************************************************\n');
    fprintf('   测量时间: %s\n', metadata.collection_timestamp);
    fprintf('   设备 ID: %s\n', metadata.device_id);
    fprintf('   有效数据时长: %.1f 秒\n', metadata.duration_s);
    fprintf('********************************************************\n\n');
    
    % =============================================
    %  第 1 部分：HRV 科普前言 (保持不变)
    % =============================================
    fprintf('           HRV (心率变异性) 科普指南\n');
    fprintf('********************************************************\n');
    % ... (科普内容和 V7.1 完全一样) ...
    fprintf('HRV 是什么？\n');
    fprintf('   它测量的是您“心跳间隔”的微小变化，是反映您“健康自动调控系统”(自主神经系统)状态的黄金标准。\n\n');
    fprintf('为什么 HRV 很重要？\n');
    fprintf('   您的调控系统分为两部分：\n');
    fprintf('   1. “应激系统”(交感神经): 负责应对压力、保持警觉。在白天工作、运动时活跃。\n');
    fprintf('   2. “恢复系统”(副交感神经): 负责休息、消化、身体修复。在放松、睡眠时活跃。\n\n');
    fprintf('========================================================\n\n');

    % =============================================
    %  第 2 部分：您的 HRV 状态快照 (V7.1 严谨逻辑)
    % =============================================
    fprintf('           === 您的 HRV 状态快照 ===\n\n');
    
    % --- 1. 总体心率状态 ---
    MeanHRV = 60000 / td_metrics.MeanNN;
    fprintf('1. 总体心率状态\n');
    fprintf('   平均心率: %.0f BPM (心跳间隔: %.2f ms)\n', MeanHRV, td_metrics.MeanNN);
    if MeanHRV > 80
        fprintf('   解读: 您的身体目前处于清醒、警觉或轻度压力的状态。\n\n');
    else
        fprintf('   解读: 您的身体目前处于平静、放松的静息状态。\n\n');
    end

    % --- 2. 核心平衡：“应激” vs “恢复” ---
    fprintf('2. 核心平衡：“应激” vs “恢复”\n');
    fprintf('   [指标] LF/HF Ratio: %.2f\n', fd_metrics.LF_HF_Ratio);
    
    if fd_metrics.LF_HF_Ratio > 2.0
        fprintf('   范围: > 2.0 (应激系统明显占优)\n');
        fprintf('   解读: 您的“应激系统”(交感)活跃度远高于“恢复系统”(副交感)。\n   (这在专注工作、焦虑或运动后是正常的，但不利于睡前。)\n\n');
    elseif fd_metrics.LF_HF_Ratio > 1.0
        fprintf('   范围: 1.0 - 2.0 (应激系统略微占优)\n');
        fprintf('   解读: 您的“应激系统”活跃度略高于“恢复系统”，身体处于警觉状态。\n\n');
    else
        fprintf('   范围: < 1.0 (恢复系统占优)\n');
        fprintf('   解读: 您的“恢复系统”活跃度高于“应激系统”，身体处于放松、修复状态。\n\n');
    end
    
    % --- 3. “恢复系统”的活跃度 (副交感神经功能) ---
    fprintf('3. “恢复系统”的活跃度 (副交感神经功能)\n');
    fprintf('   [指标] RMSSD: %.2f ms (行业金标准, 反映即时恢复力)\n', td_metrics.RMSSD);
    
    if td_metrics.RMSSD > 50
        fprintf('   范围: > 50 ms (非常活跃)\n');
        fprintf('   解读: 您的“恢复系统”非常活跃，恢复能力强劲 (常见于高水平耐力运动员或深度放松)。\n\n');
    elseif td_metrics.RMSSD > 20
        fprintf('   范围: 20 - 50 ms (健康范围)\n');
        fprintf('   解读: 您的“恢复系统”活跃度处于健康成年人的正常静息范围。\n\n');
    else
        fprintf('   范围: < 20 ms (活跃度偏低)\n');
        fprintf('   解读: 您的“恢复系统”活跃度偏低 (可能处于压力、疲劳、睡眠不足或恢复缓慢)。\n\n');
    end

    % --- (V7.1) pNN50 ---
    fprintf('   [指标] pNN50: %.2f %%\n', td_metrics.pNN50);
    if td_metrics.pNN50 > 15
        fprintf('   范围: > 15 %% (较活跃)\n');
        fprintf('   解读: 另一个指标显示您的“恢复系统”活跃度较高。\n\n');
    elseif td_metrics.pNN50 > 5
        fprintf('   范围: 5 - 15 %% (正常范围)\n');
        fprintf('   解读: 您的“恢复系统”活跃度正常。\n\n');
    else
        fprintf('   范围: < 5 %% (活跃度偏低)\n');
        fprintf('   解读: 您的“恢复系统”活跃度偏低。\n\n');
    end
    
    % --- 4. 总体健康储备 (心脏适应性) ---
    fprintf('4. 总体健康储备 (心脏适应性)\n');
    fprintf('   (注意: 以下指标反映“总体”变异性，包含长时程和短时程的所有变化)\n');
    
    fprintf('   [指标] SDNN: %.2f ms\n', td_metrics.SDNN);
    fprintf('   [指标] SD2:  %.2f ms (非线性指标, 评估长期变异)\n', nl_metrics.SD2);
    
    if td_metrics.SDNN > 30
        fprintf('   范围: 30 - 70 ms (正常范围)\n');
        fprintf('   解读: 您的心脏“总体灵活性”处于健康范围 (针对5分钟短时程记录)。\n\n');
    else
        fprintf('   范围: < 30 ms (偏低)\n');
        fprintf('   解读: 您的“总体灵活性”偏低，可能与长期压力、疲劳或自主神经功能下降有关。\n\n');
    end

    % --- (V7 算法备注) ---
    fprintf('   (!! 算法备注 !!)\n');
    fprintf('   为确保结果的学术严谨性，本报告中的 SDNN (%.2f ms) 和 SD2 (%.2f ms) 值\n', td_metrics.SDNN, nl_metrics.SD2);
    fprintf('   均在“线性去趋势”(Detrending)算法处理后的数据上计算。\n');
    fprintf('   这排除了心率缓慢漂移对结果的干扰，能更精确地反映您“真实”的总体变异性。\n');
    
    fprintf('========================================================\n');
end