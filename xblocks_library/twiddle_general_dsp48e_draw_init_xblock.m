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
function twiddle_general_dsp48e_draw_init_xblock(a_re, a_im, b_re, b_im, w_re, w_im, sync, ...
    a_re_out, a_im_out, bw_re_out, bw_im_out, sync_out, ...
    Coeffs, StepPeriod, coeff_bit_width, input_bit_width, bram_latency,...
    conv_latency, quantization, overflow, arch, coeffs_bram, FFTSize)

%depends =
%{'coeff_gen_init_xblock','cmult_dsp48e_init_xblock','c_to_ri_init_xblock'}


%% diagram
% parameters
cmult_dsp48e_latency = 4; 
total_latency = cmult_dsp48e_latency + conv_latency;

% signals
b_re_del = xSignal;
b_im_del = xSignal;

% delay sync by total_latency
sync_delay = xBlock(struct('source', 'Delay', 'name', 'sync_delay'), ...
    struct('latency', total_latency), ...
    {sync}, ...
    {sync_out});

% delay a_re by total latency
a_re_delay = xBlock(struct('source', 'Delay', 'name', 'a_re_delay'), ...
    struct('latency', total_latency, 'reg_retiming', 'on'), {a_re}, {a_re_out});

% delay a_im by total latency
a_im_delay = xBlock(struct('source', 'Delay', 'name', 'a_im_delay'), ...
    struct('latency', total_latency, 'reg_retiming', 'on'), {a_im}, {a_im_out});

xBlock(struct('source', @cmult_dsp48e_init_xblock, 'name', 'cmult'), ...
    {[], 'n_bits_a', input_bit_width, 'bin_pt_a', input_bit_width - 1, 'n_bits_b', coeff_bit_width, 'bin_pt_b', coeff_bit_width - 1, 'conjugated', 0, ...
    'full_precision', 0, 'n_bits_c', input_bit_width + 4, 'bin_pt_c', input_bit_width + 1, 'quantization', quantization, ...
    'overflow', overflow, 'conv_latency', conv_latency}, ...
    {b_re, b_im, w_re, w_im}, ...
    {bw_re_out, bw_im_out});

end
