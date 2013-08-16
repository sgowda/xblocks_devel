function xblock_delay( din, dout, name, latency, delay_type )

if length(din) ~= length(dout)
	error('delaying unequal buses')
end

[M,N] = size(din);

for m = 1:M
    for n =1:N
	    xBlock( struct('source', 'Delay', 'name', sprintf('%s_delay_%d_%d', name, m, n)), ...
	    	struct('latency', latency, 'Position',  [330   964   370   986],  'ShowName', 'off'), din(m,n), dout(m,n));
    end
end

end
