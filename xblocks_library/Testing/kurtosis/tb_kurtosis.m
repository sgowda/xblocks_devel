clc; clear; close all
mdl_name = 'kurtosis';
eval(mdl_name); % open design

%% Generate simulation inputs
log2_vec_len = 10;
vec_len = 2^log2_vec_len;
n_vecs = 3;
T_sim = vec_len*n_vecs + 100;
n_inputs = 8;

[X1, X1_data] = data_burst(vec_len*n_vecs, T_sim, 1);
[X2, X2_data] = data_burst(vec_len*n_vecs, T_sim, 1);
[X3, X3_data] = data_burst(vec_len*n_vecs, T_sim, 1);
[X4, X4_data] = data_burst(vec_len*n_vecs, T_sim, 1);
[X5, X5_data] = data_burst(vec_len*n_vecs, T_sim, 1);
[X6, X6_data] = data_burst(vec_len*n_vecs, T_sim, 1);
[X7, X7_data] = data_burst(vec_len*n_vecs, T_sim, 1);
[X8, X8_data] = data_burst(vec_len*n_vecs, T_sim, 1);

%% Re-draw blocks
tic
config.source = @kurtosis_init_xblock;
config.toplevel = subblockname(mdl_name, 'kurtosis');
xBlock(config, {config.toplevel, 'acc_len', log2_vec_len, 'n_inputs', n_inputs});

%% Simulate
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim-1));

% Run simulation
sim(mdl_name)
toc

%% Verify
% Error on final moment calculations
valid_inds = find(double(valid));
num_error = zeros(n_inputs, n_vecs);
den_error = zeros(n_inputs, n_vecs);

for m=1:n_inputs
    X_fi = eval(sprintf('X_fi%d', m));
    for k=1:n_vecs
        start = valid_inds(k);
        fi_data = X_fi(vec_len*(k-1)+2:vec_len*k+1);        
        [~, kurtosis_num_fl, kurtosis_den_fl] = excess_kurtosis_complex(fi_data);

        num_error(m, k) = (kurtosis_num_fl - num(valid_inds((k-1)*n_inputs+m)));
        den_error(m, k) = kurtosis_den_fl - den(valid_inds((k-1)*n_inputs+m));
    end
end
fprintf('Max num error: %g\n', max(max(abs(num_error))));
fprintf('Max den error: %g\n', max(max(abs(den_error))));
commandwindow
