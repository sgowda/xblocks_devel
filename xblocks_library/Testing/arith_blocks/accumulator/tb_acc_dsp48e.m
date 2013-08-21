clc; clear; close all

mdl_name = 'acc_dsp48e';
eval(mdl_name); % open design

%% Re-draw blocks
config.source = @acc_dsp48e_init_xblock;
config.toplevel = subblockname(mdl_name, 'acc_dsp48e');
xBlock(config, {config.toplevel});

%% Generate simulation inputs
T_sim = 100;
data_len = 90;
[din, din_data] = data_burst_real(data_len, T_sim, 1);
din_data_fi = double(fi(din_data, 1, 18, 17)); % TODO use 'quantize' function
din = timeseries(din_data_fi);
rst = timeseries(zeros(1, T_sim));

%% Simulate
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim-1));

% Run simulation
sim(mdl_name)

%% Verify
running_sum = cumsum(din_fi);
acc_error = running_sum(1:end-2) - din_acc(3:end);
if all(acc_error == 0)
    fprintf('Pass\n')
else
    fprintf('Fail\n')
end