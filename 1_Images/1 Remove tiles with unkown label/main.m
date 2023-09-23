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
        
        chSlideTilesDir = [chRootDir,'\',stRootTileSubDirs(iSlideIdx).name];
        
        try
            
            %==================================================================================================================
            % check bad labels
            [c1chLabelmapPathsWithBadROILabels, c1chSlidesWithBadROILabels] =...
                TileImagesUtils.VerifyLabelmapsForBadROILabels([chSlideTilesDir,'\'], [0 1 2 3 4 5 6 7]);
            
            if ~isempty(c1chLabelmapPathsWithBadROILabels)
                warning("There are masks with bad labels, see BadLabels mat file.")
                save([Experiment.GetResultsDirectory(),'\BadLabels.mat'],'c1chMaskPathsWithBadLabels','c1chSlidesWithBadLabels');
            end
            
            % remove unlabelled tiles
            TileImagesUtils.RemoveTilesWithNoLabelmapInDir([chSlideTilesDir,'\'])
            
            % remove tiles with incomplete labelmaps
			% 0 = unknown label
            TileImagesUtils.RemoveTilesWithThisROILabel([chSlideTilesDir,'\'], 0,...
                'bRemoveForAnyAmountOfROILabel',true);
            
            %==================================================================================================================
            
        catch oMe
            chMsgID = 'TileImagesUtils:EmptyDir';
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