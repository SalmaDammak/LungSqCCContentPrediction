stSlides = dir([Experiment.GetDataPath('TablesBaseDir'),'\TCGA*.csv']);

% 550 is assuming 100% PPV. Need to devide by PPV for actual number.
dNumReqTiles = ceil(550/.95);
disp("You need " + num2str(dNumReqTiles) + " cancer tiles per slide.")
vdNumCancerTilesPerslide = nan(length(stSlides), 1);
for iSlideIdx = 1:length(stSlides)
    
    
    chCurrentSlideFileName = stSlides(iSlideIdx).name;
    chCurrentSlideCSVFilePath = [Experiment.GetDataPath('TablesBaseDir'),'\', chCurrentSlideFileName];
    
    %=========================================================================%
    Experiment.StartNewSection(chCurrentSlideFileName(1:end-4))
    % IN PYTHON
    %=========================================================================%
    
    % Get paths in Python-compatible format
    chValDataCSVPathForPython = strrep(chCurrentSlideCSVFilePath,'\','\\');
    chResultsDir = [strrep(Experiment.GetResultsDirectory,'\','\\'),'\\'];
    chModelPath = strrep(Experiment.GetDataPath('Model'),'\','\\');
    
    % Use training batch size, not that it matters really...
    chBatchSize = '100';
    
    % Call Python
    c1chPythonScriptArguments = {...
        chValDataCSVPathForPython,...
        chResultsDir,...
        chBatchSize,...
        chModelPath};
    % Run the python code
    PythonUtils.ExecutePythonScriptInAnacondaEnvironment(...
        'main.py', c1chPythonScriptArguments,'C:\Users\sdammak\miniconda3', 'keras_env');
    
    % Load the mat file python drops its MATLAB-compatible variables in
    % This has: viTruth and vsiConfidences where si means single
    load([Experiment.GetResultsDirectory(),'\Workspace_in_python.mat'],'vsFilenames','vsiConfidences')
    
    %=========================================================================%
    % IN MATLAB
    %=========================================================================%
    % Check for alignment between matlab and python - Filenames
    c1xData = readcell(chCurrentSlideCSVFilePath);
    vsFilenamesFromMATLAB = strtrim(string(c1xData(:,1)));    
    vsFilenamesFromPython = strtrim(string(vsFilenames));
    
    if any(~(vsFilenamesFromMATLAB == vsFilenamesFromPython))
        save([Experiment.GetResultsDirectory(),'\ErrorWorkspace.mat']);
        error("MATLAB and Python test set filenames are not aligned")
    end
    
    % See how many tiles were predicted positive
    vdConfidences = double(vsiConfidences);
    vbPredictions = vdConfidences >= 1;
    dNumCancerTiles = sum(vbPredictions);  
    vdNumCancerTilesPerslide(iSlideIdx) = dNumCancerTiles;
    
    disp(string(chCurrentSlideFileName(1:end-4)) + " num cancer tiles: " + num2str(dNumCancerTiles));
    
    save([Experiment.GetResultsDirectory(),'\Workspace_in_MATLAB.mat'])  
    
end
