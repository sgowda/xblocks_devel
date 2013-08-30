%% Testbench for radix-2 butterfly
clear; clc; close all

mdl_name = 'butterfly';
eval(mdl_name) % open design

mult_latency = 2;
add_latency = 1;
conv_latency = 1;
mux_latency = 1;

coeff_bit_width = 18;
coeff_bin_pt = 17;
input_bit_width = 18;
input_bin_pt = 17;
bin_pt = 17;

T_sim = 2000;
data_len = T_sim-10;

t = 0:T_sim;

a_real = (rand(1, data_len)*2-1)/4;
a_imag = (rand(1, data_len)*2-1)/4;
b_real = (rand(1, data_len)*2-1)/4;
b_imag = (rand(1, data_len)*2-1)/4;
w_real = (rand(1, data_len)*2-1)/4;
w_imag = (rand(1, data_len)*2-1)/4;
w_mag = sqrt(w_real.^2 + w_imag.^2);
w_real = w_real./w_mag;
w_imag = w_imag./w_mag;

a_data = complex(a_real, a_imag);
b_data = complex(b_real, b_imag);
w_data = complex(w_real, w_imag);

a = construct_sim_timeseries(a_data, T_sim);
b = construct_sim_timeseries(b_data, T_sim);
w = construct_sim_timeseries(w_data, T_sim);

%% Re-draw test block
config.source = str2func('fft_butterfly_init_xblock');
config.toplevel = subblockname(mdl_name, 'butterfly');

xBlock(config, {config.toplevel, 'mult_latency', mult_latency, ...
    'add_latency', add_latency, 'conv_latency', conv_latency, 'mux_latency', mux_latency})

%% Simulate
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim - 1));

sim(mdl_name)

%% Verify
delay = mult_latency + add_latency + conv_latency + add_latency + mux_latency + conv_latency;
start = delay + 1;
sync_valid = sync_out(delay + 1) == 1;
fprintf('Sync valid: %d\n', sync_valid);

apbw_fl = a_data + b_data.*w_data;
ambw_fl = a_data - b_data.*w_data;

max(abs(apbw(start + 1:start+data_len) - apbw_fl.'))
max(abs(ambw(start + 1:start+data_len) - ambw_fl.'))

% Check against fixed-point butterfly function
a_re = fi(real(a_fi), 1, 18, 17);
a_im = fi(imag(a_fi), 1, 18, 17);
b_re = fi(real(b_fi), 1, 18, 17);
b_im = fi(imag(b_fi), 1, 18, 17);
w_re = fi(real(w_fi), 1, 18, 17);
w_im = fi(imag(w_fi), 1, 18, 17);

for k=1:length(a_re)
    [apbw_re(k), apbw_im(k), ambw_re(k), ambw_im(k)] = ...
        butterfly_fi(a_re(k), a_im(k), b_re(k), b_im(k), w_re(k), w_im(k));
end

delay = find(double(sync_out));
apbw_fn = double(apbw_re(1:end-delay+1)) + 1j*double(apbw_im(1:end-delay+1));
function_matches_block = all(apbw_fn.' == apbw(delay:end)) && all(ambw_fn.' == ambw(delay:end))

ambw_fn = double(ambw_re(1:end-delay+1)) + 1j*double(ambw_im(1:end-delay+1));


commandwindow