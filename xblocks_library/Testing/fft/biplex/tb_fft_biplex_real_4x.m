clc; clear; close all;
mdl_name = 'fft_biplex_real_4x';

% Open the design
eval(mdl_name)

%% Re-draw blocks
config.source = str2func('fft_biplex_real_4x_init_xblock');
config.toplevel = subblockname(mdl_name, 'fft_biplex_real_4x');
xBlock(config, {config.toplevel, 'FFTSize', 6, 'mult_spec', [2,2,2,2,2,2], 'specify_mult', 'on', 'dsp48_adders', 'on', 'add_latency', 2});

%% Generate simulation data
T_sim = 300;
sync = zeros(1, T_sim);
sync(1) = 1;

FFTSize = 6;
fft_length = 2^FFTSize;
pol1_data = (rand(1, fft_length) * 2 -1)/16;
pol1 = [0, pol1_data, zeros(1, T_sim-fft_length-1)];

pol2_data = (rand(1, fft_length) * 2 -1)/16;
pol2 = [0, pol2_data, zeros(1, T_sim-fft_length-1)];

pol3_data = (rand(1, fft_length) * 2 -1)/16;
pol3 = [0, pol3_data, zeros(1, T_sim-fft_length-1)];

pol4_data = (rand(1, fft_length) * 2 -1)/16;
pol4 = [0, pol4_data, zeros(1, T_sim-fft_length-1)];

pol1 = timeseries(pol1);
pol2 = timeseries(pol2);
pol3 = timeseries(pol3);
pol4 = timeseries(pol4);

%% Simulate
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim-1));

% Run simulation
sim(mdl_name)

%% Verify
output_start = find(biplex_sync_out) + 1;
pol1_bits_lost = log2(max(abs(biplex_out1(output_start:output_start+fft_length - 1) - fft(pol1_data).'))/2^-17);
pol2_bits_lost = log2(max(abs(biplex_out2(output_start:output_start+fft_length - 1) - fft(pol2_data).'))/2^-17);
pol3_bits_lost = log2(max(abs(biplex_out3(output_start:output_start+fft_length - 1) - fft(pol3_data).'))/2^-17);
pol4_bits_lost = log2(max(abs(biplex_out4(output_start:output_start+fft_length - 1) - fft(pol4_data).'))/2^-17);

fprintf('Max bits lost for each pol: %g, %g, %g, %g\n', pol1_bits_lost, pol2_bits_lost, pol3_bits_lost, pol4_bits_lost)