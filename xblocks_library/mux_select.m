function [selected] = mux_select(name, sel, inputs)

if ~iscell(inputs)
    error('inputs must be a cell array')
end

selected = xSignal();
config.source = 'Mux';
config.name = name;

xBlock(config, {'n_inputs', length(inputs)}, [{sel}, inputs], {selected});
