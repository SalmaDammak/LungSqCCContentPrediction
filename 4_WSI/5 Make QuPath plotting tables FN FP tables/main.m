% define threshold
dThreshold = 0.5;

chWorkspacePath = Experiment.GetDataPath('ResultsDir');

% get filenames and confidence
load(chWorkspacePath, 'vsiConfidences', 'vsFilenamesFromMATLAB', 'viTruth')

% just use the ones above threshold
vbPredictions = vsiConfidences >= dThreshold;

% make table
QuPathUtils.PreparePredictionTablesForPlotting(...
    vsFilenamesFromMATLAB,...
    vbPredictions, ...
    Experiment.GetResultsDirectory(),...
    'vdConfidences', double(vsiConfidences),...
    'vbTruth', viTruth,...
    'bAddFalseAndTrueNegativeAndPositiveColumns', true);


