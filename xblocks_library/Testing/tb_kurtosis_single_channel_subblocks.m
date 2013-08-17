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
fprintf('Redrawing origin moments\n')
config.source = @kurtosis_origin_moments_init_xblock;
config.toplevel = subblockname(mdl_name, 'kurtosis_origin_moments');
xBlock(config, {config.toplevel});

fprintf('Redrawing accumulators\n')
config.source = @kurtosis_acc_bank_init_xblock;
config.toplevel = subblockname(mdl_name, 'kurtosis_acc_bank');
xBlock(config, {config.toplevel, 'acc_len', vec_len});

fprintf('Redrawing rounding\n')
config.source = @kurtosis_acc_rounding_init_xblock;
config.toplevel = subblockname(mdl_name, 'acc_rounding');
xBlock(config, {config.toplevel, 'acc_len', log2_vec_len});

fprintf('Redrawing moment calculators\n')
config.source = @kurtosis_moment_calc_init_xblock;
config.toplevel = subblockname(mdl_name, 'kurtosis_central_moment_calc');
xBlock(config, {config.toplevel, 'acc_len', log2_vec_len});
%% Simulate
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim-1));

% Run simulation
sim(mdl_name)

%% Verify accumulator outputs
fprintf('# of sync outs correct: %d\n', length(find(sync_out_acc)) == n_vecs);
sync_out_inds = find(sync_out_acc);

X_acc = X_re_acc + 1j*X_im_acc;
X_sq_acc = X_sq_re_acc + 1j*X_sq_im_acc;
X_cube_acc = X_3rd_pow_re_acc + 1j*X_3rd_pow_im_acc;

X_acc_error = zeros(1, n_vecs);
X_sq_acc_error = zeros(1, n_vecs);
X_cube_acc_error = zeros(1, n_vecs);
abs_X_sq_acc_error = zeros(1, n_vecs);
abs_X_4th_acc_error = zeros(1, n_vecs);

for k=1:n_vecs
    start = sync_out_inds(k) + 1;
    fi_data = X_fi(vec_len*(k-1)+2:vec_len*k+1);
    X_acc_error(k) = sum(fi_data) - X_acc(start);
    X_sq_acc_error(k) = sum(fi_data.^2) - X_sq_acc(start);
    X_cube_acc_error(k) = sum(fi_data .* abs(fi_data).^2) - X_cube_acc(start);
    abs_X_sq_acc_error(k) = sum(abs(fi_data).^2) - abs_X_sq_acc(start);
    abs_X_4th_acc_error(k) = sum(abs(fi_data).^4) - abs_X_4th_power_acc(start);
end

max(abs(X_acc_error))
max(abs(X_sq_acc_error))
max(abs(X_cube_acc_error))
max(abs(abs_X_sq_acc_error))
max(abs(abs_X_4th_acc_error))

%% Error on rounded accumulated outputs
m_x_rounded = m_x_re_rounded + 1j*m_x_im_rounded;
X_sq_acc_rounded = X_sq_re_acc_rounded + 1j*X_sq_im_acc_rounded;
X_cube_acc_rounded = X_3rd_pow_re_acc_rounded + 1j*X_3rd_pow_im_acc_rounded;

X_acc_rounded_error = zeros(1, n_vecs);
X_sq_acc_rounded_error = zeros(1, n_vecs);
X_cube_acc_rounded_error = zeros(1, n_vecs);
abs_X_sq_acc_rounded_error = zeros(1, n_vecs);
abs_X_4th_acc_rounded_error = zeros(1, n_vecs);

sync_out_inds = find(sync_out_acc_rounded);
for k=1:n_vecs
    start = sync_out_inds(k) + 1;
    fi_data = X_fi(vec_len*(k-1)+2:vec_len*k+1);
    X_acc_rounded_error(k) = 1./vec_len * sum(fi_data) - m_x_rounded(start);
    X_sq_acc_rounded_error(k) = sum(fi_data.^2) - X_sq_acc_rounded(start);
    X_cube_acc_rounded_error(k) = sum(fi_data .* abs(fi_data).^2) - X_cube_acc_rounded(start);
    abs_X_sq_acc_rounded_error(k) = sum(abs(fi_data).^2) - abs_X_sq_acc_rounded(start);
