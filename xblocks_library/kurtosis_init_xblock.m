function [] = kurtosis_init_xblock(blk, varargin)
%% Config
defaults = {'acc_len', 15, 'n_inputs', 1};
acc_len = get_var('acc_len', 'defaults', defaults, varargin{:});
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
type_x = fi_dtype(1, 18, 17);

%% Inports
sync_in = xInport('sync_in');
% x_in = xInport('x_in');
x_in = xblock_new_inputs('x', n_inputs, 1);

%% Outports
valid = xOutport('valid');
channel_out = xOutport('channel');
num = xOutport('E[|X-m_x|^4]');
den = xOutport('E[|X-m_x|^2]^2');
abs_X_sq_acc_mean = xOutport('E[||X||^2]');

%% Diagram
origin_moments = xblock_new_bus(9, n_inputs);
origin_moments_acc = xblock_new_bus(9, n_inputs);
origin_moments_acc_rounded = xblock_new_bus(9, n_inputs);

channel = xSignal();
valid_ser = xSignal();
m_x_re = xSignal();
m_x_im = xSignal();
x_sq_re = xSignal();
x_sq_im = xSignal();
absx_sq = xSignal();
absx_4th = xSignal();
x_3rd_re = xSignal();
x_3rd_im = xSignal();

for k =1:n_inputs
    fprintf('Redrawing origin moments\n')
    config.source = @kurtosis_origin_moments_init_xblock;
    config.name = sprintf('kurtosis_origin_moments_%d', k);
    xBlock(config, {[]}, {sync_in, x_in{k}}, {origin_moments{:,k}});
end

origin_moments_flat = {origin_moments{1,1}};
for k=1:n_inputs
    origin_moments_flat = {origin_moments_flat{:}, origin_moments{2:end,k}};
end

fprintf('Redrawing accumulators\n')
config.source = @kurtosis_acc_bank_init_xblock;
config.name = 'kurtosis_acc_bank';
xBlock(config, {[], 'acc_len', 2^acc_len, 'n_inputs', n_inputs}, origin_moments_flat, {valid_ser, m_x_re, m_x_im, x_sq_re, x_sq_im, absx_sq, absx_4th, x_3rd_re, x_3rd_im, channel});

fprintf('Redrawing moment calculators\n')
config.source = @kurtosis_moment_calc_init_xblock;
config.name = 'kurtosis_central_moment_calc';
xBlock(config, {[], 'acc_len', acc_len}, ...
    {valid_ser, channel, m_x_re, m_x_im, x_sq_re, x_sq_im, absx_sq, absx_4th, x_3rd_re, x_3rd_im}, ...
    {valid, channel_out, num, den, abs_X_sq_acc_mean});

% valid.bind(sync_out);
% valid.bind(delay_srl('valid_del', sync_out, 1));

end
