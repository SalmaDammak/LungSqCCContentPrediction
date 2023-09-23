chBaseDir = Experiment.GetDataPath('Datasets');
stDirs = dir([chBaseDir, '\*\TilesWithScalarTargets.csv']);

for iDirIdx = 1:length(stDirs)
    chPath = [stDirs(iDirIdx).folder, '\', stDirs(iDirIdx).name];
    [~, chDirName] = fileparts(stDirs(iDirIdx).folder);
    disp(chDirName)

    tTiles = readtable(chPath);

    [dNumCenters, dNumPatients, dNumSlides, dNumTiles] = GetInfo(tTiles);

    % Find clear slide tiles
    vbMostlyClearTile = findMostlyClearTiles(tTiles.c1sPaths);
    tTissueTiles = tTiles(~vbMostlyClearTile, :);

    [dNumCenters_Tiss, dNumPatients_Tiss, dNumSlides_Tiss, dNumTiles_Tiss] = GetInfo(tTissueTiles);

    if (dNumCenters ~= dNumCenters_Tiss || dNumPatients ~= dNumPatients_Tiss)...
            || (dNumSlides ~= dNumSlides_Tiss)
        warning("Something changed after finding clear tiles that wasn't supposed to")
        disp(chDirName)
    end
    save([Experiment.GetResultsDirectory(), '\', chDirName, '.mat'])

end


function [dNumCenters, dNumPatients, dNumSlides, dNumTiles] = GetInfo(tTiles)

[vsCentreIDs, vsPatientIDs, vsSlideIDs, vsTileIDs] = TCGAUtils.GetIDsFromTileFilepaths(tTiles.c1sPaths);
dNumCenters = length(unique(vsCentreIDs));
dNumPatients = length(unique(vsPatientIDs));
dNumSlides = length(unique(vsSlideIDs));
dNumTiles = length(unique(vsTileIDs));

end


function vbMostlyClearTile = findMostlyClearTiles(vsFilenamesFromMATLAB)
vbMostlyClearTile = false(length(vsFilenamesFromMATLAB), 1);

for iTileIdx = 1:numel(vsFilenamesFromMATLAB)

    chTilePath = char(vsFilenamesFromMATLAB(iTileIdx));
    dPercentClear = TileImagesUtils.FindClearSlidePercentInTile(chTilePath);

    if dPercentClear > .5
        vbMostlyClearTile(iTileIdx) = true;
    end
end
end