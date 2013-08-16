function [ab_re, ab_im] = cplx_add(name, a, b, varargin)

if iscell(a) && iscell(b)
    ab_re = add([name, '_re'], a, b, varargin{:});    
    ab_im = add([name, '_im'], a, b, varargin{:});    
else
    NotImplementedError()
end
