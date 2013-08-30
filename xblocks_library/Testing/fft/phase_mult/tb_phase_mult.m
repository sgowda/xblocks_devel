%% Init
clear; clc; close all;
mdl_name = 'phase_mult';
eval(mdl_name)

%% Draw test block
n_inputs = 16;
biplex_fft_length = 64;

config.source = str2func('phase_mult_init_xblock');
config.toplevel = sprintf('%s/phase_mult', mdl_name);
xBlock(config, {config.toplevel, 'n_inputs', n_inputs, ...
    'biplex_fft_length', biplex_fft_length, 'cmult_impl', 'dsp48e'});

%% Generate input data
T_sim = 200;
data_length = biplex_fft_length;

[pol1, pol1_data] = data_burst(data_length, T_sim, 1./16);
[pol2, pol2_data] = data_burst(data_length, T_sim, 1./16);
[pol3, pol3_data] = data_burst(data_length, T_sim, 1./16);
[pol4, pol4_data] = data_burst(data_length, T_sim, 1./16);
[pol5, pol5_data] = data_burst(data_length, T_sim, 1./16);
[pol6, pol6_data] = data_burst(data_length, T_sim, 1./16);
[pol7, pol7_data] = data_burst(data_length, T_sim, 1./16);
[pol8, pol8_data] = data_burst(data_length, T_sim, 1./16);
[pol9, pol9_data] = data_burst(data_length, T_sim, 1./16);
[pol10, pol10_data] = data_burst(data_length, T_sim, 1./16);
[pol11, pol11_data] = data_burst(data_length, T_sim, 1./16);
[pol12, pol12_data] = data_burst(data_length, T_sim, 1./16);
[pol13, pol13_data] = data_burst(data_length, T_sim, 1./16);
[pol14, pol14_data] = data_burst(data_length, T_sim, 1./16);
[pol15, pol15_data] = data_burst(data_length, T_sim, 1./16);
[pol16, pol16_data] = data_burst(data_length, T_sim, 1./16);

input_data = [pol1_data; pol2_data; pol3_data; pol4_data;
             pol5_data; pol6_data; pol7_data; pol8_data;
             pol9_data; pol10_data; pol11_data; pol12_data;
             pol13_data; pol14_data; pol15_data; pol16_data];
%% Simulate
set_param(mdl_name, 'StopTime', num2str(T_sim-1));
sim(mdl_name)

%% Verify
output_start = find(double(sync_out)) + 1;

output_data = [out1.'; out2.'; out3.'; out4.'; out5.'; out6.'; out7.'; out8.';
    out9.'; out10.'; out11.'; out12.'; out13.'; out14.'; out15.'; out16.';];
output_data = output_data(:,output_start:output_start + biplex_fft_length - 1);

error_mat = zeros(n_inputs, data_length);
for k=1:n_inputs
    din_name = sprintf('din%d', k);
    phase_coeffs = exp(-1j*2*pi/(n_inputs*biplex_fft_length)*(0:biplex_fft_length-1)*(k-1));
    error_mat(k,:) = (phase_coeffs .* input_data(k,:)) - output_data(k,:);
end
fprintf('Maximum error (# of bits), %g\n', log2(max(max(abs(error_mat))) / 2^-17))
