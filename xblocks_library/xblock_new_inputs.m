function inputs = xblock_new_inputs( name, M, N )

inputs = {};
for m = 1:M
    for n = 1:N
        if N == 1
            inputs{m,n} = xInport( [name, '_', num2str(m)] );
        else
            inputs{m,n} = xInport( [name, '_', num2str(m), '_', num2str(n)] );
        end
    end
end

end