function rr_data = load_rr_data(filepath)
    % load_rr_data: 从 Polar H10 导出的 .txt 文件中加载 RR 间期数据
    % [更新 v2] 采用列索引 (T{:, 1}) 而不是列名称 (T.HR)，以提高鲁棒性

    disp(['正在加载 RR 数据: ' filepath]);
    
    opts = detectImportOptions(filepath, 'FileType', 'text');
    opts.CommentStyle = '#';
    opts.Delimiter = ',';
    
    opts.VariableNamingRule = 'preserve';
    
    try
        T = readtable(filepath, opts);
        
        % --- 鲁棒性修复 ---
        % 4. 过滤数据：只保留皮肤有接触 (SC == 1) 的有效数据
        %    使用列索引 (Col 4) 而不是名称 ('SC')
        initial_count = height(T);
        
        % 检查列数
        if width(T) < 4
            error('RR 文件格式不正确，未找到第 4 列 (SC)。');
        end
        
        T = T(T{:, 4} == 1, :); % T{:, 4} 表示第 4 列 (SC)
        valid_count = height(T);
        
        fprintf('  加载了 %d 行数据, 移除了 %d 行 (因皮肤未接触).\n', initial_count, initial_count - valid_count);
        
        % 5. 打包为标准 struct 接口
        %    使用列索引 (Col 2, 3, 1) 而不是名称
        %    (根据文件格式：HR, RR, MS, SC)
        rr_data.hr_bpm = T{:, 1};        % 第 1 列是 HR
        rr_data.rr_ms = T{:, 2};         % 第 2 列是 RR
        rr_data.timestamps_ms = T{:, 3}; % 第 3 列是 MS
        rr_data.source_file = filepath;
        
    catch ME
        % 增强错误提示
        if contains(ME.message, '索引超出') || contains(ME.message, '格式不正确')
            error('读取 RR 文件失败: %s\n列数似乎不匹配。请检查文件格式是否为 "HR, RR, MS, SC"。\n原始错误: %s', filepath, ME.message);
        else
            error('读取 RR 文件失败: %s\n%s', filepath, ME.message);
        end
    end
end