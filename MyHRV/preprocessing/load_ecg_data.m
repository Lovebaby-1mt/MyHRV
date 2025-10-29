function ecg_data = load_ecg_data(filepath)
    % load_ecg_data: 从 Polar H10 导出的 .txt 文件中加载原始 ECG 数据
    % [更新 v3] 在 'mean' 函数中使用 'omitnan' 来跳过 NaN 值，确保 Fs 计算正确

    disp(['正在加载 ECG 数据: ' filepath]);
    
    opts = detectImportOptions(filepath, 'FileType', 'text');
    opts.CommentStyle = '#';
    opts.Delimiter = ',';
    opts.VariableNamingRule = 'preserve'; 
    
    try
        T = readtable(filepath, opts);
        
        if width(T) < 2
            error('ECG 文件格式不正确，未找到第 2 列 (MS)。');
        end

        % --- 鲁棒性修复 (v3) ---
        % 4. 估算采样率 (Fs)
        %    计算时间戳的差值
        intervals_ms = diff(T{:, 2}); % T{:, 2} 表示第 2 列的数据
        
        %    计算平均差值，并使用 'omitnan' 忽略任何 NaN 值
        avg_interval_ms = mean(intervals_ms, 'omitnan');
        
        fs_hz = 1000 / avg_interval_ms;
        
        fprintf('  加载了 %d 个 ECG 样本. 估算采样率 Fs: %.2f Hz.\n', height(T), fs_hz);
        
        % 5. 打包为标准 struct 接口
        ecg_data.voltage_mv = T{:, 1};    % 第 1 列是 ECG
        ecg_data.timestamps_ms = T{:, 2}; % 第 2 列是 MS
        ecg_data.fs_hz = fs_hz;
        ecg_data.source_file = filepath;
        
    catch ME
        if contains(ME.message, '索引超出') || contains(ME.message, '格式不正确')
            error('读取 ECG 文件失败: %s\n列数似乎不匹配。请检查文件格式是否为 "ECG, MS"。\n原始错误: %s', filepath, ME.message);
        else
             error('读取 ECG 文件失败: %s\n%s', filepath, ME.message);
        end
    end
end