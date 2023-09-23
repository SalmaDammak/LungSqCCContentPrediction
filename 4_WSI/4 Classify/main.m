%=========================================================================%
Experiment.StartNewSection('Python')
%=========================================================================%
% Get paths in Python-compatible format
chValDataCSVPathForPython = strrep(Experiment.GetDataPath('TablesDir'),'\','\\');
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
load([Experiment.GetResultsDirectory(),'\Workspace_in_python.mat'],'vsFilenames','vsiConfidences','viTruth')

%=========================================================================%
Experiment.StartNewSection('MATLAB')
%=========================================================================%
% Check for alignment between matlab and python - Filenames
c1xData = readcell(Experiment.GetDataPath('TablesDir'));
vsFilenamesFromMATLAB = strtrim(string(c1xData(:,1)));
vsFilenamesFromMATLAB(1,:) = [];
vsFilenamesFromPython = strtrim(string(vsFilenames));

if any(~(vsFilenamesFromMATLAB == vsFilenamesFromPython))
    save([Experiment.GetResultsDirectory(),'\ErrorWorkspace.mat']);
    error("MATLAB and Python test set filenames are not aligned")
end

% Check for alignment between matlab and python - Ground truth
vdDifference = cell2mat(c1xData(2:end,2)) - double(viTruth');

% This is basically "isequal" with a tolerence of eps*10, which is
% 2.2204e-15
if any(vdDifference> eps*10)
    error('The MATLAB tTestTable is not aligned with Python ground truth.')
end
    
vdConfidences = double(vsiConfidences);

% Calculate metrics using BOLT
disp(newline + "Per tile error metrics using BOLT: ")
iPositiveLabel = int32(1);
dThreshold = 1;
viTruth = int32(viTruth');
[dAUC, dAccuracy, dTrueNegativeRate, dTruePositiveRate, dFalseNegativeRate, dFalsePositiveRate, tExcelFileMetrics]=...
    CalculateAllTheMetricsGivenThreshold(viTruth, vdConfidences, iPositiveLabel, dThreshold);

% Calculate positive predictive value
vdPredictions = double(vsiConfidences >= dThreshold);
dPPV = CaluclatePPV(vdPredictions, viTruth);
save([Experiment.GetResultsDirectory(),'\Workspace_in_MATLAB.mat'])


function dPPV = CaluclatePPV(vdPredictions, vdTruth)
dNumTruePositive = 0;
dNumFalsePositive = 0;

for i = 1:length(vdPredictions)
    if vdPredictions(i) == 1 && vdTruth(i) == 1
        dNumTruePositive = dNumTruePositive + 1;
    elseif vdPredictions(i) == 1 && vdTruth(i) == 0
        dNumFalsePositive = dNumFalsePositive + 1;
    end
    
end
dPPV = dNumTruePositive / (dNumTruePositive + dNumFalsePositive);
disp("PPV is: " + num2str(round(100*(dPPV)))+ "%")
end

function [dAUC, dAccuracy, dTrueNegativeRate, dTruePositiveRate, ...
    dFalseNegativeRate, dFalsePositiveRate, tExcelFileMetrics]=...
    CalculateAllTheMetricsGivenThreshold(viTruth, vdConfidences, iPositiveLabel, dThreshold)

dAUC = ErrorMetricsCalculator.CalculateAUC(viTruth, vdConfidences, iPositiveLabel);
disp("MATLAB AUC: " + num2str(dAUC,'%.2f'))

dMisclassificationRate = ErrorMetricsCalculator.CalculateMisclassificationRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);
dAccuracy = 1 - dMisclassificationRate;
disp("MATLAB accuracy is: " + num2str(round(100*(1-dMisclassificationRate)))+ "%")

dTrueNegativeRate = ErrorMetricsCalculator.CalculateTrueNegativeRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);
disp("MATLAB TNR is: " + num2str(round(100*(dTrueNegativeRate)))+ "%")

dTruePositiveRate = ErrorMetricsCalculator.CalculateTruePositiveRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);
disp("MATLAB TPR is: " + num2str(round(100*(dTruePositiveRate))) + "%")

dFalseNegativeRate = ErrorMetricsCalculator.CalculateFalseNegativeRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);

dFalsePositiveRate = ErrorMetricsCalculator.CalculateFalsePositiveRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);

tExcelFileMetrics = table(dAUC, dThreshold, dAccuracy, dTrueNegativeRate, dTruePositiveRate);
end
