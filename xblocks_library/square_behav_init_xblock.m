function square_behav_init_xblock(blk, varargin)
defaults = {'mult_latency', 3};
mult_latency = get_var('mult_latency', 'defaults', defaults, varargin{:});

%% inports
a = xInport('a');

%% outports
outport1 = xOutport('a^2');

% block: untitled/square_behav_init_xblock/Mult
Mult = xBlock(struct('source', 'Mult', 'name', 'Mult'), ...
                     {'latency', mult_latency}, ...
                     {a, a}, ...
                     {outport1});

end
