function design = designApplicator(NL, f0, eps_a, eps_c, thk_c, x0)
%DESIGNAPPLICATOR Design a quarter-wave applicator for coating measurements.
%
%   DESIGN = DESIGNAPPLICATOR(NL, F0, EPS_A, EPS_C, THK_C)
%   determines the dielectric applicator thickness that aligns the resonance with the
%   design frequency for a nominal dielectric coating thickness.
%
%   The applicator thickness is chosen such that angle(S_11) = 0 degrees
%   at the design frequency (f0) for the specified coating thickness.
%
%   Inputs
%   ------
%   NL: Object
%       nLayerCircular object.
%   
%   f0: double 
%       Design frequency (GHz).
%   
%   eps_a: complex scalar
%       Applicator relative permittivity.   
%   
%   eps_c: complex scalar
%       Coating relative permittivity.
%
%   thk_c: double
%       nominal coating thickness (mm).
%
%   X0 (optional)
%       Initial guess for applicator thickness (mm). If omitted, a
%       quarter-wavelength estimate is used.
%
%   Output
%   ------
%   DESIGN
%       Structure containing:
%
%       thickness      Optimized applicator thickness (mm)
%       gamma          Reflection coefficient at the solution
%       phase          Reflected phase (deg)
%       frequency      Design frequency (GHz)
%       coatingThk     Target coating thickness (mm)
%       er             Relative permittivity vector
%       ur             Relative permeability vector
%       success        True if |phase| < 1e-3 degrees
%
%   Example
%   -------
%   design = designApplicator(NL, 36, 10-0.004j, 3.5-0.004j, 0.100);
%
%   disp(design.thickness)
%
% Author: Laith Al Sairafi

arguments
    NL
    f0 (1,1) double
    eps_a (1,1) double
    eps_c (1,1) double
    thk_c (1,1) double
    x0 (1,1) double = NaN
end

%% Initial guess

if isnan(x0)
    x0 = 300/(4*f0*sqrt(real(eps_a)));
end

%% Layer properties

er = {eps_a, eps_c};
ur = {1.0-0.0j, 1.0-0.0j};

%% Objective

phaseFun = @(t)rad2deg(angle(NL.calculate(f0, er, ur, {t, thk_c})));

%% Solve

thk = fzero(phaseFun,x0);

%% Evaluate solution

gamma = NL.calculate(f0,er,ur,{thk, thk_c});

phase = rad2deg(angle(gamma));

if ~(abs(phase) < 1e-3)
    error("non zero phase. applicator optimizor failed to find a solution")
end

%% Return structure

design.thickness  = thk;
design.gamma      = gamma;
design.phase      = phase;
design.frequency  = f0;
design.coatingThk = thk_c;
design.er = er;
design.ur = ur;
design.success = abs(phase) < 1e-3;

end