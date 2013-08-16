clear; clc; close all;
mdl_name = 'twiddle_stage_2_negate_mux';
eval(mdl_name)

latency = 3;

%% Re-draw block
config.source = @negate_mux_init_xblock;
config.toplevel = subblockname(mdl_name, 'negate_mux');
xBlock(config, {config.toplevel, 1, 18, 17});
% negate_mux_init_xblock(blk, mux_latency, input_bit_width, input_bin_pt)

%% Generate simulation data
T_sim = 100;

sel_data = [ones(1, T_sim/2), zeros(1, T_sim/2)];
sel = timeseries(sel_data, 0:T_sim-1);
b_re_data = (rand(1, T_sim)*2-1)/4;
b_re = timeseries(b_re_data, 0:T_sim-1);
b_im_data = (rand(1, T_sim)*2-1)/4;
b_im = timeseries(b_im_data, 0:T_sim-1);

%% Simulate
set_param(mdl_name, 'StopTime', num2str(T_sim - 1));
sim(mdl_name)

%% Verify
bw_im_true = zeros(1,T_sim);
for k=1:T_sim;
    if sel_data(k) == 1
        bw_im_true(k) = -b_re_data(k);
    else
        bw_im_true(k) = b_im_data(k);
    end
end

data_mat = [b_re_data', b_im_data', bw_im_true', bw_im, sel_data'];
error = bw_im(latency + 1:end) - bw_im_true(1:end-latency)';
fprintf('max(abs(error)) = %g\n', max(abs(error)))