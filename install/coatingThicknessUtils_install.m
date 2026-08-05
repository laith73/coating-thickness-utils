function coatingThicknessUtils_install()

% Get repository root (one level above install folder)
repoPath = fileparts(fileparts(mfilename("fullpath")));

% Add source folder
srcPath = fullfile(repoPath, "src");
addpath(srcPath);

fprintf("coating-thickness-utils installed successfully.\n");

end