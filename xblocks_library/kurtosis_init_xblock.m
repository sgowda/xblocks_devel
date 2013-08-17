function [] = kurtosis_single_channel_init_xblock(blk, varargin)
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
origin_moments = xblock_new_bus(6, n_inputs);
origin_moments_acc = xblock_new_bus(9, n_inputs);
origin_moments_acc_rounded = xblock_new_bus(9, n_inputs);

for k =1:n_inputs
    % fprintf('Redrawing origin moments\n')
    config.source = @kurtosis_origin_moments_init_xblock;
    config.name = sprintf('kurtosis_origin_moments_%d', k);
    xBlock(config, {[]}, {sync_in, x_in{k}}, {origin_moments{:,k}});

    % fprintf('Redrawing accumulators\n')
    config.source = @kurtosis_acc_bank_init_xblock;
    config.name = sprintf('kurtosis_acc_bank_%d', k);
    xBlock(config, {[], 'acc_len', 2^acc_len}, {origin_moments{:,k}}, {origin_moments_acc{:,k}});

    % fprintf('Redrawing rounding\n')
    config.source = @kurtosis_acc_rounding_init_xblock;
    config.name = sprintf('acc_rounding_%d', k);
    xBlock(config, {[], 'acc_len', acc_len}, {origin_moments_acc{:,k}}, {origin_moments_acc_rounded{:,k}});
end

%--- Draw serializers
ld = delay_srl('load_del', origin_moments_acc_rounded{1,1}, 1);
[m_x_type, x_sq_type, x_3rd_type, x_4th_type] = acc_rounding_types(type_x, acc_len);
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
% m_x
xBlock(struct('source', @kurtosis_data_serializer_init_xblock, 'name', 'm_x_re_ser'), ...
    {[], 'n_inputs', n_inputs, 'bit_width', m_x_type.WordLength, 'bin_pt', m_x_type.FractionLength}, ...
    [{ld}, origin_moments_acc_rounded(2,:)], {channel, m_x_re, valid_ser});
xBlock(struct('source', @kurtosis_data_serializer_init_xblock, 'name', 'm_x_im_ser'), ...
    {[], 'n_inputs', n_inputs, 'bit_width', m_x_type.WordLength, 'bin_pt', m_x_type.FractionLength}, ...
    [{ld}, origin_moments_acc_rounded(3,:)], {[], m_x_im, []});
% x_sq
xBlock(struct('source', @kurtosis_data_serializer_init_xblock, 'name', 'x_sq_re_ser'), ...
    {[], 'n_inputs', n_inputs, 'bit_width', x_sq_type.WordLength, 'bin_pt', x_sq_type.FractionLength}, ...
    [{ld}, origin_moments_acc_rounded(4,:)], {[], x_sq_re, []});
xBlock(struct('source', @kurtosis_data_serializer_init_xblock, 'name', 'x_sq_im_ser'), ...
    {[], 'n_inputs', n_inputs, 'bit_width', x_sq_type.WordLength, 'bin_pt', x_sq_type.FractionLength}, ...
    [{ld}, origin_moments_acc_rounded(5,:)], {[], x_sq_im, []});
% abs
xBlock(struct('source', @kurtosis_data_serializer_init_xblock, 'name', 'absx_sq_re_ser'), ...
    {[], 'n_inputs', n_inputs, 'bit_width', x_sq_type.WordLength, 'bin_pt', x_sq_type.FractionLength}, ...
    [{ld}, origin_moments_acc_rounded(6,:)], {[], absx_sq, []});
xBlock(struct('source', @kurtosis_data_serializer_init_xblock, 'name', 'absx_4th_im_ser'), ...
    {[], 'n_inputs', n_inputs, 'bit_width', x_4th_type.WordLength, 'bin_pt', x_4th_type.FractionLength}, ...
    [{ld}, origin_moments_acc_rounded(7,:)], {[], absx_4th, []});
% x_3rd
xBlock(struct('source', @kurtosis_data_serializer_init_xblock, 'name', 'x_3rd_re_ser'), ...
    {[], 'n_inputs', n_inputs, 'bit_width', x_3rd_type.WordLength, 'bin_pt', x_3rd_type.FractionLength}, ...
    [{ld}, origin_moments_acc_rounded(8,:)], {[], x_3rd_re, []});
xBlock(struct('source', @kurtosis_data_serializer_init_xblock, 'name', 'x_3rd_im_ser'), ...
    {[], 'n_inputs', n_inputs, 'bit_width', x_3rd_type.WordLength, 'bin_pt', x_3rd_type.FractionLength}, ...
    [{ld}, origin_moments_acc_rounded(9,:)], {[], x_3rd_im, []});

% % fprintf('Redrawing moment calculators\n')
% sync_out = xSignal();
config.source = @kurtosis_moment_calc_init_xblock;
config.name = 'kurtosis_central_moment_calc';
xBlock(config, {[], 'acc_len', acc_len}, ...
    {valid_ser, channel, m_x_re, m_x_im, x_sq_re, x_sq_im, absx_sq, absx_4th, x_3rd_re, x_3rd_im}, ...
    {valid, channel_out, num, den, abs_X_sq_acc_mean});

% valid.bind(sync_out);
% valid.bind(delay_srl('valid_del', sync_out, 1));

end
