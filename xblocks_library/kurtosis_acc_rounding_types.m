function [m_x_type, x_sq_type, x_3rd_type, x_4th_type] = kurtosis_acc_rounding_types(type_x, acc_len)

single_type_x = type_x;
double_type_x = type_x^2 + type_x^2;
triple_type_x = type_x^3;
quad_type_x = double_type_x^2;

single_type_x_acc = fi_dtype(1, single_type_x.WordLength+acc_len, single_type_x.FractionLength+acc_len);
double_type_x_acc = fi_dtype(1, double_type_x.WordLength+acc_len, double_type_x.FractionLength);
triple_type_x_acc = fi_dtype(1, triple_type_x.WordLength+acc_len, triple_type_x.FractionLength);
quad_type_x_acc = fi_dtype(1, quad_type_x.WordLength+acc_len, quad_type_x.FractionLength);

m_x_type   = fi_dtype(1, 25, 25-(type_x.WordLength - type_x.FractionLength)); % mean needs no more integer bits than the original representation
x_sq_type   = fi_dtype(1, 35, 35-(double_type_x_acc.WordLength - double_type_x_acc.FractionLength));
x_3rd_type   = fi_dtype(1, 35, 35-(triple_type_x_acc.WordLength - triple_type_x_acc.FractionLength));
x_4th_type     = quad_type_x_acc;
