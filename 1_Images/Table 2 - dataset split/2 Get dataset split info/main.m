chBaseDir = Experiment.GetDataPath('Datasets');
stSets = dir([chBaseDir, '\*.mat']);

% Loop through datasets
for iSetIdx =   1:length(stSets)
    % Load num centers, num patients, num tiles, and the tiles themselves
    chSetName = stSets(iSetIdx).name;
    chPath = [chBaseDir, '\', chSetName];
    load(chPath,"dNumCenters_Tiss", "dNumPatients_Tiss", "dNumSlides_Tiss", "dNumTiles_Tiss", "dNumTiles");

    tSetResults = table(dNumCenters_Tiss, dNumPatients_Tiss, dNumSlides_Tiss, dNumTiles, dNumTiles_Tiss,...
        'RowNames', {erase(chSetName, '.mat')});
    if iSetIdx == 1
        tResults = tSetResults;
    else
        tResults = [tResults; tSetResults];
    end

end

%disp(tResults)
save([Experiment.GetResultsDirectory(), '\DatasetSplit.mat'],'tResults')
writetable(tResults, [Experiment.GetResultsDirectory(), '\DatasetSplit.xlsx'])