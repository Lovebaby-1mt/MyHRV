% /preprocessing/detrend_window.m
% 描述: 对一个“数据窗口”(Window)进行线性去趋势
%      - 这是一个精简版，专门用于在循环中被调用

function rr_ms_detrended = detrend_window(t_sec_window, rr_ms_window)
    %   Inputs:
    %       t_sec_window: 窗口内的时间戳数组 (单位: 秒)
    %       rr_ms_window: 窗口内的 RR 间期数组 (单位: ms)
    
    % 1. 拟合线性趋势 (1阶多项式)
    p = polyfit(t_sec_window, rr_ms_window, 1);
    
    % 2. 计算趋势线
    trend_line = polyval(p, t_sec_window);
    
    % 3. 从原始信号中减去趋势线，并加回均值
    rr_ms_detrended = (rr_ms_window - trend_line) + mean(rr_ms_window);
end