%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu
%   %
%   Copyright (C) 2011 Suraj Gowda, Hong Chen                                 %
%                                                                             %
%   This program is free software; you can redistribute it and/or modify      %
%   it under the terms of the GNU General Public License as published by      %
%   the Free Software Foundation; either version 2 of the License, or         %
%   (at your option) any later version.                                       %
%                                                                             %
%   This program is distributed in the hope that it will be useful,           %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of            %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             %
%   GNU General Public License for more details.                              %
%                                                                             %
%   You should have received a copy of the GNU General Public License along   %
%   with this program; if not, write to the Free Software Foundation, Inc.,   %
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.               %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function simd_add_dsp48e_init_xblock(blk, varargin)

defaults = {'mode', 'Addition', ...
    'n_bits_a', 18, ...
    'bin_pt_a', 17, ...
    'n_bits_b', 18, ...
    'bin_pt_b', 17, ...
    'full_precision', 1, ...
    'n_bits_c', 19, ...
    'bin_pt_c', 17, ...
    'quantization', 'Truncate', ...
    'overflow', 'Wrap', ...
    'cast_latency', 0, ...
    'accept_pcin', 0 ...
    };

mode = get_var('mode', 'defaults', defaults, varargin{:});
n_bits_a = get_var('n_bits_a', 'defaults', defaults, varargin{:});
bin_pt_a = get_var('bin_pt_a', 'defaults', defaults, varargin{:});
n_bits_b = get_var('n_bits_b', 'defaults', defaults, varargin{:});
bin_pt_b = get_var('bin_pt_b', 'defaults', defaults, varargin{:});
full_precision = get_var('full_precision', 'defaults', defaults, varargin{:});
n_bits_c = get_var('n_bits_c', 'defaults', defaults, varargin{:});
bin_pt_c = get_var('bin_pt_c', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});
cast_latency = get_var('cast_latency', 'defaults', defaults, varargin{:});
accept_pcin = get_var('accept_pcin', 'defaults', defaults, varargin{:});

% if(~exist('accept_pcin'))
%     accept_pcin=0;
% end

% Determine addition or subtraction mode
if strcmp(mode, 'Addition'),
    % 	alumode = 0;
    alumode = '0000';
elseif strcmp(mode, 'Subtraction'),
    % 	alumode = 3;
    alumode = '0011';
else
    errordlg('Invalid add/sub mode.');
    return
end

if (n_bits_a < 1),
    errordlg([blk, ': Input ''a'' bit width must be greater than 0.']);
    return
end

if (n_bits_b < 1),
    errordlg([blk, ': Input ''b'' bit width must be greater than 0.']);
    return
end

if (bin_pt_a < 0),
    errordlg([blk, ': Input ''a'' binary point must be greater than 0.']);
    return
end

if (bin_pt_b < 0),
    errordlg([blk, ': Input ''b'' binary point must be greater than 0.']);
    return
end

if (bin_pt_a > n_bits_a),
    errordlg([blk, ': Input ''a'' binary point cannot exceed bit width.']);
    return
end

if (bin_pt_b > n_bits_b),
    errordlg([blk, ': Input ''b'' binary point cannot exceed bit width.']);
    return
end

%% inports
a_re = xInport('a_re');
a_im = xInport('a_im');
b_re = xInport('b_re');
b_im = xInport('b_im');

if accept_pcin
    pcin = xInport('pcin');
end
%% outports
c_re = xOutport('c_re');
c_im = xOutport('c_im');

%% diagram

% block: dsp48e_pfb_test3/caddsub_dsp48e/DSP48E
Reinterpret_A_out1 = xSignal;
Reinterpret_B_out1 = xSignal;
Reinterpret_C_out1 = xSignal;
opmode_out1 = xSignal;
alumode_out1 = xSignal;
carryin_out1 = xSignal;
carryinsel_out1 = xSignal;
DSP48E_out1 = xSignal;
slice_c_im_out1 = xSignal;
realign_b_re_out1 = xSignal;
realign_a_re_out1 = xSignal;
realign_a_im_out1 = xSignal;
reinterp_a_re_out1 = xSignal;
reinterp_c_re_out1 = xSignal;
reinterp_c_im_out1 = xSignal;
concat_b_out1 = xSignal;
concat_a_out1 = xSignal;
Slice_B_out1 = xSignal;
Slice_A_out1 = xSignal;
reinterp_a_im_out1 = xSignal;
reinterp_b_re_out1 = xSignal;
reinterp_b_im_out1 = xSignal;
realign_b_im_out1 = xSignal;
slice_c_re_out1 = xSignal;

% dsp48e_op = xSignal('dsp48e_op');
opmode = xSignal;
alumode_sig = xSignal;
carryin = xSignal;
carryinsel = xSignal;

max_non_frac = max(n_bits_a - bin_pt_a, n_bits_b - bin_pt_b);
max_bin_pt = max(bin_pt_a, bin_pt_b);
bin_pt_tmp = 24 - (max_non_frac + 2);

