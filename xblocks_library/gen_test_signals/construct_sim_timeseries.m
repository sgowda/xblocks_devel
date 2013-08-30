function [x_ts, x_data] = construct_sim_timeseries(x_data, vec_len, varargin)
% [x_ts] = construct_sim_timeseries(x_data, vec_len, varargin)
    defaults = {'sample_rate', 1};
    sample_rate = get_var('sample_rate', 'defaults', defaults, varargin{:});
    
    L = length(x_data);
    x_data = [0, x_data, zeros(1, vec_len/sample_rate - L - 1)];
    x_ts = timeseries(x_data, (0:vec_len/sample_rate-1)*sample_rate);
end