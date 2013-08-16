function signals = xblock_new_bus(M, N)
% signals = xblock_new_bus( M,N )
signals = {};
for n = 1:N
	for m = 1:M
        if M == 1
            signals{n} = xSignal();
        elseif N == 1
            signals{m} = xSignal();
        else
            signals{m,n} = xSignal();
        end
end

end