function [selected] = mux_select(name, sel, inputs, varargin)
defaults = {'latency', 0};
latency = get_var('latency', 'defaults', defaults, varargin{:});

if ~iscell(inputs)
    error('inputs must be a cell array')
end

selected = xSignal();
config.source = 'Mux';
config.name = name;

xBlock(config, {'inputs', length(inputs), 'latency', latency}, [{sel}, inputs], {selected});