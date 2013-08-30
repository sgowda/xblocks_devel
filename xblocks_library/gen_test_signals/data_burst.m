function [a, a_data] = data_burst(burst_len, vec_len, scale, varargin)
    defaults = {'distr', 'unif'};
    distr = get_var('distr', 'defaults', defaults, varargin{:});
    if strcmp(distr, 'unif')
        a_data_real = (rand(1, burst_len) * 2 -1)*scale;
        a_data_imag = (rand(1, burst_len) * 2 -1)*scale;
    elseif strcmp(distr, 'normal')
        a_data_real = randn(1, burst_len)*scale;
        a_data_imag = randn(1, burst_len)*scale;
    else
        error('Unrecognized distribution: %s', distr);
    end
    a_data = complex(a_data_real, a_data_imag);
    a = [0, a_data, zeros(1, vec_len-burst_len-1)];
    a = timeseries(a, 0:vec_len-1, 'name', 'a');
end