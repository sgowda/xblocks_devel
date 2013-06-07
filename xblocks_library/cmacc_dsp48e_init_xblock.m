%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %
%   Copyright (C) 2011 Suraj Gowda  Hong Chen                                 %
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
function cmacc_dsp48e_init_xblock(blk, n_bits_a, bin_pt_a, n_bits_b, bin_pt_b, conjugated, ...
    full_precision, n_bits_c, bin_pt_c, quantization, overflow, cast_latency)
% cmacc_dsp48e_init_xblock
% Computes a*b+c in 4 DSP48e slices, where a,b,c are complex numbers

% Validate input fields.
% Initialization script
if (n_bits_a < 1),
    disp([gcb,': Input ''a'' bit width must be greater than 0.']);
    return
end

if (n_bits_b < 1),
    disp([gcb, ': Input ''b'' bit width must be greater than 0.']);
    return
end

if (n_bits_c < 1),
    disp([gcb, ': Output ''c'' bit width must be greater than 0.']);
    return
end

if (n_bits_a > 25),
    disp([gcb, ': Input ''a'' bit width cannot exceed 25.']);
    return
end

if (n_bits_b > 18),
    disp([gcb, ': Input ''b'' bit width cannot exceed 18.']);
    return
end

if (bin_pt_a < 0),
    disp([gcb, ': Input ''a'' binary point must be greater than 0.']);
    return
end

if (bin_pt_b < 0),
    disp([gcb, ': Input ''b'' binary point must be greater than 0.']);
    return
end

if (bin_pt_c < 0),
    disp([gcb, ': Output ''c'' binary point must be greater than 0.']);
    return
end

if (bin_pt_a > n_bits_a),
    disp([gcb, ': Input ''a'' binary point cannot exceed bit width.']);
    return
end

if (bin_pt_b > n_bits_b),
    disp([gcb, ': Input ''b'' binary point cannot exceed bit width.']);
    return
end

if (bin_pt_c > n_bits_c),
    disp([gcb, ': Output ''c'' binary point cannot exceed bit width.']);
    return
end

bin_pt_reinterp = bin_pt_a + bin_pt_b;
if strcmp(full_precision, 'on'),
    n_bits_out = n_bits_a + n_bits_b + 1;
    bin_pt_out = bin_pt_a + bin_pt_b;
else
    n_bits_out = n_bits_c;
    bin_pt_out = bin_pt_c;
end


%% inports
a_re = xInport('a_re');
a_im = xInport('a_im');
b_re = xInport('b_re');
b_im = xInport('b_im');
c_re = xInport('c_re');
c_im = xInport('c_im');

%% outports
d_re = xOutport('d_re');
d_im = xOutport('d_im');

%% Signals
realign_a_re_out1 = xSignal;
realign_b_im_out1 = xSignal;

c_re_del = xSignal;
c_re_align = xSignal;
c_re_reinterp = xSignal;
c_re_dsp_in = xSignal;
c_im_del = xSignal;
c_im_align = xSignal;
c_im_reinterp = xSignal;
c_im_dsp_in = xSignal;
reinterp_a_im_out1 = xSignal;
Convert_out1 = xSignal;
DSP48E_0_out1 = xSignal;
DSP48E_0_out2 = xSignal;
DSP48E_1_out1 = xSignal;
DSP48E_2_out1 = xSignal;
DSP48E_2_out2 = xSignal;
DSP48E_3_out1 = xSignal;
reinterp_d_im_out1 = xSignal;
reinterp_d_re_out1 = xSignal;
realign_a_im_out1 = xSignal;
realign_b_re_out1 = xSignal;
Convert7_out1 = xSignal;
dsp48e0_op = xSignal('dsp48e0_op');
dsp48e1_op = xSignal('dsp48e1_op');
dsp48e2_op = xSignal('dsp48e2_op');
dsp48e3_op = xSignal('dsp48e3_op');
Convert5_out1 = xSignal;
Convert6_out1 = xSignal;
reinterp_b_re_out1 = xSignal;
Convert4_out1 = xSignal;
reinterp_b_im_out1 = xSignal;
Convert3_out1 = xSignal;
reinterp_a_re_out1 = xSignal;
Convert1_out1 = xSignal;
Convert2_out1 = xSignal;

del_c_re = xBlock( struct('source', 'Delay', 'name', 'del_c_re'), struct('latency', 1), {c_re}, {c_re_del});
realign_c_re = xBlock(struct('source', 'Convert', 'name', 'realign_c_re'), ...
    struct('n_bits', bin_pt_reinterp + (n_bits_a-bin_pt_a), 'bin_pt', bin_pt_reinterp, 'pipeline', 'on'), ...
    {c_re_del}, {c_re_align});

