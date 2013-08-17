function [m_x_type_unr, x_sq_type_unr, x_3rd_type_unr, x_4th_type_unr] = kurtosis_acc_types(type_x, acc_len)

single_type_x = type_x;
double_type_x = type_x^2 + type_x^2;
triple_type_x = type_x^3;
quad_type_x = double_type_x^2;

m_x_type_unr = fi_dtype(1, single_type_x.WordLength+acc_len, single_type_x.FractionLength+acc_len);
x_sq_type_unr = fi_dtype(1, double_type_x.WordLength+acc_len, double_type_x.FractionLength);
x_3rd_type_unr = fi_dtype(1, triple_type_x.WordLength+acc_len, triple_type_x.FractionLength);
x_4th_type_unr = fi_dtype(1, quad_type_x.WordLength+acc_len, quad_type_x.FractionLength);
