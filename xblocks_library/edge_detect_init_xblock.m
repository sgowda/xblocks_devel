function edge_detect_init_xblock(blk, varargin)
defaults = {'edge', 'Rising', 'polarity', 'Active High'};
edge = get_var('edge', 'defaults', defaults, varargin{:});
polarity = get_var('polarity', 'defaults', defaults, varargin{:});

rising_edge = strcmp(edge, 'Rising');
active_high = strcmp(polarity, 'Active High');
active_low = strcmp(polarity, 'Active Low');

%% Inports
x = xInport('x');

%% Outports
edge = xOutport('edge');

if rising_edge
    not_x = inverter('inverter', x);
    del_x = delay_srl('del', x, 1);
    edge_sig = nor_gate('edge_op', not_x, del_x);
    if active_high
        edge.bind(edge_sig)
    else
        edge.bind(inverter('inv1', edge_sig))
    end
else
    error('edge_detect_init_xblock: case not yet implemented')
end

end