xBlock(struct('source', 'dsp48e_input_cast_init_xblock', 'name', 'dsp48e_cast2c'), ...
    {[blk, '/dsp48e_cast2c'], 'input_port', 'c'}, {c_re_align}, {c_re_dsp_in});

del_c_im = xBlock( struct('source', 'Delay', 'name', 'del_c_im'), struct('latency', 1), {c_im}, {c_im_del});
realign_c_im = xBlock(struct('source', 'Convert', 'name', 'realign_c_im'), ...
    struct('n_bits', bin_pt_reinterp + (n_bits_a-bin_pt_a), 'bin_pt', bin_pt_reinterp, 'pipeline', 'on'), ...
    {c_im_del}, {c_im_align});

xBlock(struct('source', 'dsp48e_input_cast_init_xblock', 'name', 'dsp48e_cast0c'), ...
    {[blk, '/dsp48e_cast0c'], 'input_port', 'c'}, {c_im_align}, {c_im_dsp_in});

xBlock(struct('source', 'dsp48e_input_cast_init_xblock', 'name', 'dsp48e_cast2a'), ...
    {[blk, '/dsp48e_cast2a'], 'input_port', 'a'}, {realign_a_im_out1}, {Convert_out1});

xBlock(struct('source', 'dsp48e_input_cast_init_xblock', 'name', 'dsp48e_cast0a'), ...
    {[blk, '/dsp48e_cast0a'], 'input_port', 'a'}, {realign_a_im_out1}, {Convert1_out1});

xBlock(struct('source', 'dsp48e_input_cast_init_xblock', 'name', 'dsp48e_cast3a'), ...
    {[blk, '/dsp48e_cast3a'], 'input_port', 'a'}, {realign_a_re_out1}, {Convert2_out1});

xBlock(struct('source', 'dsp48e_input_cast_init_xblock', 'name', 'dsp48e_cast2b'), ...
    {[blk, '/dsp48e_cast2b'], 'input_port', 'b'}, {realign_b_im_out1}, {Convert3_out1});

xBlock(struct('source', 'dsp48e_input_cast_init_xblock', 'name', 'dsp48e_cast3b'), ...
    {[blk, '/dsp48e_cast3b'], 'input_port', 'b'}, {realign_b_re_out1}, {Convert4_out1});

xBlock(struct('source', 'dsp48e_input_cast_init_xblock', 'name', 'dsp48e_cast1a'), ...
    {[blk, '/dsp48e_cast1a'], 'input_port', 'a'}, {realign_a_re_out1}, {Convert5_out1});

xBlock(struct('source', 'dsp48e_input_cast_init_xblock', 'name', 'dsp48e_cast0b'), ...
    {[blk, '/dsp48e_cast0b'], 'input_port', 'b'}, {realign_b_re_out1}, {Convert6_out1});

xBlock(struct('source', 'dsp48e_input_cast_init_xblock', 'name', 'dsp48e_cast1b'), ...
    {[blk, '/dsp48e_cast1b'], 'input_port', 'b'}, {realign_b_im_out1}, {Convert7_out1});

%---- DSP48E opcodes
dsp48e0_op_gen = xBlock(struct('source', 'dsp48e_ctrl_init_xblock', 'name', 'dsp48e0_op_gen'), ...
    {[blk, '/dsp48e0_op_gen'], 'opmode', '0110101'}, {}, {dsp48e0_op});

dsp48e1_op_gen = xBlock(struct('source', 'dsp48e_ctrl_init_xblock', 'name', 'dsp48e1_op_gen'), ...
    {[blk, '/dsp48e1_op_gen'], 'opmode', '0010101'}, {}, {dsp48e1_op});

dsp48e2_op_gen = xBlock(struct('source', 'dsp48e_ctrl_init_xblock', 'name', 'dsp48e2_op_gen'), ...
    {[blk, '/dsp48e2_op_gen'], 'opmode', '0110101', 'alumode', '0011'}, {}, {dsp48e2_op});

dsp48e3_op_gen = xBlock(struct('source', 'dsp48e_ctrl_init_xblock', 'name', 'dsp48e3_op_gen'), ...
    {[blk, '/dsp48e3_op_gen'], 'opmode', '0010101'}, {}, {dsp48e3_op});


%---- DSP slices
DSP48E_0 = xBlock(struct('source', 'DSP48E', 'name', 'DSP48E_0'), ...
    struct('use_pcout', 'on', 'use_creg', 'on', 'use_op', 'on'), ...
    {Convert1_out1, Convert6_out1, c_im_dsp_in, dsp48e0_op}, ...
    {DSP48E_0_out1, DSP48E_0_out2});


