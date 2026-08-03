function [gamma, f_res, idx] = gammaFunction(f, S11)
%GAMMAFUNCTION Computes the gamma function and resonant frequency.
%
%   [gamma, f_res, idx] = gammaFunction(f, S11)
%
%   Inputs:
%       f   - Frequency vector (Hz)
%       S11 - Complex reflection coefficient vector
%
%   Outputs:
%       gamma - Gamma function
%       f_res - Resonant frequency (Hz)
%       idx   - Index of the resonant frequency
%
%   Equation:
%       gamma(f) = 0.5 * |1 - S11(f)|
%
% Author: Laith Al Sairafi

    % Check input dimensions
    if length(f) ~= length(S11)
        error('Frequency vector and S11 vector must have the same length.');
    end

    % Compute gamma function
    gamma = 0.5 * abs(1 - S11);

    % Find resonant frequency (minimum gamma)
    [~, idx] = min(gamma);
    f_res = f(idx);

end