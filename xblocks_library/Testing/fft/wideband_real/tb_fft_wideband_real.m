clc; clear; close all

mdl_name = 'fft_wideband_real';
eval(mdl_name); % open design

%% Re-draw blocks
% Copy the biplex core over from the biplex testbench
% Copy the phase mult block over (if the FFT length or the precision changes)
% Copy the fft direct over (ONLY if the precision or the parallelism changes)
% Change the shift offset!

%% Generate simulation inputs
T_sim = 20000;
fft_length = 1024;
parallelism = 16;
fft_latency = 500;%160;
n_frames = (floor(T_sim/fft_length) - ceil(fft_latency/fft_length));
data_length = n_frames*fft_length;
[din, din_data] = data_burst_real(data_length, T_sim, 1, 'sample_rate', 1/16);

% [pol1, pol1_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol2, pol2_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol3, pol3_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol4, pol4_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol5, pol5_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol6, pol6_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol7, pol7_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol8, pol8_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol9, pol9_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol10, pol10_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol11, pol11_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol12, pol12_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol13, pol13_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol14, pol14_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol15, pol15_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
% [pol16, pol16_data] = data_burst_real(data_length/parallelism, T_sim, 1./16);
%              
%% Simulate
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim-1));

tic
% Run simulation
sim(mdl_name)
toc
%% verify full computation
biplex_fft_length = fft_length/parallelism;
biplex_output_start = find(double(biplex_sync_out)) + 1;

pol1_data = downsample(din_data, parallelism, 0);
pol2_data = downsample(din_data, parallelism, 1);
pol3_data = downsample(din_data, parallelism, 2);
pol4_data = downsample(din_data, parallelism, 3);
pol5_data = downsample(din_data, parallelism, 4);
pol6_data = downsample(din_data, parallelism, 5);
pol7_data = downsample(din_data, parallelism, 6);
pol8_data = downsample(din_data, parallelism, 7);
pol9_data = downsample(din_data, parallelism, 8);
pol10_data = downsample(din_data, parallelism, 9);
pol11_data = downsample(din_data, parallelism, 10);
pol12_data = downsample(din_data, parallelism, 11);
pol13_data = downsample(din_data, parallelism, 12);
pol14_data = downsample(din_data, parallelism, 13);
pol15_data = downsample(din_data, parallelism, 14);
pol16_data = downsample(din_data, parallelism, 15);

input_data = [pol1_data; pol2_data; pol3_data; pol4_data;
             pol5_data; pol6_data; pol7_data; pol8_data;
             pol9_data; pol10_data; pol11_data; pol12_data;
             pol13_data; pol14_data; pol15_data; pol16_data];

inds = 1:biplex_fft_length;
biplex_bits_lost = zeros(n_frames, 4);
biplex_err = zeros(n_frames, 4);

n_shift_stages = 6;
n_biplex_shifts = 4;
biplex_downshift = 2^n_biplex_shifts;
for k=1:n_frames
    inds_k = inds + (k-1)*biplex_fft_length;
    biplex_err(k, 1) = max_error(biplex_out1(inds_k + biplex_output_start - 1), fft(pol1_data(inds_k)).'/biplex_downshift);
    biplex_bits_lost(k, 1) = bits_lost(biplex_out1(inds_k + biplex_output_start - 1), fft(pol1_data(inds_k)).'/biplex_downshift);
    
    biplex_err(k, 2) = max_error(biplex_out2(inds_k + biplex_output_start - 1), fft(pol2_data(inds_k)).'/biplex_downshift);
    biplex_bits_lost(k, 2) = bits_lost(biplex_out2(inds_k + biplex_output_start - 1), fft(pol2_data(inds_k)).'/biplex_downshift);
    
    biplex_err(k, 3) = max_error(biplex_out3(inds_k + biplex_output_start - 1), fft(pol3_data(inds_k)).'/biplex_downshift);
    biplex_bits_lost(k, 3) = bits_lost(biplex_out3(inds_k + biplex_output_start - 1), fft(pol3_data(inds_k)).'/biplex_downshift);
    
    biplex_err(k, 4) = max_error(biplex_out4(inds_k + biplex_output_start - 1), fft(pol4_data(inds_k)).'/biplex_downshift);
    biplex_bits_lost(k, 4) = bits_lost(biplex_out4(inds_k + biplex_output_start - 1), fft(pol4_data(inds_k)).'/biplex_downshift);
end
max(max(biplex_err))

% check full output
output_start = find(double(sync_out)) + 1;
X = [out1, out2, out3, out4, out5, out6, out7, out8, out9, out10, out11, out12, out13, out14, out15, out16];
full_err = nan(1, n_frames);

for k=1:n_frames
    inds_k = inds + (k-1)*biplex_fft_length;
    X_frame = X(inds_k + output_start - 1, :);
    X_frame = X_frame(:);
    x_input = input_data(:, inds_k);
    X_fl = fft(x_input(:));
    full_err(k) = max(abs(X_frame - X_fl/(2^n_shift_stages)));
end

figure()
hist(log2(full_err/2^-17))

figure()
hold on
plot(abs(X_frame), 'g')
plot(abs(X_fl/(2^n_shift_stages)), 'b')

commandwindow