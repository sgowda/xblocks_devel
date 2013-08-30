function [a, a_data] = data_burst_real(burst_len, vec_len, scale, varargin)
% [a, a_data] = data_burst_real(burst_len, vec_len, scale, varargin)
    defaults = {'sample_rate', 1};
    sample_rate = get_var('sample_rate', 'defaults', defaults, varargin{:});
    a_data = (rand(1, burst_len) * 2 -1)*scale;
    a = [0, a_data, zeros(1, vec_len/sample_rate-burst_len-1)];
    a = timeseries(a, (0:vec_len/sample_rate-1)*sample_rate, 'name', 'a');
end