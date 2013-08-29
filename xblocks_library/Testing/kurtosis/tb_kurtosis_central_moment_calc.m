%% Init
clear; clc; close all
mdl_name = 'kurtosis_central_moment_calc';
eval(mdl_name)

%% Re-draw
config.source = @kurtosis_moment_calc_init_xblock;
config.toplevel = sprintf('%s/kurtosis_central_moment_calc', mdl_name);
xBlock(config, {config.toplevel});

%% Setup input signals
vec_len = 2^14;
n_vecs = 3;
data_len = 100;
T_sim = data_len + 100;

% Simulated input data
x_data_real = (randn(vec_len, data_len) * 0.25);
x_data_imag = (randn(vec_len, data_len) * 0.25);
x_data = x_data_real + 1j*x_data_imag;

% floating-point functionality of the accumulators
m_x = mean(x_data, 1);
x_sq_mean = mean(x_data.^2, 1);
x_3rd_mean = mean( x_data .* abs(x_data).^2, 1);

x_mean_re      = timeseries(real(m_x));
x_mean_im      = timeseries(imag(m_x));
x_sq_mean_re   = timeseries(real(x_sq_mean));
x_sq_mean_im   = timeseries(imag(x_sq_mean));
abs_x_sq_mean  = timeseries(mean(abs(x_data).^2, 1));
abs_x_4th_mean = timeseries(mean(abs(x_data).^4, 1));
x_3rd_mean_re  = timeseries(real(x_3rd_mean));
x_3rd_mean_im  = timeseries(imag(x_3rd_mean));

% Configure data types for from_workspace_real blocks
type_x = fi_dtype(1, 18, 17);
acc_len = log2(vec_len);
[x_mean_dtype, x_sq_mean_dtype, x_3rd_mean_dtype, x_4th_mean_dtype] = kurtosis_mean_types(type_x, acc_len);

set_from_workspace_dtype(subblockname(mdl_name, 'x_mean_re'), x_mean_dtype);
set_from_workspace_dtype(subblockname(mdl_name, 'x_mean_im'), x_mean_dtype);
set_from_workspace_dtype(subblockname(mdl_name, 'x_sq_mean_re'), x_sq_mean_dtype);
set_from_workspace_dtype(subblockname(mdl_name, 'x_sq_mean_im'), x_sq_mean_dtype);
set_from_workspace_dtype(subblockname(mdl_name, 'x_3rd_mean_re'), x_3rd_mean_dtype);
set_from_workspace_dtype(subblockname(mdl_name, 'x_3rd_mean_im'), x_3rd_mean_dtype);
set_from_workspace_dtype(subblockname(mdl_name, 'abs_x_sq_mean'), x_sq_mean_dtype);
set_from_workspace_dtype(subblockname(mdl_name, 'abs_x_4th_mean'), x_4th_mean_dtype);

%% Simulate
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim-1));

% Run simulation
sim(mdl_name)

%% Verify
output_start = find(double(valid));
den_error = zeros(1, data_len);
num_error = zeros(1, data_len);
% for k=1:data_len
%     output_ind = k + output_start - 1;
%     den_error(k) = kurtosis_den(output_ind) - mean(abs(x_data(:,k) - mean(x_data(:,k))).^2).^2; 
% %     kurtosis_num_fl = mean(abs(x_data(:,k) - mean(x_data(:,k))).^4);
%     kurtosis_num_fl = mean(abs(x_data(:,k) - mean(x_data(:,k))).^4) - abs(mean(x_data(:,k).^2) - mean(x_data(:,k)).^2)^2;
%     num_error(k) = kurtosis_num_fl - kurtosis_num(output_ind);
% end
% fprintf('Max den error: %g\n', max(abs(den_error)))
% fprintf('Max num error: %g\n', max(abs(num_error)))

% Compare results to fixed-point function implementation; should match exactly
[num_fi, den_fi, power_fi] = kurtosis_moment_calc_norm_inputs_fi(x_mean_re_fi, x_mean_im_fi, x_sq_mean_re_fi, x_sq_mean_im_fi, abs_x_sq_mean_fi, abs_x_4th_mean_fi, x_3rd_mean_re_fi, x_3rd_mean_im_fi);
power_diff = max(abs(double(power_fi(1:data_len) - power(output_start:output_start+data_len-1))))
den_diff = max(abs(double(den_fi(1:data_len) - den(output_start:output_start+data_len-1))))
num_diff = max(abs(double(num_fi(1:data_len) - num(output_start:output_start+data_len-1))))



commandwindow