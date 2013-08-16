clc; clear; close all

mdl_name = 'vacc';
eval(mdl_name); % open design

%% Test parameters to sweep over
veclen = [3, 4, 5, 6, 7, 8, 9, 10];
acc_len = 9;

%% Generate simulation inputs
data_len = max(veclen)*(acc_len + 1);

T_sim = 10000;
data_len = T_sim - max(latencies) - max(bram_latencies) - 1;
[din, din_data] = data_burst_real(data_len, T_sim, 1);
din_data_fi = double(fi(din_data, 1, 18, 17)); % TODO use 'quantize' function
din = construct_sim_timeseries(din_data_fi, T_sim);

%% Re-draw blocks
for latency=latencies
    for bram_latency=bram_latencies
        config.source = @vacc_init_xblock;
        config.toplevel = subblockname(mdl_name, 'vacc');
        xBlock(config, {config.toplevel});
        
        %-- Simulate
        % Set simulation time
        set_param(mdl_name, 'StopTime', num2str(T_sim-1));

        % Run simulation
        sim(mdl_name)

        %-- Verify
        start = 1;
        x = [0, din_data_fi]';
        all(x == dout(latency+start : latency+start+length(din_data)))        
    end
end