end

max(abs(X_acc_rounded_error))
max(abs(X_sq_acc_rounded_error))
max(abs(X_cube_acc_rounded_error))
max(abs(abs_X_sq_acc_rounded_error))

%% Error on final moment calculations
valid_inds = find(valid);
fourth_moment_diff = zeros(1, n_vecs);
second_moment_diff = zeros(1, n_vecs);
fl_error_num = zeros(1, n_vecs);
fl_error_den = zeros(1, n_vecs);
kappa_x_fi = zeros(1, n_vecs);
kappa_x = zeros(1, n_vecs);
for k=1:n_vecs
    fi_data = X_fi(vec_len*(k-1)+2:vec_len*k+1);
    x_re = fi(real(fi_data), 1, 18, 17);
    x_im = fi(imag(fi_data), 1, 18, 17);
    [kappa_x_fi(k), kurtosis_num_fi, second_abs_moment_sq_fi, fourth_abs_moment_fi, mean_power_fi] = excess_kurtosis_complex_stream_fi(x_re, x_im);
    [kappa_x_fi(k), kurtosis_num_fi2, second_abs_moment_sq_fi2, mean_power_fi2] = excess_kurtosis_complex_stream_fi2(x_re, x_im);
    [kappa_x(k), kurtosis_num, second_abs_moment_sq,] = excess_kurtosis_complex(fi_data);
    
    fl_error_num(k) = kurtosis_num - double(kurtosis_num_fi2);
    fl_error_den(k) = second_abs_moment_sq - double(second_abs_moment_sq_fi2);

    fourth_moment_diff(k) = fourth_central_moment(valid_inds(k)) - kurtosis_num_fi2;
    second_moment_diff(k) = second_abs_moment_sq_fi2 - kurtosis_den(valid_inds(k));

end
second_moment_diff
fourth_moment_diff
fprintf('(num error)/num = %g\n', mean(abs(fl_error_num) / fourth_central_moment(valid_inds(k))));
fprintf('(den error)/den = %g\n', mean(abs(fl_error_den) / kurtosis_den(valid_inds(k))));

%     kurtosis_den_fl = mean(abs(fi_data - mean(fi_data)).^2)^2;
%     kurtosis_num = mean(abs(fi_data - mean(fi_data)).^4);
    
    
%     [kappa_x, kurtosis_num, second_abs_moment_sq, fourth_abs_moment] = excess_kurtosis_complex_stream_fi(fi(real(fi_data), 1, 18, 17), fi(imag(fi_data), 1, 18, 17))
    
%     start = sync_out_inds(k) + 1;
%     fourth_central_moment_fl = 1./vec_len * (abs_X_4th_power_acc(start) - (4*real(X_cube_acc(start)*conj(m_x(start)))) + ...
%         (2*real(X_sq_acc(start) * conj(m_x(start)^2))) + (4*(abs_X_sq_acc(start)).*abs(m_x(start)).^2) + (abs(m_x(start)).^4 - 4*abs(m_x(start))^4));
    
%     start = valid_inds(k);
%     fourth_moment_error(k) = (kurtosis_num - fourth_central_moment(start));
%     second_moment_error(k) = kurtosis_den_fl - kurtosis_den(start);


% [fourth_moment_error', second_moment_error']
% fl_error_num
% fl_error_den

% fourth_central_moment = 1./vec_len * (abs_X_4th_power_acc(start) - (4*real(X_cube_acc(start)*conj(m_x(start)))) + ...
% 	(2*real(X_sq_acc(start) * conj(m_x(start)^2))) + (4*(abs_X_sq_acc(start)).*abs(m_x(start)).^2) + (abs(m_x(start)).^4 - 4*abs(m_x(start))^4))

commandwindow