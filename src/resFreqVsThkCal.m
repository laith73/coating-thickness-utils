function Results = resFreqVsThkCal(NL, eps_a, thk_a, options)
% RESONANTFREQVSTHICKNESSSINGLE  Linear (polynomial) fit of resonant
% frequency vs coating thickness for a single applicator material.
%
%   Results = resFreqVsThkCal(name, thickness, eps)
%   Results = resFreqVsThkCal(name, thickness, eps, Name, Value, ...)
%
% Simulates S11 for one applicator loaded with a coating material
% over a swept coating thickness, extracts the resonant frequency at
% each thickness, fits a polynomial thickness = f(resonantFrequency), 
% and returns the fit.
%
% Required arguments:
%   NL: Object
%       nLayerCircular object.
%   eps_a: scalar complex
%       applicator relative permittivity.
%   thk_a: scalar
%       applicator thickness in mm
%
% Name-Value arguments (all optional):
%   f                   - frequency sweep vector in GHz
%                          (default: linspace(32,40,1601))
%   eps_c               - complex relative permittivity of the coating
%                         (default: 3.45 - 0.004j, i.e. Kapton)
%   thk_c_range         - vector of coating thicknesses to sweep, in um
%                          (default: linspace(0, 250, 251))
%   fitOrder            - polynomial order for thickness(f) fit
%                          (default: 2)
% Outputs:
%   Results  -  coeffs, R2, frequency, thickness
%
% Author: Laith Al Sairafi


arguments
    NL
    eps_a (1,1) double
    thk_a (1,1) double

    options.f (1,:) double = linspace(32, 40, 1601)
    options.eps_c (1,1) double = 3.45 - 0.004j
    options.thk_c_range (1,:) double = linspace(0, 250, 251)
    options.fitOrder (1,1) double {mustBeInteger, mustBePositive} = 2
end

f = options.f;
eps_c = options.eps_c;
thk_c_range = options.thk_c_range;      % um
thk_c_range_mm = thk_c_range / 1000;

%% Calculate reflection coefficients

er = {eps_a, eps_c};
ur = {1.0-0.0j, 1.0-0.0j};

n = numel(thk_c_range);
resFreq  = zeros(n, 1);
minGamma = zeros(n, 1);

for ii = 1:n
    S11 = NL.calculate(f, er, ur, {thk_a, thk_c_range_mm(ii)});
    gamma = 0.5 * abs(1 - S11);
    [minGamma(ii), idx] = min(gamma);
    resFreq(ii) = f(idx);
end

%% Polynomial Fit thickness = p(resFreq)

p = polyfit(resFreq, thk_c_range, options.fitOrder);
thicknessFit = polyval(p, resFreq);

SSres = sum((thk_c_range - thicknessFit').^2);
SStot = sum((thk_c_range - mean(thk_c_range)).^2);
R2 = 1 - SSres / SStot;

Results.coeffs = p;
Results.R2 = R2;
Results.frequency = resFreq;
Results.thickness = thk_c_range;

%% Print Summary

numCoeffs = numel(p);
coeffHeaders = strings(1, numCoeffs);

for kk = 1:numCoeffs
    coeffHeaders(kk) = sprintf('c%d', numCoeffs - kk);   % c(n-1) ... c0, highest order first
end
 
headerFmt = ['%12s' repmat(' %12s', 1, numCoeffs) ' %12s\n'];
rowFmt    = ['%12s' repmat(' %12.4g', 1, numCoeffs) ' %12.5f\n'];
 
fprintf('\n');
fprintf(headerFmt, 'Material', coeffHeaders{:}, 'R^2');
fprintf(rowFmt, 'Coeffs', p, R2);

end