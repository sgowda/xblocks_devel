clc; clear; close all

mdl_name = 'delay_bram';
eval(mdl_name); % open design

%% Test parameters to sweep over
latencies = [5, 6, 7, 8];
bram_latencies = [2, 3, 4];

%% Generate simulation inputs
T_sim = 100;
data_len = T_sim - max(latencies) - max(bram_latencies) - 1;
[din, din_data] = data_burst_real(data_len, T_sim, 1);
din_data_fi = double(fi(din_data, 1, 18, 17)); % TODO use 'quantize' function
din = construct_sim_timeseries(din_data_fi, T_sim);

%% Re-draw blocks
for latency=latencies
    for bram_latency=bram_latencies
        config.source = @delay_bram_init_xblock;
        config.toplevel = subblockname(mdl_name, 'delay_bram');
        xBlock(config, {config.toplevel, 'latency', latency, 'bram_latency', bram_latency});
        
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