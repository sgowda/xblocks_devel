function [x_reinterp] = reinterp_int(name, x)
x_reinterp = reinterpret(name, x, fi_dtype(1, 1, 0), 'force_arith_type', 1, 'force_bin_pt', 1);
