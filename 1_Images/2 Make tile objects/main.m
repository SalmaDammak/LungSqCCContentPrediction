% Foci = regions selected by pathologist for contouring
% NCNT = Non Cancer Non Tumour (used to augment training)
c1chROITypeNames = {'Foci', 'NCNT'};
chPartialRootDir = Experiment.GetDataPath('RootTileDir');

for iROITypeIdx = 1:length(c1chROITypeNames)
    
    chROITypeName = c1chROITypeNames{iROITypeIdx};
    Experiment.StartNewSection(chROITypeName)
    
    chRootDir = [chPartialRootDir, '_', chROITypeName];
    stRootTileSubDirs = dir([chRootDir,'\TCGA*']);
    
    %for each dir
    for iSlideIdx = 1:length(stRootTileSubDirs)
        
        chSlideName = stRootTileSubDirs(iSlideIdx).name;
        disp(['(', num2str(iSlideIdx), '/', num2str(length(stRootTileSubDirs)),') ', chSlideName])
        Experiment.StartNewSubSection(chSlideName)
        
        chSlideTilesDir = [chRootDir,'\',stRootTileSubDirs(iSlideIdx).name, '\'];
        
        try
            
            %==================================================================================================================
            % Create mask targets
            voTilesWithMaskTargets = BinaryMaskTarget.MakeTilesWithMaskTargetsFromDir...
                (string(chSlideTilesDir), "CancerNoCancerMasks", 'sPartialFileDirectory',string(Experiment.GetResultsDirectory()),'bFromTCGA', true);
            save(fullfile(Experiment.GetResultsDirectory(), 'TilesWithMaskTargets.mat'), 'voTilesWithMaskTargets','-v7.3')
            
            % Create scalar targets
            voTilesWithScalarTargets = BinaryMaskTarget.ConvertTilesBinaryMaskTargetsToPercentCoverageTargets(voTilesWithMaskTargets);
            save(fullfile(Experiment.GetResultsDirectory(), 'TilesWithScalarTargets.mat'), 'voTilesWithScalarTargets','-v7.3')
            
            % Create binary targets (>0% cancer = cancer, 0% cancer = non-cancer)
            dMinPercent = 0;
            voTilesWithBinaryTargets = ScalarTarget.ConvertTilesScalarTargetsToBinaryScalarTargets(...
                voTilesWithScalarTargets, 'dPositiveIsMoreThanThreshold', dMinPercent);
            save(fullfile(Experiment.GetResultsDirectory,'TilesWithBinaryTargets.mat'),'voTilesWithBinaryTargets','-v7.3')
            
            % Make into table
            tData = TileWithTarget.ConvertToTableForPython(voTilesWithBinaryTargets);
            save(fullfile(Experiment.GetResultsDirectory,'TilesWithBinaryTargetsTable.mat'),'tData','-v7.3');
            
            % Make into csv file for python use later
            writetable(tData,...
                fullfile(Experiment.GetResultsDirectory, 'TilesWithBinaryTargets.csv'), 'FileType', 'text', 'delimiter',',');
            
            % Create summary stats
            dNumTiles = length(voTilesWithBinaryTargets);
            dNumPositiveTiles = sum([tData.c1xLabels{:}]);
            [sCentreIDs, sPatientIDs, sSlideIDs] = TCGAUtils.GetIDsFromTileFilepaths(string(chSlideName), 'bSlideNamesNotTilesGiven', true);
            
            save(fullfile(Experiment.GetResultsDirectory,'Summary.mat'),'dNumTiles', 'dNumPositiveTiles','sCentreIDs', 'sPatientIDs', 'sSlideIDs','-v7.3');
            disp("Num tiles: " + num2str(dNumTiles))
            disp("Num positive: " + num2str(dNumPositiveTiles) + " (" + num2str(100*dNumPositiveTiles/dNumTiles, '%.f') + "%)")
            %==================================================================================================================
            
        catch oMe
            chMsgID = 'BinaryMaskTarget:EmptyDir';
            if strcmp(chMsgID, oMe.identifier)
                warning("This directory does not have tiles.")
            else
                rethrow(oMe)
            end
        end
        
        disp(newline)
        Experiment.EndCurrentSubSection()
    end
    Experiment.EndCurrentSection();
end