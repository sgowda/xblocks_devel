function [edge] = posedge(name, x)

edge = xSignal();
xBlock(struct('name', name, 'source', @edge_detect_init_xblock), ...
    {'edge', 'Rising', 'polarity', 'Active High'}, {x}, {edge});

end
