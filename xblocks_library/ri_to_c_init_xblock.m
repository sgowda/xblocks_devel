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
function ri_to_c_init_xblock(varargin)
%% inports
re = xInport('re');
im = xInport('im');

%% outports
c = xOutport('c');

%% diagram

% block: untitled/butterfly_direct/ri_to_c01/concat
re_reinterp = xSignal;
im_reinterp = xSignal;
concat = xBlock(struct('source', 'Concat', 'name', 'concat'), ...
    [], {re_reinterp, im_reinterp}, {c});

% block: untitled/butterfly_direct/ri_to_c01/force_im
force_im = xBlock(struct('source', 'Reinterpret', 'name', 'force_im'), ...
    struct('force_arith_type', 'on', 'force_bin_pt', 'on'), {im}, {im_reinterp});

% block: untitled/butterfly_direct/ri_to_c01/force_re
force_re = xBlock(struct('source', 'Reinterpret', 'name', 'force_re'), ...
    struct('force_arith_type', 'on', 'force_bin_pt', 'on'), {re}, {re_reinterp});
end
