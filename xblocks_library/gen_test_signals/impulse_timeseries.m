function [a] = impulse_timeseries(impl_value, vec_len, varargin)
    defaults = {'sample_rate', 1};
    sample_rate = get_var('sample_rate', 'defaults', defaults, varargin{:});
    a = [0, impl_value, zeros(1, vec_len/sample_rate-2)];
    a = timeseries(a, (0:vec_len/sample_rate-1)*sample_rate, 'name', 'a');
end
