%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda    Hong Chen                               %
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
function butterfly_arith_dsp48e_init_xblock(blk, varargin)
% depend list:
% {'c_to_ri_init_xblock','cmacc_dsp48e_init_xblock','simd_add_dsp48e_init_xblock','coeff_gen_init_xblock'}

defaults = {'coeff_bit_width', 18, ...
    'coeff_bin_pt', 17, ...
    'input_bit_width', 18, ...
    'conv_latency', 1, ...
    'quantization', 'Truncate', ...
    'overflow', 'Wrap'};

coeff_bit_width = get_var('coeff_bit_width', 'defaults', defaults, varargin{:});
coeff_bin_pt = get_var('coeff_bin_pt', 'defaults', defaults, varargin{:});
input_bit_width = get_var('input_bit_width', 'defaults', defaults, varargin{:});
conv_latency = get_var('conv_latency', 'defaults', defaults, varargin{:});
quantization = get_var('quantization', 'defaults', defaults, varargin{:});
overflow = get_var('overflow', 'defaults', defaults, varargin{:});


%% inports
a = xInport('a');
b = xInport('b');
w = xInport('w');
sync = xInport('sync');

%% outports
apbw_re_out = xOutport('a+bw_re');
apbw_im_out = xOutport('a+bw_im');
ambw_re_out = xOutport('a-bw_re');
ambw_im_out = xOutport('a-bw_im');
sync_out = xOutport('sync_out');

%% diagram
% parameters
macc_latency = 4; % fixed for this implementation
add_latency = 2; % fixed for this implementation
total_latency = macc_latency + conv_latency;

% signals
a_re = xSignal('a_re');
a_im = xSignal('a_im');
b_re = xSignal('b_re');
b_im = xSignal('b_im');
w_re = xSignal('w_re');
w_im = xSignal('w_im');

% convert 'a' input to real/imag
c_to_ri_a = xBlock(struct('source', str2func('c_to_ri_init_xblock'), 'name', 'c_to_ri_a'), ...
    {[blk, '/c_to_ri_a'],input_bit_width, input_bit_width-1}, {a}, {a_re, a_im});

% convert 'b' input to real/imag
c_to_ri_b = xBlock(struct('source', str2func('c_to_ri_init_xblock'), 'name', 'c_to_ri_b'), ...
    {[blk, '/c_to_ri_b'],input_bit_width, input_bit_width-1}, {b}, {b_re, b_im});

% convert 'w' input to real/imag
c_to_ri_w = xBlock(struct('source', str2func('c_to_ri_init_xblock'), 'name', 'c_to_ri_w'), ...
    {[blk, '/c_to_ri_w'],input_bit_width, input_bit_width-1}, {w}, {w_re, w_im});

a_re_del2 = xSignal;
a_im_del2 = xSignal;
a_re_del_scale = xSignal;
a_im_del_scale = xSignal;

apbw_re = xSignal;
apbw_im = xSignal;
pcout_cmacc = xSignal();

% delay sync by total_latency 
sync_delay = xBlock(struct('source', 'Delay', 'name', 'sync_delay'), ...
                       struct('latency', total_latency+add_latency), ...
                       {sync}, ...
                       {sync_out});

% delay a_re by total latency, with split for input to cmacc
a_re_delay = xBlock(struct('source', 'Delay', 'name', 'a_re_delay2'), ...
                       struct('latency', total_latency, 'reg_retiming', 'on'), {a_re}, {a_re_del2});


% delay a_im by total latency 
a_im_delay = xBlock(struct('source', 'Delay', 'name', 'a_im_delay2'), ...
                       struct('latency', total_latency, 'reg_retiming', 'on'), {a_im}, {a_im_del2});
                       
% Scale 'a' terms for subtraction input
xBlock( struct('source', 'Scale', 'name', 'a_re_scale'), struct('scale_factor', 1), {a_re_del2}, {a_re_del_scale});
xBlock( struct('source', 'Scale', 'name', 'a_im_scale'), struct('scale_factor', 1), {a_im_del2}, {a_im_del_scale});
                           
% block: twiddles_collections/twiddle_general_dsp48e/cmult
cmacc_sub = xBlock(struct('source', str2func('cmacc_dsp48e_init_xblock'), 'name', 'apbw'), ...
                      {[blk, '/apbw'],input_bit_width, input_bit_width - 1, coeff_bit_width, coeff_bin_pt, 'off', ...
                      	'off', input_bit_width + 5, input_bit_width + 1, quantization, ... 
                      	overflow, conv_latency}, ...
                      {b_re, b_im, w_re, w_im, a_re, a_im}, ...
                      {apbw_re, apbw_im,pcout_cmacc});

apbw_re_out.bind( apbw_re );
apbw_im_out.bind( apbw_im );
                      
csub = xBlock(struct('source', str2func('simd_add_dsp48e_init_xblock'), 'name', 'csub'), ...
				  {[blk, '/csub'],'Subtraction', input_bit_width, input_bit_width-1, input_bit_width + 4, ...
						input_bit_width + 1, 'off', input_bit_width + 5, input_bit_width + 1, 'Truncate', 'Wrap', 0, 1}, ...
				  {a_re_del_scale, a_im_del_scale, apbw_re, apbw_im,pcout_cmacc}, ...
				  {ambw_re_out, ambw_im_out});                      

% % instantiate coefficient generator
% br_indices = bit_rev( Coeffs, FFTSize-1 );
% br_indices = -2*pi*1j*br_indices/2^FFTSize;
% ActualCoeffs = exp(br_indices);
% coeff_gen_sub = xBlock(struct('source',str2func('coeff_gen_init_xblock'), 'name', 'coeff_gen'), ...
%                           {[blk, '/coeff_gen'],ActualCoeffs, coeff_bit_width, StepPeriod, bram_latency, coeffs_bram}, {sync}, {w});                     
                      
if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
end                          
end
