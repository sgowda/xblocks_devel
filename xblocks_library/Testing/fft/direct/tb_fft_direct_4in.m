%% Init
clc; clear; close all

mdl_name = 'fft_direct_4in';
eval(mdl_name); % open design

%% Re-draw blocks
FFTSize = 2;
config.source = str2func('fft_direct_init_xblock');
config.toplevel = subblockname(mdl_name, 'fft_direct');
xBlock(config, {config.toplevel, 'FFTSize', FFTSize, ...
    'mult_spec', 2*ones(1, FFTSize), 'map_tail', 0});

%% Generate simulation data
T_sim = 200;
sync = zeros(1, T_sim);
sync(1) = 1;

data_length = 32;

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
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim-1));

% Run simulation
sim(mdl_name)

%% Verify
output_start = find(double(sync_out)) + 1;

output_data = [out1.'; out2.'; out3.'; out4.'];
% out5.'; out6.'; out7.'; out8.';
%     out9.'; out10.'; out11.'; out12.'; out13.'; out14.'; out15.'; out16.';];
% fft(input_data(:,1)) - output_data(:,output_start)


n_inputs = 2^FFTSize;
error_mat = zeros(n_inputs, data_length);
for k=1:data_length
    error_mat(:,k) = fft(input_data(1:n_inputs,k)) - output_data(:,output_start + k -1);
end
fprintf('Maximum error (# of bits), %g\n', log2(max(max(abs(error_mat))) / 2^-17))
