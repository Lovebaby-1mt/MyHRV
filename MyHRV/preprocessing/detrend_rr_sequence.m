% /preprocessing/detrend_rr_sequence.m
% 描述: 对非均匀采样的 RR 序列进行线性去趋势 (Detrending)
%      - 解决“非平稳趋势”对 SDNN 和 SD2 造成的失真

function rr_data_out = detrend_rr_sequence(rr_data_in)
    
    % 1. 获取清理后的数据和对应的时间戳 (转为秒)
    rr_ms_clean = rr_data_in.rr_ms_clean;
    t_sec = rr_data_in.timestamps_ms / 1000;
    
    % 2. (关键) 拟合线性趋势
    % polyfit(x, y, n) - n=1 表示 1 阶多项式 (即线性)
    % 我们拟合 t_sec 和 rr_ms_clean 之间的线性关系
    p = polyfit(t_sec, rr_ms_clean, 1);
    
    % 3. 计算趋势线 (在每个时间点上的值)
    trend_line = polyval(p, t_sec);
    
    % 4. (关键) 从原始信号中减去趋势线
    % 注意：我们只减去趋势，不移除均值
    % (rr_ms_clean - trend_line) 会得到一个 0 均值附近的信号
    % 我们要把它加回到原始均值上
    rr_ms_detrended = (rr_ms_clean - trend_line) + mean(rr_ms_clean);
    
    % 5. 将新数据添加回结构体
    rr_data_out = rr_data_in; % 复制所有已有字段
    rr_data_out.rr_ms_detrended = rr_ms_detrended;
    
end