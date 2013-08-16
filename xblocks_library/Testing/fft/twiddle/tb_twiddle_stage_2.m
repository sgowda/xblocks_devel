clear; clc; close all;
mdl_name = 'twiddle_stage_2';
eval(mdl_name)

%% Generate simulation data
T_sim = 100;

stage = 2;
FFTSize = 5;
fft_length = 2^FFTSize;

[a, a_data] = data_burst(fft_length, T_sim, 1./16);
[b, b_data] = data_burst(fft_length, T_sim, 1./16);
[w, w_data] = data_burst(fft_length, T_sim, 1./16);

%% Re-draw
FFTSize = 5;
config.source = str2func('fft_twiddle_init_xblock');
config.toplevel = subblockname(mdl_name, 'twiddle_stage_2');
xBlock(config, {config.toplevel, 'twiddle_type', 'twiddle_stage_2', 'FFTSize', FFTSize});

%% Simulate
set_param(mdl_name, 'StopTime', num2str(T_sim - 1));
sim(mdl_name)

%% Verify
bw = bw_re + 1j*bw_im;
output_start = find(sync_out) + 1;
coeff = b_data.' ./ bw(output_start : output_start + fft_length -1 );

coeff_switching_period = 2^FFTSize / 2^stage;
true_coeff = repmat([1, 1j], 8, 2^(stage-1));
true_coeff = true_coeff(:);
data = [(0:fft_length-1)', coeff, true_coeff];

coeff_error = coeff - true_coeff;
fprintf('Max error: %g\n', max(abs(coeff_error)));
commandwindow