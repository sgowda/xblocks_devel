function outputs = xblock_new_outputs( name, M, N )

outputs = {};
for m = 1:M
    for n = 1:N
        if N == 1
            outputs{m,n} = xOutport(sprintf('%s_%d', name, m));
        elseif M == 1
            outputs{m,n} = xOutport(sprintf('%s_%d', name, n));
        else
            outputs{m,n} = xOutport(sprintf('%s_%d_%d', name, m, n));
        end
    end
end

end

