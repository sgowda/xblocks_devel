clc; clear; close all

mdl_name = 'delay_bram';
eval(mdl_name); % open design

%% Re-draw blocks
latency = 10;
config.source = @delay_bram_init_xblock;
config.toplevel = subblockname(mdl_name, 'delay_bram');
xBlock(config, {config.toplevel, 'latency', latency});

%% Generate simulation inputs
T_sim = 100;
[din, din_data] = data_burst_real(T_sim - latency - 5, T_sim, 1);
din_data_fi = double(fi(din_data, 1, 18, 17)); % TODO use actual rounding
din = construct_sim_timeseries(din_data_fi, T_sim);

%% Simulate
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim-1));

% Run simulation
sim(mdl_name)

%% Verify
start = 1;
x = [0, din_data_fi]';
all(x == dout(latency+start : latency+start+length(din_data)))