if full_precision
    n_bits_out = max_non_frac + max_bin_pt + 1;
    bin_pt_out = max_bin_pt;
else
    n_bits_out = n_bits_c;
    bin_pt_out = bin_pt_c;
end

% Validate derived values.

if (n_bits_out > 24),
    errordlg([blk, ': Output bit width cannot exceed 24 bits real/imag. ', ...
        'Current settings require ', num2str(n_bits_out), ' bits.']);
    return
end

if(accept_pcin == 0)
    DSP48E = xBlock(struct('source', 'DSP48E', 'name', 'DSP48E'), ...
        struct('use_creg', 'on'), ...
        {Reinterpret_A_out1, Reinterpret_B_out1, Reinterpret_C_out1, opmode, alumode_sig, carryin, carryinsel}, ...
        {DSP48E_out1});
else
    DSP48E = xBlock(struct('source', 'DSP48E', 'name', 'DSP48E'), ...
        struct('use_creg', 'on', 'use_pcin', 'on'), ...
        {Reinterpret_A_out1, Reinterpret_B_out1, Reinterpret_C_out1, pcin, opmode, alumode_sig, carryin, carryinsel}, ...
        {DSP48E_out1});
end
% block: dsp48e_pfb_test3/caddsub_dsp48e/Reinterpret_A
Reinterpret_A = xBlock(struct('source', 'Reinterpret', 'name', 'Reinterpret_A'), ...
    struct('force_arith_type', 'on', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'force_bin_pt', 'on'), ...
    {Slice_A_out1}, ...
    {Reinterpret_A_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/Reinterpret_B
Reinterpret_B = xBlock(struct('source', 'Reinterpret', 'name', 'Reinterpret_B'), ...
    struct('force_arith_type', 'on', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'force_bin_pt', 'on'), ...
    {Slice_B_out1}, ...
    {Reinterpret_B_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/Reinterpret_C
Reinterpret_C = xBlock(struct('source', 'Reinterpret', 'name', 'Reinterpret_C'), ...
    struct('force_arith_type', 'on', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'force_bin_pt', 'on'), ...
    {concat_a_out1}, ...
    {Reinterpret_C_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/Slice_A
Slice_A = xBlock(struct('source', 'Slice', 'name', 'Slice_A'), ...
    struct('nbits', 30), ...
    {concat_b_out1}, ...
    {Slice_A_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/Slice_B
Slice_B = xBlock(struct('source', 'Slice', 'name', 'Slice_B'), ...
    struct('nbits', 18, ...
    'mode', 'Lower Bit Location + Width'), ...
    {concat_b_out1}, ...
    {Slice_B_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/alumode


% alumode_blk = xBlock(struct('source', 'Constant', 'name', 'alumode'), ...
%                         struct('arith_type', 'Unsigned', ...
%                                'const', alumode, ...
%                                'n_bits', 4, ...
%                                'bin_pt', 0), ...
%                         {}, ...
%                         {alumode_out1});
%
% % block: dsp48e_pfb_test3/caddsub_dsp48e/carryin
% carryin = xBlock(struct('source', 'Constant', 'name', 'carryin'), ...
%                         struct('arith_type', 'Unsigned', ...
%                                'const', 0, ...
%                                'n_bits', 1, ...
%                                'bin_pt', 0), ...
%                         {}, ...
%                         {carryin_out1});
%
% % block: dsp48e_pfb_test3/caddsub_dsp48e/carryinsel
% carryinsel = xBlock(struct('source', 'Constant', 'name', 'carryinsel'), ...
%                            struct('arith_type', 'Unsigned', ...
%                                   'const', 0, ...
%                                   'n_bits', 3, ...
%                                   'bin_pt', 0), ...
%                            {}, ...
%                            {carryinsel_out1});

dsp48e_op_gen = xBlock(struct('source', 'dsp48e_ctrl_init_xblock', 'name', 'dsp48e_op_gen'), ...
    {[blk, '/dsp48e_op_gen'], 'opmode', '0110011', 'alumode', alumode,  'consolidate_ports', 0}, ...
    {}, {opmode, alumode_sig, carryin, carryinsel});


% block: dsp48e_pfb_test3/caddsub_dsp48e/cast_c_im
cast_c_im = xBlock(struct('source', 'Convert', 'name', 'cast_c_im'), ...
    struct('n_bits', n_bits_out, ...
    'bin_pt', bin_pt_out, ...
    'pipeline', 'on', ...
    'quantization', quantization, ...
    'overflow', overflow, ...
    'latency', cast_latency), ...
    {reinterp_c_im_out1}, ...
    {c_im});

% block: dsp48e_pfb_test3/caddsub_dsp48e/cast_c_re
cast_c_re = xBlock(struct('source', 'Convert', 'name', 'cast_c_re'), ...
    struct('n_bits', n_bits_out, ...
    'bin_pt', bin_pt_out, ...
    'pipeline', 'on', ...
    'quantization', quantization, ...
    'overflow', overflow, ...
    'latency', cast_latency), ...
    {reinterp_c_re_out1}, ...
    {c_re});

% block: dsp48e_pfb_test3/caddsub_dsp48e/concat_a
concat_a = xBlock(struct('source', 'Concat', 'name', 'concat_a'), ...
    [], ...
    {reinterp_a_re_out1, reinterp_a_im_out1}, ...
    {concat_a_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/concat_b
concat_b = xBlock(struct('source', 'Concat', 'name', 'concat_b'), ...
    [], ...
    {reinterp_b_re_out1, reinterp_b_im_out1}, ...
    {concat_b_out1});

% % block: dsp48e_pfb_test3/caddsub_dsp48e/opmode
% opmode = xBlock(struct('source', 'Constant', 'name', 'opmode'), ...
%                        struct('arith_type', 'Unsigned', ...
%                               'const', 51, ...
%                               'n_bits', 7, ...
%                               'bin_pt', 0), ...
%                        {}, ...
%                        {opmode_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/realign_a_im
realign_a_im = xBlock(struct('source', 'Convert', 'name', 'realign_a_im'), ...
    struct('n_bits', 24, ...
    'bin_pt', bin_pt_tmp, ...
    'pipeline', 'on'), ...
    {a_im}, ...
    {realign_a_im_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/realign_a_re
realign_a_re = xBlock(struct('source', 'Convert', 'name', 'realign_a_re'), ...
    struct('n_bits', 24, ...
    'bin_pt', bin_pt_tmp, ...
    'pipeline', 'on'), ...
    {a_re}, ...
    {realign_a_re_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/realign_b_im
realign_b_im = xBlock(struct('source', 'Convert', 'name', 'realign_b_im'), ...
    struct('n_bits', 24, ...
    'bin_pt', bin_pt_tmp, ...
    'pipeline', 'on'), ...
    {b_im}, ...
    {realign_b_im_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/realign_b_re
realign_b_re = xBlock(struct('source', 'Convert', 'name', 'realign_b_re'), ...
    struct('n_bits', 24, ...
    'bin_pt', bin_pt_tmp, ...
    'pipeline', 'on'), ...
    {b_re}, ...
    {realign_b_re_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/reinterp_a_im
reinterp_a_im = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_a_im'), ...
    struct('force_arith_type', 'on', ...
    'force_bin_pt', 'on'), ...
    {realign_a_im_out1}, ...
    {reinterp_a_im_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/reinterp_a_re
reinterp_a_re = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_a_re'), ...
    struct('force_arith_type', 'on', ...
    'force_bin_pt', 'on'), ...
    {realign_a_re_out1}, ...
    {reinterp_a_re_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/reinterp_b_im
reinterp_b_im = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_b_im'), ...
    struct('force_arith_type', 'on', ...
    'force_bin_pt', 'on'), ...
    {realign_b_im_out1}, ...
    {reinterp_b_im_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/reinterp_b_re
reinterp_b_re = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_b_re'), ...
    struct('force_arith_type', 'on', ...
    'force_bin_pt', 'on'), ...
    {realign_b_re_out1}, ...
    {reinterp_b_re_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/reinterp_c_im
reinterp_c_im = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_c_im'), ...
    struct('force_arith_type', 'on', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'force_bin_pt', 'on', ...
    'bin_pt', bin_pt_tmp), ...
    {slice_c_im_out1}, ...
    {reinterp_c_im_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/reinterp_c_re
reinterp_c_re = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_c_re'), ...
    struct('force_arith_type', 'on', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'force_bin_pt', 'on', ...
    'bin_pt', bin_pt_tmp), ...
    {slice_c_re_out1}, ...
    {reinterp_c_re_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/slice_c_im
slice_c_im = xBlock(struct('source', 'Slice', 'name', 'slice_c_im'), ...
    struct('nbits', 24, ...
    'mode', 'Lower Bit Location + Width'), ...
    {DSP48E_out1}, ...
    {slice_c_im_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/slice_c_re
slice_c_re = xBlock(struct('source', 'Slice', 'name', 'slice_c_re'), ...
    struct('nbits', 24, ...
    'mode', 'Lower Bit Location + Width', ...
    'bit0', 24), ...
    {DSP48E_out1}, ...
    {slice_c_re_out1});


% if ~isempty(blk) && ~strcmp(blk(1),'/')
%     clean_blocks(blk);
%     annotation_fmt = '%d_%d + %d_%d ==> %d_%d\nMode=%s\nLatency=%d';
%     annotation = sprintf(annotation_fmt, ...
%       n_bits_a, bin_pt_a, ...
%       n_bits_b, bin_pt_b, ...
%       n_bits_out, bin_pt_out, ...
%       mode, 2+cast_latency);
%     set_param(blk, 'AttributesFormatString', annotation);
% end


end

