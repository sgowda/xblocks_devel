function [x_slices] = slice_partition(name, x, bit_widths)

n_slices = length(bit_widths);
x_slices = xblock_new_bus(n_slices, 1);
lsb_offsets = [0, cumsum(bit_widths)];

for k=1:n_slices
    xBlock(struct('source', 'Slice', 'name', sprintf('%s_%d', name, k)), ...
        struct('nbits', bit_widths(k), 'mode', 'Lower Bit Location + Width', ...
        'bit0', lsb_offsets(k)), ...
        {x}, ...
        x_slices(k));
end

end
