function mult_35x25_init_xblock(blk, varargin)
%% config
defaults = {'bin_pt', 0};
bin_pt = get_var('bin_pt', 'defaults', defaults, varargin{:});

%% inports
A = xInport('In1');
B = xInport('In2');

%% outports
AB = xOutport('Out1');

%% diagram
% AB_int         = xSignal();
DSP48E_0_p     = xSignal();
DSP48E_0_acout = xSignal();
DSP48E_0_pcout = xSignal();
DSP48E_1_p     = xSignal();
B_msb          = xSignal();
B_lsb          = xSignal();
% prod_lsb       = xSignal();
% prod_msb       = xSignal();
% B_msb_sign_ext = xSignal();

[opmode0, alumode0, carryin0, carryinsel0] = dsp48e_ctrl('ctrl0', '0000101', '0000', '0', '000');
[opmode1, alumode1, carryin1, carryinsel1] = dsp48e_ctrl('ctrl1', '1010101', '0000', '0', '000');

A_sign_ext = trunc_and_wrap('sign_ext', A, 30, 0);

B_int = reinterp_int('as_type_int', B);
B_int_35bit = trunc_and_wrap('convert_B', B_int, 35, 0);

% % block: mult_35x25/mult_35x25_init_xblock/Slice
% Slice = xBlock(struct('source', 'Slice', 'name', 'Slice'), ...
%     struct('nbits', 18, ...
%     'mode', 'Lower Bit Location + Width', ...
%     'bit0', 17), ...
%     {B_int_35bit}, ...
%     {B_msb});
% 
% % block: mult_35x25/mult_35x25_init_xblock/Slice1
% Slice1 = xBlock(struct('source', 'Slice', 'name', 'Slice1'), ...
%     struct('nbits', 17, ...
%     'mode', 'Lower Bit Location + Width'), ...
%     {B_int_35bit}, ...
%     {B_lsb});

B_slices = slice_partition('B_slice', B_int_35bit, [17, 18]);
B_lsb = B_slices{1};
B_msb = B_slices{2};
B_msb_sign_ext = trunc_and_wrap('covnert_B1', B_msb, 18, 0);
B_lsb_sign_ext = trunc_and_wrap('convert_B2', B_lsb, 18, 0);

B_msb_sign_ext_del = delay_srl('del1', B_msb_sign_ext, 1);

% block: mult_35x25/mult_35x25_init_xblock/DSP48E_0
DSP48E_0 = xBlock(struct('source', 'DSP48E', 'name', 'DSP48E_0'), ...
    struct('use_acout', 'on', ...
    'use_pcout', 'on', ...
    'pipeline_a', '2', ...
    'pipeline_b', '2'), ...
    {A_sign_ext, B_lsb_sign_ext, opmode0, alumode0, carryin0, carryinsel0}, ...
    {DSP48E_0_p, DSP48E_0_acout, DSP48E_0_pcout});

% block: mult_35x25/mult_35x25_init_xblock/DSP48E_1
DSP48E_1 = xBlock(struct('source', 'DSP48E', 'name', 'DSP48E_1'), ...
    struct('use_a', 'Cascaded from ACIN Port', ...
    'use_pcin', 'on', ...
    'pipeline_a', '2', ...
    'pipeline_b', '2'), ...
    {DSP48E_0_acout, B_msb_sign_ext_del, DSP48E_0_pcout, opmode1, alumode1, carryin1, carryinsel1}, ...
    {DSP48E_1_p});

prod_lsb = slice_off_bottom('Slice2', DSP48E_0_p, 17);
prod_msb = slice_off_bottom('Slice3', DSP48E_1_p, 43);

AB_int_lsb     = reinterp_uint('reinterp_lsb', prod_lsb);
AB_int_lsb_del = delay_srl('del2', AB_int_lsb, 1);
AB_int_msb     = reinterp_uint('reinterp_msb', prod_msb);
AB_int         = concatenate('concat', {AB_int_msb, AB_int_lsb_del});
AB_sig         = reinterpret('reinterp_prod', AB_int, fi_dtype(1, 60, bin_pt));
AB.bind(AB_sig);
