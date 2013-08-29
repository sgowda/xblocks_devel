function [err] = max_error(x, y)
    err = max(abs(x-y));
end