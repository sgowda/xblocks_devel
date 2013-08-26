clc; clear; close all

mdl_name = 'addsub_96bit_dsp48e';
eval(mdl_name); % open design

%% Re-draw blocks
bit_width_a = 70;
bin_pt_a = bit_width_a - 1;

bit_width_b = 70;
bin_pt_b = bit_width_b - 1;

mode = 'Subtraction';
config.source = @addsub_96bit_dsp48e_init_xblock;
config.toplevel = subblockname(mdl_name, 'addsub');
xBlock(config, {[], 'bit_width_a', bit_width_a, 'bin_pt_a', bin_pt_a, ...
    'bit_width_b', bit_width_b, 'bin_pt_b', bin_pt_b, 'mode', mode});

set_param(subblockname(mdl_name, 'a'), 'n_bits', num2str(bit_width_a), 'bin_pt', num2str(bin_pt_a))
set_param(subblockname(mdl_name, 'b'), 'n_bits', num2str(bit_width_b), 'bin_pt', num2str(bin_pt_b))

%% Generate simulation inputs
T_sim = 1000;
a = data_burst_real(T_sim-10, T_sim, 1);
b = data_burst_real(T_sim-10, T_sim, 1);

%% Simulate
% Set simulation time
set_param(mdl_name, 'StopTime', num2str(T_sim-1));

% Run simulation
sim(mdl_name)

%% Verify
if strcmp(mode, 'Addition')
    sum_fi = a_fi + b_fi;
else % subtraction
    sum_fi = a_fi - b_fi;
end
sum_error = sum_fi(1:end-3) - double(ab_fi(4:end));
pass = max(abs(sum_error)) == 0
bits = [bit17, bit47, bit65, bit67];

% check that all the b inputs get random bits, i.e. the full range of
% possible inputs is being tested
all_sl_rand = all(~all(bits == 0) == 1) && all(~all(bits == 1) == 1)