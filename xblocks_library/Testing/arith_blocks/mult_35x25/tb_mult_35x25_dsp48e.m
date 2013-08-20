clc; close all; clear
mdl_name = 'mult_35x25_dsp48e';
eval(mdl_name);

%% Generate simulation signals
T_sim = 10000;

bin_pt_a = 3;
bin_pt_b = 4;

a_data = randi([-2^34, 2^34-1], [1, T_sim])/2^bin_pt_a;
b_data = randi([-2^24, 2^24-1], [1, T_sim])/2^bin_pt_b;

a = timeseries(a_data);
b = timeseries(b_data);

set_param(subblockname(mdl_name, 'a'), 'bin_pt', num2str(bin_pt_a));
set_param(subblockname(mdl_name, 'b'), 'bin_pt', num2str(bin_pt_b));

config.source = @mult_35x25_init_xblock;
config.toplevel = subblockname(mdl_name, 'mult_35x25');
xBlock(config, {config.toplevel, 'bin_pt_a', bin_pt_a, 'bin_pt_b', bin_pt_b});

%% Simulate
set_param(mdl_name, 'StopTime', num2str(T_sim - 1));
sim(mdl_name)

%% Verify
ab_true = double((int64(a_data * 2^bin_pt_a) .* int64(b_data * 2^bin_pt_b))') / 2^(bin_pt_a + bin_pt_b);
ab = double(ab);

% ab_true = a_fi .* b_fi;
fprintf('Quant error on a: %d\n', ~all(a_data - a_fi' == 0))
fprintf('Quant error on b: %d\n', ~all(b_data - b_fi' == 0))

if all(ab_true(1:end-5) == ab(6:end))
    fprintf('Pass\n')
else
    fprintf('Fail\n');
end
   
error = ab_true(1:end-5) - ab(6:end);

broken_inds = find(~(ab_true(1:end-5) == ab(6:end)));