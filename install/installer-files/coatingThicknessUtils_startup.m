function coatingThicknessUtils_startup()

% Add coating-thickness-utils source folder to MATLAB path

libPath = "<LIBRARY_PATH>";

srcPath = fullfile(libPath, "src");

addpath(srcPath);

end