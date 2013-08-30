clc; clear; close all

mdl_name = 'vacc';
eval(mdl_name); % open design

%% Generate simulation inputs
veclen = 0;
n_vecs = 20;

din_bit_width = 50;
din_bin_pt = din_bit_width - 1;

acc_len = 2;
din_data = randn(2^veclen, n_vecs) / 4;
din_data_fi = double(fi(din_data, 1, din_bit_width, din_bin_pt)); % TODO use 'quantize' function

T_sim = (n_vecs + 4)*2^veclen + 100;

din = construct_sim_timeseries(din_data_fi(:)', T_sim);

set_param(subblockname(mdl_name, 'din'), 'n_bits', num2str(din_bit_width), 'bin_pt', num2str(din_bin_pt));
%% Re-draw blocks

config.source = @vacc_init_xblock;
config.toplevel = subblockname(mdl_name, 'vacc');
xBlock(config, {config.toplevel, 'veclen', veclen, 'in_bit_width', din_bit_width, 'in_bin_pt', din_bin_pt});
        
%% Simulate
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim-1));

% Run simulation
sim(mdl_name)

%% Verify
n_accs = n_vecs / acc_len;
acc_vecs = zeros(2^veclen, n_accs);
for k=1:n_accs
    acc_vecs(:,k) = sum(din_data_fi(:, (k-1)*acc_len+1:k*acc_len), 2);
end

valid_inds = find(double(valid));
vacc_error = acc_vecs(:) - dout(valid_inds(1:2^veclen*n_accs));
if all(vacc_error == 0)
    fprintf('Pass\n')
else
    fprintf('Error!\n')
end
