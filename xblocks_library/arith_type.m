function [arith_type_str] = arith_type(dtype)

if dtype.Signed == 1
    arith_type_str = 'Signed  (2''s comp)';
elseif dtype.Signed == 0;
    arith_type_str = 'Unsigned';
end
