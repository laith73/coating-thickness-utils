function results = measCoatingThkOpt(folderPaths, baseMeasFile, ...
    eps_a, thk_a_guess, eps_c)
%MEASUREPAINTTHICKNESS Estimate paint thickness from repeated S11 measurements.
%
%   RESULTS = MEASUREPAINTTHICKNESS(FOLDERPATHS, BASEMEASFILE, EPS_A,
%   UR_A, THK_A_GUESS, EPS_PT, UR_PT) processes repeated measurements of
%   paint-coated samples acquired using a circular open-ended waveguide
%   probe and estimates the paint thickness using the nLayer inverse
%   solver.
%
%   The function first determines the applicator thickness from the base
%   (0-mil) calibration measurement. It then independently solves for the
%   paint thickness for each repeated measurement and returns the mean and
%   standard deviation of the estimated thicknesses.
%
%   Inputs
%   ------
%   folderPaths : string array
%       Paths to folders containing repeated measurements. Each folder must
%       contain the same set of Touchstone (.s2p) files with identical
%       filenames.
%
%   baseMeasFile : string
%       Filename of the applicator calibration measurement.
%       Must present in every measurement folder.
%
%   eps_a : complex scalar
%       Initial guess for the applicator relative permittivity.
%
%   thk_a_guess : double
%       Initial guess for the applicator thickness (mm).
%
%   eps_pt : complex scalar
%       Paint relative permittivity.
%   
%   Output
%   ------
%   results : struct
%       Structure containing the solved parameters:
%
%       f                 - Frequency vector (GHz)
%       files             - Measurement filenames
%       thk_actual        - Actual paint thicknesses (mm)
%       thk_runs          - Estimated paint thickness for each run (numRuns × numMeasurements)
%       thk_mean          - Mean estimated paint thickness (mm)
%       thk_std           - Standard deviation of estimated thickness (mm)
%       app_thickness     - Solved applicator thickness (mm)
%       app_permittivity  - Solved applicator relative permittivity
%
%   Notes
%   -----
%   • Each repeated measurement is solved independently.
%   • The reported mean and standard deviation are computed from the
%     recovered thicknesses, not by averaging the measured reflection
%     coefficients prior to inversion.
%   • All measurement folders must contain identical filenames and
%     frequency sampling.
%
%   Example
%   -------
%   folderPaths = [
%       "...\Run1\"
%       "...\Run2\"
%       "...\Run3\"
%   ];
%
%   results = measurePaintThickness( ...
%       folderPaths, ...
%       "0MiL-Kapton.s2p", ...
%       11.7-0.05j, ...
%       1, ...
%       0.64, ...
%       3.5-0.004j, ...
%       1);
%
%   errorbar(results.thk_actual*1000, ...
%            results.thk_mean*1000, ...
%            results.thk_std*1000, 'o');
%
%   See also nLayerInverse, nLayerCircular, sparameters.
%
% Author: Laith Al Sairafi

%% Settings

numModes = 50;
pointsNum = 1601;
numRuns = numel(folderPaths);
ur_a = 1.0-0.0j; % Only dielectric applicator materials
ur_c = 1.0-0.0j; % Only dielectric coating materials
f = linspace(32,40, pointsNum);

%% Read filenames

listing = dir(folderPaths(1));

files = string({listing(~[listing.isdir]).name})';

numbers = regexp(files,'^\d+','match');
numbers = cellfun(@(c) str2double(c{1}),numbers);

[~,idx] = sort(numbers);
files = files(idx);

measNum = numel(files);

thk_pt_actual = 0.0254*(0:measNum-1);

%% Create nLayer objects

NL = nLayerCircular(0, numModes, waveguideBand="Ka_TE01", modeSymmetryAxial="TE");

NL.frequencyRange = f;

%% Applicator thickness Solver 

solverApp = nLayerInverse(1);

solverApp.setLayersToSolve(Thk=(1));

%% Paint thicknesses Solver

solverPaint = nLayerInverse(2);

solverPaint.setLayersToSolve(Thk=(2));

%% Solve for paint thicknesses

er = {eps_a eps_c};
ur = {ur_a ur_c};

thk_pt = zeros(numRuns,measNum);
thk_a = zeros(numRuns,1);

for run = 1:numRuns
    
    S = sparameters(folderPaths(run) + baseMeasFile); 
    gamCal = squeeze(S.Parameters(1,1,:));

    solverApp.setInitialValues(Er=eps_a, Ur=ur_a, Thk=thk_a_guess);
    [ParamsApp,~,UncertApp] = solverApp.solveStructure(NL, f, gamCal);

    thk_a(run) = ParamsApp.thk;

    fprintf('\n=========================================\n');
    fprintf('Calibration Run %d\n',run);
    fprintf('=========================================\n');

    solverApp.printStructureParameters(ParamsApp, UncertApp, Title="Applicator Calibration");

    for ii = 1:measNum

        % Configure paint solver

        S = sparameters(folderPaths(run)+files(ii));

        gam = squeeze(S.Parameters(1,1,:));

        solverPaint.setInitialValues( ...
            Er=er,...
            Ur=ur,...
            Thk={thk_a(run), thk_pt_actual(ii)});

        [Params, ~, Uncert] = solverPaint.solveStructure(NL,f,gam);
        
        structureTitle = string(thk_pt_actual(ii) * 1e3) + " Micron Paint";
        
        solverPaint.printStructureParameters(Params, Uncert, Title=structureTitle);

        thk_pt(run,ii) = Params.thk(2);
    end

end

%% Return results

results.f               = f;
results.files           = files;
results.thk_actual      = thk_pt_actual;
results.thk_runs        = thk_pt;
results.thk_mean        = mean(thk_pt,1);
results.thk_std         = std(thk_pt,0,1);
results.app_thickness   = thk_a;

end