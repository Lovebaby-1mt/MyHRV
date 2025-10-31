% /preprocessing/load_rr_data.m
% [V3] 增加了文件头元数据 (Metadata) 的解析功能
%      - 提取 Collection Timestamp 和 Device ID
%      - 计算有效数据的总时长

function rr_data = load_rr_data(filepath)
    % load_rr_data: 从 Polar H10 导出的 .txt 文件中加载 RR 间期数据
    % [更新 v3] 增加了元数据解析

    disp(['正在加载 RR 数据: ' filepath]);
    
    % --- (新增 V3) 元数据解析 ---
    try
        % 1. 将整个文件读入一个字符串
        file_content = fileread(filepath);
        
        % 2. 使用正则表达式提取所需信息
        % 提取 Collection Timestamp
        timestamp_match = regexp(file_content, '# Collection Timestamp: (.*?)\s*\n', 'tokens', 'once');
        if ~isempty(timestamp_match)
            rr_data.metadata.collection_timestamp = timestamp_match{1};
        else
            rr_data.metadata.collection_timestamp = '未知';
        end
        
        % 提取 Device Info ID
        device_match = regexp(file_content, '# Device Info: ID (.*?),', 'tokens', 'once');
        if ~isempty(device_match)
            rr_data.metadata.device_id = device_match{1};
        else
            rr_data.metadata.device_id = '未知';
        end
        
    catch ME_meta
        fprintf(' (警告) 解析元数据失败: %s. 继续加载数据...\n', ME_meta.message);
        rr_data.metadata.collection_timestamp = '解析失败';
        rr_data.metadata.device_id = '解析失败';
    end
    % --- 元数据解析结束 ---

    
    % --- (V2) 数据加载逻辑 (保持不变) ---
    opts = detectImportOptions(filepath, 'FileType', 'text');
    opts.CommentStyle = '#';
    opts.Delimiter = ',';
    opts.VariableNamingRule = 'preserve';
    
    try
        T = readtable(filepath, opts);
        
        if width(T) < 4
            error('RR 文件格式不正确，未找到第 4 列 (SC)。');
        end
        
        initial_count = height(T);
        
        % 4. 过滤数据：只保留 (SC == 1)
        T_valid = T(T{:, 4} == 1, :); % T{:, 4} 是 SC 列
        valid_count = height(T_valid);
        
        fprintf('  加载了 %d 行数据, 移除了 %d 行 (因皮肤未接触).\n', initial_count, initial_count - valid_count);
        
        % 5. 打包为标准 struct 接口
        rr_data.hr_bpm = T_valid{:, 1};        % 第 1 列是 HR
        rr_data.rr_ms = T_valid{:, 2};         % 第 2 列是 RR
        rr_data.timestamps_ms = T_valid{:, 3}; % 第 3 列是 MS
        rr_data.source_file = filepath;
        
        % --- (新增 V3) 计算有效时长 ---
        if valid_count > 1
            duration_ms = T_valid{end, 3} - T_valid{1, 3};
            rr_data.metadata.duration_s = duration_ms / 1000;
        else
            rr_data.metadata.duration_s = 0;
        end
        % --- 时长计算结束 ---
        
    catch ME
        % ... (错误处理保持不变) ...
        if contains(ME.message, '索引超出') || contains(ME.message, '格式不正确')
            error('读取 RR 文件失败: %s\n列数似乎不匹配。请检查文件格式是否为 "HR, RR, MS, SC"。\n原始错误: %s', filepath, ME.message);
        else
            error('读取 RR 文件失败: %s\n%s', filepath, ME.message);
        end
    end
end