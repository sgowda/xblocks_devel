function dsp48e_input_cast_init_xblock(blk, varargin)

defaults = {'input_port', 'a'};
input_port = get_var('input_port', 'defaults', defaults, varargin{:});

if strcmp(input_port, 'a')
    n_bits = 30;
elseif strcmp(input_port, 'b')
    n_bits = 18;
elseif strcmp(input_port, 'c')
    n_bits = 48;
else
    error(sprintf('Unrecognized input port: %s', input_port))
end

%% inports
In1 = xInport('In1');

%% outports
Out1 = xOutport('Out1');

%% diagram

% block: butterfly/arith/apbw/dsp48e_input_cast_init_xblock/cast_c_re1
reinterp_c_re1_out1 = xSignal('reinterp_c_re1_out1');
cast_c_re1 = xBlock(struct('source', 'Convert', 'name', 'cast_c'), ...
                           struct('n_bits', n_bits, ...
                                  'bin_pt', 0, ...
                                  'pipeline', 'on'), ...
                           {reinterp_c_re1_out1}, ...
                           {Out1});

% block: butterfly/arith/apbw/dsp48e_input_cast_init_xblock/reinterp_c_re1
reinterp_c_re1 = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_c'), ...
                               struct('force_arith_type', 'on', ...
                                      'arith_type', 'Signed  (2''s comp)', ...
                                      'force_bin_pt', 'on'), ...
                               {In1}, ...
                               {reinterp_c_re1_out1});
end
