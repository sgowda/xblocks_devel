clc; clear; close all

mdl_name = 'kurtosis_detector_serializer';
eval(mdl_name); % open design

%% Re-draw blocks
config.source = @kurtosis_data_serializer_init_xblock;
config.toplevel = subblockname(mdl_name, 'kurtosis_data_serializer');
xBlock(config, {config.toplevel})

%% Generate simulation inputs
T_sim = 2000;
shift = [0, ones(1,8), zeros(1,T_sim-8-1)];
shift = timeseries(shift, 0:(T_sim-1));

load = zeros(1, T_sim);
load_inds = randi([0, T_sim], [1, 5]);
load(load_inds) = 1;
load = timeseries(load, 0:(T_sim-1));

data_length = T_sim-1;
[din0, din0_data] = data_burst_real(data_length, T_sim, 1);
[din1, din1_data] = data_burst_real(data_length, T_sim, 1);
[din2, din2_data] = data_burst_real(data_length, T_sim, 1);
[din3, din3_data] = data_burst_real(data_length, T_sim, 1);
[din4, din4_data] = data_burst_real(data_length, T_sim, 1);
[din5, din5_data] = data_burst_real(data_length, T_sim, 1);
[din6, din6_data] = data_burst_real(data_length, T_sim, 1);
[din7, din7_data] = data_burst_real(data_length, T_sim, 1);

din = [din0.Data(:), din1.Data(:), din2.Data(:), din3.Data(:), din4.Data(:), din5.Data(:), din6.Data(:), din7.Data(:)]';

%% Simulate
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim-1));

% Run simulation
sim(mdl_name)

%% Verify
all(ser_data(logical(we)) == [zeros(8,1); reshape(din(:,sort(load_inds)), [], 1)])


% all(ser_data2(logical(we2)) == [zeros(2,1); reshape(din(1:2,sort(load_inds)), [], 1)])