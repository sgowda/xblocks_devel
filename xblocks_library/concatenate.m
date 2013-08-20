function sOut = concatenate(name, sIn)

if ~iscell(sIn)
    error('sIn must be cell array')
end

n_inputs = length(sIn);

if(n_inputs == 1)
    sOut = sIn;
else
    sOut = xSignal;
    
    bConcat = xBlock(struct('source', 'Concat', 'name', name), ...
        struct('num_inputs', n_inputs), ...
        {sIn{:}}, {sOut});
end
