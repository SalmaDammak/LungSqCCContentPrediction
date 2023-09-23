% define threshold
dThreshold = 1;

%%% create tables
chBaseDir = Experiment.GetDataPath('ResultsDir');
stSlides = dir([chBaseDir, '\* TCGA*']);

% loop through all slides
for iSlideIdx = 1:length(stSlides)
    
    chWorkspacePath = [chBaseDir, '\', stSlides(iSlideIdx).name,'\Workspace_in_MATLAB.mat'];
    
    % get filenames and confidence
    load(chWorkspacePath, 'vsiConfidences', 'vsFilenamesFromMATLAB')
    
    % just use the ones above threshold
    vbTilesToKeep = vsiConfidences >= dThreshold;
    vsPredictedCancerFilenames = vsFilenamesFromMATLAB(vbTilesToKeep);
    vdConfidences = double(vsiConfidences);
    vdConfidences = vdConfidences(vbTilesToKeep);
    
    % use predictions to signal upper threshold
    vbPredictions = vdConfidences >= dThreshold;
        
    % make table
    QuPathUtils.PreparePredictionTablesForPlotting(...
    vsPredictedCancerFilenames,...
    vbPredictions, ...
    Experiment.GetResultsDirectory());
end

%%% prepare list of slides to load into QuPath
% Add source folder and change the extension
chSlideFolder = Experiment.GetDataPath('SlideDir');
c1chSlideNames = dir([Experiment.GetResultsDirectory(),'\TCGA*']);
c1chSlideNames = {c1chSlideNames.name}';
c1chSlidePaths = cellfun(@(c) [chSlideFolder,'\', strrep(c, '.csv', '.svs')], c1chSlideNames, 'UniformOutput', false);

% prepare text file for QuPath project
chFileName = [Experiment.GetResultsDirectory(),'\1SlidesForQuPathProject.txt'];
writecell(c1chSlidePaths,chFileName)

%%% prepare base path for csv files in Groovy-friendly format
% Write path with forward slashes to copy into Groovy script 
chFileName = [Experiment.GetResultsDirectory(),'\1Path.txt'];
writecell({strrep(Experiment.GetResultsDirectory(),'\','/')},chFileName);
