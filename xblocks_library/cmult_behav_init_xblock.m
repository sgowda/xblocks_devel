%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %
%   Copyright (C) 2013 Suraj Gowda    Hong Chen                               %
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
function cmult_behav_init_xblock(blk, varargin)

defaults = {'n_bits_a', 18, 'bin_pt_a', 17, 'n_bits_b', 18, 'bin_pt_b', 17, 'conjugated', 0, ...
	'full_precision', 1, 'n_bits_c', 18, 'bin_pt_c', 17, 'quantization', 'Truncate', 'overflow', 'Wrap', ...
    'cplx_inputs', 0, 'mult_latency', 3, 'add_latency', 2, 'conv_latency', 1};

n_bits_a = get_var('n_bits_a', 'defaults', defaults, varargin{:});
n_bits_b = get_var('n_bits_b', 'defaults', defaults, varargin{:});
n_bits_c = get_var('n_bits_c', 'defaults', defaults, varargin{:});
bin_pt_a = get_var('bin_pt_a', 'defaults', defaults, varargin{:});
bin_pt_b = get_var('bin_pt_b', 'defaults', defaults, varargin{:});
bin_pt_c = get_var('bin_pt_c', 'defaults', defaults, varargin{:});
conjugated = get_var('conjugated', 'defaults', defaults, varargin{:});
full_precision = get_var('full_precision', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});
cplx_inputs = get_var('cplx_inputs', 'defaults', defaults, varargin{:});
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});

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
if full_precision,
  n_bits_out = n_bits_a + n_bits_b + 1;
  bin_pt_out = bin_pt_a + bin_pt_b;
else
  n_bits_out = n_bits_c;
  bin_pt_out = bin_pt_c;
end


% Set conjugation mode.

if conjugated,
    alumode1_val = 1;
    carryin1_val = 1;
    alumode3_val = 0;
else
    alumode1_val = 0;
    carryin1_val = 0;
    alumode3_val = 3;
end


%-- inports and outports
if cplx_inputs
    a = xInport('a');
    b = xInport('b');
    c = xOutport('c');
    
    a_re = xSignal('a_re');
    a_im = xSignal('a_im');
    b_re = xSignal('b_re');
    b_im = xSignal('b_im');

    xBlock(struct('name', 'a_input_c_to_ri', 'source', str2func('c_to_ri_init_xblock')), ...
        {sprintf('%s/%s', blk, 'a_input_c_to_ri'), n_bits_a, bin_pt_a}, ...
        {a}, {a_re, a_im});

    xBlock(struct('name', 'b_input_c_to_ri', 'source', str2func('c_to_ri_init_xblock')), ...
        {sprintf('%s/%s', blk, 'b_input_c_to_ri'), n_bits_b, bin_pt_b}, ...
        {b}, {b_re, b_im});
    
    c_re = xSignal('c_re');
    c_im = xSignal('c_im');
    
    xBlock(struct('name', 'c_output_ri_to_c', 'source', str2func('ri_to_c_init_xblock')), ...
        {sprintf('%s/%s', blk, 'c_output_ri_to_c')}, {c_re, c_im}, {c});
else
    a_re = xInport('a_re');
    a_im = xInport('a_im');
    b_re = xInport('b_re');
    b_im = xInport('b_im');

    c_re = xOutport('c_re');
    c_im = xOutport('c_im');
end


%% diagram

w = xSignal;
% w_re = xSignal;
% w_im = xSignal;

mult_out1 = xSignal;
mult1_out1 = xSignal;
mult2_out1 = xSignal;
mult3_out1 = xSignal;

total_latency = mult_latency + add_latency + conv_latency;

% delay b_re by bram_latency
b_re_del = b_re;
b_im_del = b_im;
% b_re_delay = xBlock(struct('source', 'Delay', 'name', 'b_re_delay'), ...
%     struct('latency', bram_latency, 'reg_retiming', 'on'), {b_re}, {b_re_del});
% 
% % delay b_im by bram_latency
% b_im_delay = xBlock(struct('source', 'Delay', 'name', 'b_im_delay'), ...
%     struct('latency', bram_latency, 'reg_retiming', 'on'), {b_im}, {b_im_del});

% instantiate coefficient generator


% split w into real/imag
% c_to_ri_w = xBlock(struct('source', str2func('c_to_ri_init_xblock'), 'name', 'c_to_ri_w'), ...
%                             {[], ...
%                             coeff_bit_width, ...
%                             coeff_bit_width-2}, ...  % note this is -2
%                          {w}, {w_re, w_im});

mults = xBlock(struct('source', str2func('tap_multiply_fabric_init_xblock'), 'name', 'mults'), ...
    {[], n_bits_a, n_bits_a-1, n_bits_b, ...
    n_bits_b-1, 'on', 0, 0, quantization, overflow, conv_latency, ...
    4, mult_latency}, ...
    {a_re, b_re, a_im, b_im, a_im, b_re, a_re, b_im}, ...
    {mult_out1, mult1_out1, mult2_out1, mult3_out1} );


% block: twiddles_collections/twiddle_general_4mult/AddSub
if conjugated
    AddSub_out1 = xSignal;
    AddSub = xBlock(struct('source', 'AddSub', 'name', 'AddSub'), ...
        struct('mode', 'Addition', ...
        'latency', add_latency, ...
        'use_behavioral_HDL', 'on'), ...
        {mult_out1, mult1_out1}, ...
        {AddSub_out1});

    % block: twiddles_collections/twiddle_general_4mult/AddSub1
    AddSub1_out1 = xSignal;
    AddSub1 = xBlock(struct('source', 'AddSub', 'name', 'AddSub1'), ...
        struct('mode', 'Subtraction', ...
        'latency', add_latency, ...
        'use_behavioral_HDL', 'on'), ...
        {mult2_out1, mult3_out1}, ...
        {AddSub1_out1});	
else 
    AddSub_out1 = xSignal;
    AddSub = xBlock(struct('source', 'AddSub', 'name', 'AddSub'), ...
        struct('mode', 'Subtraction', ...
        'latency', add_latency, ...
        'use_behavioral_HDL', 'on'), ...
        {mult_out1, mult1_out1}, ...
        {AddSub_out1});

    % block: twiddles_collections/twiddle_general_4mult/AddSub1
    AddSub1_out1 = xSignal;
    AddSub1 = xBlock(struct('source', 'AddSub', 'name', 'AddSub1'), ...
        struct('latency', add_latency, ...
        'use_behavioral_HDL', 'on'), ...
        {mult2_out1, mult3_out1}, ...
        {AddSub1_out1});
end
% block: twiddles_collections/twiddle_general_4mult/convert0
%convert0_out1 = xSignal;
convert0 = xBlock(struct('source', 'Convert', 'name', 'convert0'), ...
    struct('n_bits', n_bits_out, ...
    'bin_pt', bin_pt_out, ...
    'quantization', quantization, ...
    'overflow', overflow, ...
    'latency', conv_latency, ...
    'pipeline', 'on'), ...
    {AddSub_out1}, ...
    {c_re});

% block: twiddles_collections/twiddle_general_4mult/convert1
%convert1_out1 = xSignal;
convert1 = xBlock(struct('source', 'Convert', 'name', 'convert1'), ...
    struct('n_bits', n_bits_out, ...
    'bin_pt', bin_pt_out, ...
    'quantization', quantization, ...
    'overflow', overflow, ...
    'latency', conv_latency, ...
    'pipeline', 'on'), ...
    {AddSub1_out1}, ...
    {c_im});



end