DSP48E_1 = xBlock(struct('source', 'DSP48E', 'name', 'DSP48E_1'), ...
    struct('use_pcin', 'on', ...
    'pipeline_a', '2', ...
    'pipeline_b', '2', 'use_op', 'on'), ...
    {Convert5_out1, Convert7_out1, DSP48E_0_out2, dsp48e1_op}, ...
    {DSP48E_1_out1});

% block: twiddle_dsp48e_test/twiddle_general_dsp48e/cmult/DSP48E_2
DSP48E_2 = xBlock(struct('source', 'DSP48E', 'name', 'DSP48E_2'), ...
    struct('use_pcout', 'on', 'use_creg', 'on', 'use_op', 'on'), ...
    {Convert_out1, Convert3_out1, c_re_dsp_in, dsp48e2_op}, ...
    {DSP48E_2_out1, DSP48E_2_out2});

% block: twiddle_dsp48e_test/twiddle_general_dsp48e/cmult/DSP48E_3
%NOTE: THERE IS A PURPOSE TO THIS 'PCOUT'.  DO NOT REMOVE -- RYAN MONROE
DSP48E_3 = xBlock(struct('source', 'DSP48E', 'name', 'DSP48E_3'), ...
    struct('use_pcin', 'on', ...
    'pipeline_a', '2', ...
    'pipeline_b', '2', 'use_op', 'on'), ...
    {Convert2_out1, Convert4_out1, DSP48E_2_out2, dsp48e3_op}, ...
    {DSP48E_3_out1});

% block: twiddle_dsp48e_test/twiddle_general_dsp48e/cmult/cast_d_im
cast_d_im = xBlock(struct('source', 'Convert', 'name', 'cast_d_im'), ...
    struct('n_bits', n_bits_out, ...
    'bin_pt', bin_pt_out, ...
    'latency', cast_latency, ...
    'quantization', quantization, 'overflow', overflow, ...
    'pipeline', 'on'), ...
    {reinterp_d_im_out1}, ...
    {d_im});

% block: twiddle_dsp48e_test/twiddle_general_dsp48e/cmult/cast_d_re
cast_d_re = xBlock(struct('source', 'Convert', 'name', 'cast_d_re'), ...
    struct('n_bits', n_bits_out, ...
    'bin_pt', bin_pt_out, ...
    'latency', cast_latency, ...
    'quantization', quantization, 'overflow', overflow, ...
    'pipeline', 'on'), ...
    {reinterp_d_re_out1}, ...
    {d_re});

% block: twiddle_dsp48e_test/twiddle_general_dsp48e/cmult/realign_a_im
realign_a_im = xBlock(struct('source', 'Convert', 'name', 'realign_a_im'), ...
    struct('n_bits', n_bits_a, ...
    'bin_pt', bin_pt_a, ...
    'pipeline', 'on'), ...
    {a_im}, ...
    {realign_a_im_out1});

% block: twiddle_dsp48e_test/twiddle_general_dsp48e/cmult/realign_a_re

realign_a_re = xBlock(struct('source', 'Convert', 'name', 'realign_a_re'), ...
    struct('n_bits', n_bits_a, ...
    'bin_pt', bin_pt_a, ...
    'pipeline', 'on'), ...
    {a_re}, ...
    {realign_a_re_out1});

% block: twiddle_dsp48e_test/twiddle_general_dsp48e/cmult/realign_b_im
realign_b_im = xBlock(struct('source', 'Convert', 'name', 'realign_b_im'), ...
    struct('n_bits', n_bits_b, ...
    'bin_pt', bin_pt_b, ...
    'pipeline', 'on'), ...
    {b_im}, ...
    {realign_b_im_out1});

% block: twiddle_dsp48e_test/twiddle_general_dsp48e/cmult/realign_b_re
realign_b_re = xBlock(struct('source', 'Convert', 'name', 'realign_b_re'), ...
    struct('n_bits', n_bits_b, ...
    'bin_pt', bin_pt_b, ...
    'pipeline', 'on'), ...
    {b_re}, ...
    {realign_b_re_out1});

% block: twiddle_dsp48e_test/twiddle_general_dsp48e/cmult/reinterp_d_im
reinterp_d_im = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_d_im'), ...
    struct('force_arith_type', 'on', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'force_bin_pt', 'on', ...
    'bin_pt', bin_pt_reinterp), ...
    {DSP48E_1_out1}, ...
    {reinterp_d_im_out1});

% block: twiddle_dsp48e_test/twiddle_general_dsp48e/cmult/reinterp_d_re
reinterp_d_re = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_d_re'), ...
    struct('force_arith_type', 'on', ...
    'arith_type', 'Signed  (2''s comp)', ...
    'force_bin_pt', 'on', ...
    'bin_pt', bin_pt_reinterp), ...
    {DSP48E_3_out1}, ...
    {reinterp_d_re_out1});


if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
end

end
