% Parameters
chLearningRate =  '0.01';
chBatchSize = '100';
chMaxEpochs = '20'; 
dThreshold = .5;

% Get paths
chBasePath = Experiment.GetDataPath('TablesDir');
chTrainFolderName = '01 Train';
chValFolderName = '02 Val';
chTrainCSVPath = [chBasePath, chTrainFolderName,'\TilesWithScalarTargets.csv'];
chValTablePath = [chBasePath, chValFolderName, '\TilesWithScalarTargetsTable.mat'];

%=========================================================================%
Experiment.StartNewSection('In python')
%=========================================================================%
% Create datapaths in the format python uses
chTrainDataCSVPathForPython = strrep(chTrainCSVPath,'\','\\');
chValDataCSVPathForPythong = strrep(chTrainDataCSVPathForPython, chTrainFolderName, chValFolderName);
chResultsDir = [strrep(Experiment.GetResultsDirectory,'\','\\'),'\\'];

% Set up parameters as strings to be parsed by python script to the correct
% type
chExpFolderName = pwd();
chExpFolderName = chExpFolderName(end-11:end);

c1chPythonScriptArguments = {...
    chTrainDataCSVPathForPython,...
    chValDataCSVPathForPythong,...
    chResultsDir,...
    chMaxEpochs,... 
    chLearningRate,... 
    chBatchSize,... 
    chExpFolderName};

% Run the python code
PythonUtils.ExecutePythonScriptInAnacondaEnvironment(...
    'main.py', c1chPythonScriptArguments,'C:\Users\sdammak\miniconda3', 'keras_env');

% Load the mat file python drops its MATLAB-compatible variables in
% This has: viTruth and vsiConfidences where si means single 
load([Experiment.GetResultsDirectory(),'\Workspace_in_python.mat'],'vsFilenames', 'viTruth','vsiConfidences')

%=========================================================================%
Experiment.StartNewSection('In MATLAB')
%=========================================================================%
try
	% Check for alignment between matlab and python - Filenames
	load(chValTablePath, 'tData');

	vsFilenamesFromMATLAB = strtrim(string(tData.c1sPaths)); 
	vsFilenamesFromPython = strtrim(string(vsFilenames));

	if any(~(vsFilenamesFromMATLAB == vsFilenamesFromPython))
		save([Experiment.GetResultsDirectory(),'\ErrorWorkspace.mat']);
		error("MATLAB and Python test set filenames are not aligned")
	end

	% Check for alignment between matlab and python - Ground truth
	vdDifference = double([tData.c1xLabels{:}]') - double(viTruth');

    % This is basically "isequal" with a tolerence of eps*10, which is
    % 2.2204e-15
	if any(vdDifference> eps*10)
		error('The MATLAB tTestTable is not aligned with Python ground truth.')
	end

	% For90% +ve
	disp(newline + "Per tile classification error metrics (90% cutoff) using BOLT: ")
	dCutOff = 0.9;
	iPositiveLabel = int32(1);
	vdBinaryTruth = int32(viTruth' > dCutOff);
	vdBinaryConfidences = double(double(vsiConfidences) > dCutOff);
	[dAUC, dAccuracy, dTrueNegativeRate, dTruePositiveRate, dFalseNegativeRate, dFalsePositiveRate, tExcelFileMetrics]=...
		CalculateAllTheMetricsGivenThreshold(vdBinaryTruth, vdBinaryConfidences, iPositiveLabel, dThreshold);

	% Calculate positive predictive value
	vdPredictions = vdBinaryConfidences;
	vdPositiveSamplePredictions = vdPredictions(vdBinaryTruth == 1);
	dPPV = sum(vdPositiveSamplePredictions)/sum(vdBinaryTruth);
	disp("PPV is: " + num2str(round(100*(dPPV)))+ "%")
catch oMe
	save([Experiment.GetResultsDirectory(),'\Workspace_in_MATLAB.mat'])
end
save([Experiment.GetResultsDirectory(),'\Workspace_in_MATLAB.mat'])

function [dAUC, dAccuracy, dTrueNegativeRate, dTruePositiveRate, ...
    dFalseNegativeRate, dFalsePositiveRate, tExcelFileMetrics]=...
    CalculateAllTheMetricsGivenThreshold(viTruth, vdConfidences, iPositiveLabel, dThreshold)

dAUC = ErrorMetricsCalculator.CalculateAUC(viTruth, vdConfidences, iPositiveLabel);
disp("BOLT AUC: " + num2str(dAUC,'%.2f'))

dMisclassificationRate = ErrorMetricsCalculator.CalculateMisclassificationRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);
dAccuracy = 1 - dMisclassificationRate;
disp("BOLT accuracy is: " + num2str(round(100*(1-dMisclassificationRate)))+ "%")

dTrueNegativeRate = ErrorMetricsCalculator.CalculateTrueNegativeRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);
disp("BOLT TNR is: " + num2str(round(100*(dTrueNegativeRate)))+ "%")

dTruePositiveRate = ErrorMetricsCalculator.CalculateTruePositiveRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);
disp("BOLT TPR is: " + num2str(round(100*(dTruePositiveRate))) + "%")

dFalseNegativeRate = ErrorMetricsCalculator.CalculateFalseNegativeRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);

dFalsePositiveRate = ErrorMetricsCalculator.CalculateFalsePositiveRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);

tExcelFileMetrics = table(dAUC, dThreshold, dAccuracy, dTrueNegativeRate, dTruePositiveRate);
end