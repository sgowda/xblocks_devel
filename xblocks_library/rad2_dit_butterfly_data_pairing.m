function [output_data] = rad2_dit_butterfly_data_pairing(x, stage)
% corner turn operator for 1 FFT stage
    N = length(x);
    J = 2^stage;
    M = N / J;
   
    % 2d reshaping operator on the vector
%     data = reshape(x, J, M)
    data = zeros(1, M, J);
    for k=1:J
        data(:,:,k) = x((k-1)*M+1 : k*M);
    end

    output_data = [];
    for j=1:J/2
        c0 = data(:,:,2*j-1);
        c1 = data(:,:,2*j);
        ds0 = [c0(1,:); c1(1,:)];
        output_data = [output_data, ds0];
end
