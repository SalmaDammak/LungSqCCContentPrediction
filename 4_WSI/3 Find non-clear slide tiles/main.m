load(Experiment.GetDataPath('Table'), 'tData')
disp(num2str(height(tData)))
chSlideName = 'TCGA-22-1012-01Z-00-DX1.053F81FA-F91A-42B0-8F12-CD2495FA9E99';

% Intialize list
vbMostlyClearTile = false(height(tData), 1);

% Find mostly clear tiles
for iTileIdx = 1:height(tData)
    chTilePath = char(tData.c1sPaths{iTileIdx});
    
    try
        dPercentClear = TileImagesUtils.FindClearSlidePercentInTile(chTilePath);
    catch oMe
        if strcmp(oMe.identifier, 'MATLAB:imagesci:png:libraryFailure')
            warning(['Png error. Tile idx: ', num2str(iTileIdx)])
        else
            rethrow(oMe)
        end
    end
    
    if dPercentClear > .5
        vbMostlyClearTile(iTileIdx) = true;
    end
end

% Create tables for these blank tiles
tClearTiles = tData(vbMostlyClearTile,:);
chClearTargetCSVFilepath = fullfile(Experiment.GetResultsDirectory(), [chSlideName,'_MostlyClear.csv']);
writetable(tClearTiles,chClearTargetCSVFilepath, 'FileType', 'text', 'delimiter',',');

% Create new CSV for classification
tNonClearTiles = tData(~vbMostlyClearTile,:);
chNonClearTargetCSVFilepath = fullfile(Experiment.GetResultsDirectory(), [chSlideName, '.csv']);
writetable(tNonClearTiles,chNonClearTargetCSVFilepath, 'FileType', 'text', 'delimiter',',');
