% /visualization/plot_scrolling_ecg.m
% [V3] 实现了基于 tic/toc 的实时回放
%      - 使用“真实时间” (toc) 来驱动“数据时间” (t_sec)
%      - 使用“块渲染”(Chunk Rendering) 提高效率
%      - 增加了 ishandle 检查，防止用户关闭窗口时报错

function plot_scrolling_ecg(ecg_data, window_duration_s)
    %   Inputs:
    %       ecg_data:          包含 .voltage_mv 和 .timestamps_ms 的结构体
    %       window_duration_s: 窗口宽度 (例如: 10, 表示一次显示 10 秒)

    % 1. 准备数据 (V2 的 NaN 过滤)
    t_ms_raw = ecg_data.timestamps_ms;
    v_mv_raw = ecg_data.voltage_mv;
    
    nan_indices = isnan(t_ms_raw) | isnan(v_mv_raw);
    
    t_sec = t_ms_raw(~nan_indices) / 1000; % 转换为秒
    v_mv = v_mv_raw(~nan_indices);
    
    if any(nan_indices)
        fprintf('   (警告) 在 ECG 数据中检测到并移除了 %d 个 NaN 点。\n', sum(nan_indices));
    end
    
    % 2. 设置图窗和坐标轴
    figure('Name', 'ECG 信号动态回放 (实时)');
    ax = gca;
    
    ylim([-1.5, 2.0]); % 固定 Y 轴
    
    xlabel('时间 (秒)');
    ylabel('电压 (mV)');
    title('ECG 信号动态回放 (实时)');
    grid on;
    
    % 3. 创建 animatedline 对象
    h_line = animatedline('Color', [0, 0.4470, 0.7410]);
    
    % 4. (V3) 实时播放逻辑
    fprintf('ECG 实时播放中... (总时长: %.1f 秒)\n', t_sec(end));

    % 启动秒表
    real_time_start = tic; 
    
    % 获取数据的起始时间
    data_start_time = t_sec(1);
    
    % 我们从第一个点开始
    current_data_idx = 1; 
    
    % 只要数据没播完，并且图窗还开着，就继续
    while current_data_idx <= length(t_sec) && ishandle(h_line)
        
        % 1. 获取真实世界过去的时间
        real_time_elapsed = toc(real_time_start);
        
        % 2. 计算我们“应该”播放到的数据时间点
        current_target_data_time = data_start_time + real_time_elapsed;
        
        % 3. 查找从“上次的点”到“目标时间点”之间的所有数据
        %    (在 t_sec 数组中，从 current_data_idx 开始往后找)
        relative_indices_to_plot = find(t_sec(current_data_idx:end) <= current_target_data_time);
        
        if ~isempty(relative_indices_to_plot)
            % 4. 如果找到了需要绘制的新数据点
            
            % 获取这批数据的“绝对”索引
            last_relative_idx = relative_indices_to_plot(end);
            abs_idx_to_plot_end = current_data_idx + last_relative_idx - 1;
            
            % 5. (关键) 一次性“块渲染”所有新数据点
            addpoints(h_line, t_sec(current_data_idx:abs_idx_to_plot_end), v_mv(current_data_idx:abs_idx_to_plot_end));
            
            % 6. 更新X轴窗口 (只更新一次)
            current_display_time = t_sec(abs_idx_to_plot_end);
            ax.XLim = [current_display_time - window_duration_s, current_display_time];
            
            % 7. 刷新图窗
            drawnow('limitrate'); % 限制刷新率，防止卡顿
            
            % 8. 更新下一次循环的起始点
            current_data_idx = abs_idx_to_plot_end + 1;
        else
            % 9. 如果没找到新数据点 (意味着真实时间还没“追”上数据时间)
            %    暂停 1 毫秒，释放 CPU，防止 100% 占用
            pause(0.001); 
        end
    end

    if ishandle(h_line)
        fprintf('ECG 播放结束。\n');
    else
        fprintf('ECG 播放被用户手动关闭。\n');
    end
end