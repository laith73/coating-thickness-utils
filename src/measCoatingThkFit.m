function Results = measCoatingThkFit(NL, folderPaths, baseMeasFile, ...
    f, eps_a, thk_a_guess, eps_c, thk_c_range)
%MEASUREDPAINTTHICKNESS Estimate paint thickness from repeated S11 measurements.
%
% Uses resonance frequency calibration to estimate coating thickness.
%
% Inputs
% ------
% NL : object
%       nLayerCircular object configured for the measurement setup.
%
% folderPaths : string array
%       Paths to folders containing repeated measurements.
%
% baseMeasFile : string
%       Applicator calibration measurement filename.
%
% f : vector
%       Frequency vector in GHz corresponding to the S-parameter data.
%
% eps_a : complex scalar
%       Initial applicator relative permittivity.
%
% thk_a_guess : double
%       Initial applicator thickness guess (mm).
%
% eps_c : complex scalar
%       Coating relative permittivity.
%
% thk_c_range : vector
%       Actual coating thickness values (um) corresponding to the
%       measurement files.
%
% Outputs
% -------
% Results : struct
%       Contains measured thicknesses and calibration information.
%
% Author: Laith Al Sairafi


%% Settings

numRuns = numel(folderPaths);
ur_a = 1.0 - 0.0j;


%% Read filenames

listing = dir(folderPaths(1));

files = string({listing(~[listing.isdir]).name})';

numbers = regexp(files,'^\d+','match');
numbers = cellfun(@(c) str2double(c{1}),numbers);

[~,idx] = sort(numbers);
files = files(idx);

measNum = numel(files);

%% Calibrate applicator

solver = nLayerInverse(1);
solver.setLayersToSolve(Thk=1);
solver.setInitialValues(Er=eps_a, Ur=ur_a, Thk=thk_a_guess);

% Average calibration measurement
gamCal = zeros(numel(f),1);

for run = 1:numRuns
    S = sparameters(folderPaths(run)+baseMeasFile);
    gamCal = gamCal + squeeze(S.Parameters(1,1,:));
end

gamCal = gamCal/numRuns;

[Params,~,Uncert] = solver.solveStructure(NL,f,gamCal);

thk_a = Params.thk;
eps_a = Params.er;


fprintf('\n========================================\n');
fprintf('Applicator Calibration\n');
fprintf('========================================\n');

solver.printStructureParameters(Params, Uncert,Title="Applicator");

%% Generate resonance frequency calibration

calResults = resFreqVsThkCal(NL, eps_a, thk_a, eps_c=eps_c, thk_c_range=thk_c_range);

fprintf('\nResonance Calibration R^2 = %.6f\n',calResults.R2);

p = calResults.coeffs;


%% Extract thickness from measurements

thk_runs = zeros(numRuns,measNum);
resFreq = zeros(numRuns,measNum);

for run = 1:numRuns

    fprintf('\nProcessing Run %d/%d\n',run,numRuns);

    for ii = 1:measNum

        % Read S11 measurement
        S = sparameters(folderPaths(run)+files(ii));
        gam = squeeze(S.Parameters(1,1,:));


        % Calculate gamma(f)
        gamma = gammaFunction(f,gam);

        % Find resonant frequency
        [~,idx] = min(gamma);
        f_res = f(idx);
        resFreq(run,ii) = f_res;

        % Convert frequency to thickness
        thk_est = polyval(p,f_res);

        % Check calibration range
        if thk_est < min(calResults.thickness) || ...
                thk_est > max(calResults.thickness)

            warning(['Estimated thickness %.2f um is outside ' ...
                'calibration range.'], thk_est);
        end


        thk_runs(run,ii) = thk_est;
    end

end

%% Return Results

Results.f                  = f;
Results.files              = files;
Results.thk_runs           = thk_runs;
Results.thk_mean            = mean(thk_runs,1);
Results.thk_std             = std(thk_runs,0,1);
Results.resFreq             = resFreq;

% Applicator calibration
Results.app_thickness       = thk_a;
Results.app_permittivity    = eps_a;

% Resonance calibration
Results.calibration         = calResults;


end