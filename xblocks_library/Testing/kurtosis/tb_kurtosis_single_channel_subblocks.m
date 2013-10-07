clc; clear; close all
mdl_name = 'kurtosis_single_channel_subblocks';
eval(mdl_name); % open design

%% Generate simulation inputs
log2_vec_len = 10;
vec_len = 2^log2_vec_len;
n_vecs = 3;
T_sim = vec_len*n_vecs + 500;

[X, X_data] = data_burst(vec_len*n_vecs, T_sim, 1./4, 'distr', 'normal');

%% Re-draw blocks
% fprintf('Redrawing origin moments\n')
% config.source = @kurtosis_origin_moments_init_xblock;
% config.toplevel = subblockname(mdl_name, 'kurtosis_origin_moments');
% xBlock(config, {config.toplevel});
% 
% fprintf('Redrawing accumulators\n')
% config.source = @kurtosis_acc_bank_init_xblock;
% config.toplevel = subblockname(mdl_name, 'kurtosis_acc_bank');
% xBlock(config, {config.toplevel, 'acc_len', vec_len});
% 
% fprintf('Redrawing moment calculators\n')
% config.source = @kurtosis_moment_calc_init_xblock;
% config.toplevel = subblockname(mdl_name, 'kurtosis_central_moment_calc');
% xBlock(config, {config.toplevel, 'acc_len', log2_vec_len});
%% Simulate
set_param(mdl_name, 'StopTime', num2str(T_sim - 1));
sim(mdl_name)

%% Verify accumulator outputs
fprintf('# of sync outs correct: %d\n', length(find(double(acc_valid))) == n_vecs);
acc_valid_inds = find(double(acc_valid));

X_mean = X_re_mean + 1j*X_im_mean;
X_sq_mean = X_sq_re_mean + 1j*X_sq_im_mean;
X_cube_mean = X_3rd_pow_re_mean + 1j*X_3rd_pow_im_mean;

X_mean_error         = zeros(1, n_vecs);
X_sq_mean_error      = zeros(1, n_vecs);
X_cube_mean_error    = zeros(1, n_vecs);
abs_X_sq_mean_error  = zeros(1, n_vecs);
abs_X_4th_mean_error = zeros(1, n_vecs);

for k=1:n_vecs
    start = acc_valid_inds(k);
    fi_data = double(X_fi(vec_len*(k-1)+2:vec_len*k+1));

    X_mean_error(k)         = mean(fi_data) - X_mean(start);
    X_sq_mean_error(k)      = mean(fi_data.^2) - X_sq_mean(start);
    X_cube_mean_error(k)    = mean(fi_data .* abs(fi_data).^2) - X_cube_mean(start);
    abs_X_sq_mean_error(k)  = mean(abs(fi_data).^2) - abs_X_sq_mean(start);
    abs_X_4th_mean_error(k) = mean(abs(fi_data).^4) - abs_X_4th_power_mean(start);
end

max(abs(X_mean_error))
max(abs(X_sq_mean_error))
max(abs(X_cube_mean_error))
max(abs(abs_X_sq_mean_error))
max(abs(abs_X_4th_mean_error))

%% Error on final moment calculations
valid_inds = find(double(valid));

fourth_moment_diff = zeros(1, n_vecs);
second_moment_diff = zeros(1, n_vecs);
fl_error_num       = zeros(1, n_vecs);
fl_error_den       = zeros(1, n_vecs);
kappa_x_fi         = zeros(1, n_vecs);
kappa_x            = zeros(1, n_vecs);

for k=1:n_vecs
    fi_data = X_fi(vec_len*(k-1)+2:vec_len*k+1);
    x_re = fi(real(fi_data), 1, 18, 17);
    x_im = fi(imag(fi_data), 1, 18, 17);
%     x_fi_k = x_re + 1j*x_im;
    x_fi_k = fi_data;
    [kappa_x_fi(k), kurtosis_num_fi, kurtosis_den_fi, mean_power_fi] = excess_kurtosis_complex_stream_fi(x_fi_k);
    [kappa_x(k), kurtosis_num, second_abs_moment_sq,] = excess_kurtosis_complex(fi_data);
    
    fl_error_num(k) = kurtosis_num - double(kurtosis_num_fi);
    fl_error_den(k) = second_abs_moment_sq - double(kurtosis_den_fi);

    fourth_moment_diff(k) = fourth_central_moment(valid_inds(k)) - kurtosis_num_fi;
    second_moment_diff(k) = kurtosis_den_fi - kurtosis_den(valid_inds(k));
    power_diff(k) = power(valid_inds(k)) - double(mean_power_fi);
end
second_moment_diff
fourth_moment_diff
power_diff
fprintf('(num error)/num = %g\n', mean(abs(fl_error_num) / fourth_central_moment(valid_inds(k))));
fprintf('(den error)/den = %g\n', mean(abs(fl_error_den) / kurtosis_den(valid_inds(k))));

commandwindow
