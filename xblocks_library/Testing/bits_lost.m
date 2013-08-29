function [lost] = bits_lost(x, y)
    lost = log2(max_error(x, y));
end