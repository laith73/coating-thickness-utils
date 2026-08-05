function coatingThicknessUtils_install(options)
%COATINGTHICKNESSUTILS_INSTALL Install coating-thickness-utils.
%
% This function:
%   - Creates the MATLAB startup.m file if it does not exist.
%   - Adds coatingThicknessUtils_startup() to startup.m.
%   - Copies the startup function to the userpath directory.
%   - Runs the startup function.
%
% Author: Laith Al Sairafi

arguments
    options.ShowFinishedPopup(1,1) logical = true;
end

%% Paths and filenames

startupLineSearch = "coatingThicknessUtils_startup(";
startupLineFull = "coatingThicknessUtils_startup();";

startupFileName = "coatingThicknessUtils_startup.m";

libName = "coating-thickness-utils";
libPath = fileparts(fileparts(mfilename("fullpath")));

startupLocation = userpath();
startupFilePath = fullfile(startupLocation, "startup.m");


%% Create startup.m if it does not exist

if isempty(dir(startupFilePath))
    writelines("", startupFilePath);
end


%% Add startup call

startupLines = readlines(startupFilePath);

hasStartupLine = startsWith(startupLines, startupLineSearch);

if ~any(hasStartupLine)
    writelines(startupLineFull, ...
        startupFilePath, ...
        WriteMode="append");
end


%% Copy startup function to userpath

startupSource = fullfile(libPath, ...
    "install", ...
    "installer-files", ...
    startupFileName);

startupLines = readlines(startupSource);

% Replace repository path placeholder
startupLines = strrep(startupLines, ...
    "<LIBRARY_PATH>", libPath);

writelines(startupLines, ...
    fullfile(startupLocation, startupFileName));


%% Remove old versions from MATLAB path

pathAll = split(path(), pathsep());

oldPaths = pathAll(startsWith(pathAll, libPath));

if ~isempty(oldPaths)
    rmpath(oldPaths{:});
end


%% Run startup

coatingThicknessUtils_startup();


%% Finished message

if options.ShowFinishedPopup
    msgbox(sprintf("Library '%s' was successfully installed.", libName), ...
        sprintf("'%s Installer'", libName));
end

end