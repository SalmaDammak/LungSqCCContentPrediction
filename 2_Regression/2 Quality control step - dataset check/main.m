chBasePath = fullfile(Experiment.GetDataPath('TileTablesEXP'), 'Results');

% Get folder names in this general fashion instead of by using the set
% names in case I ever decide to name the sets differently (e.g. cross val)
% or if only make 2 sets
stFolderNames = dir(chBasePath);
stFolderNames = stFolderNames([stFolderNames.isdir], :);
stFolderNames(1:2,:) = [];

c1c1vsUniqueCentreIDs = cell(length(stFolderNames), 1);
for iSetIdx = 1:length(stFolderNames)
    
    % Load each set that is getting passed to Python
    chSetFoldername = stFolderNames(iSetIdx).name;
    chSetPath = fullfile(chBasePath, chSetFoldername, 'TilesWithScalarTargets.csv');
    tData = readtable(chSetPath);    
    vsPaths = string({tData.c1sPaths{:}}');
    
    % Get the unique IDs, for this set of experiments, I want the centre
    % IDs, which is the first output of this TCGAUtils.GetIDsFromTileFilepaths
    c1c1vsUniqueCentreIDs{iSetIdx} = {unique(TCGAUtils.GetIDsFromTileFilepaths(vsPaths))};    
end

for iSetIdx = 1:length(stFolderNames)
    
    % Grab IDs for each set
    vsCurrentSetIDs = c1c1vsUniqueCentreIDs{iSetIdx}{:};
    chCurrentSetName = stFolderNames(iSetIdx).name;
    
    for iOtherSetIdx = 1:length(stFolderNames)
        
        % Compare them to every other set
        if iSetIdx ~= iOtherSetIdx
        chOtherSetName = stFolderNames(iOtherSetIdx).name;
        vsOtherSetIDs = c1c1vsUniqueCentreIDs{iOtherSetIdx}{:};
        vsCentresInCommon = intersect(vsCurrentSetIDs, vsOtherSetIDs);
        
        if isempty(vsCentresInCommon)
            disp([chCurrentSetName, ' & ', chOtherSetName, ' do NOT have centre IDs in common.' ])    
        else
            warning([chCurrentSetName, ' & ', chOtherSetName, ' DO have centre IDs in common. ' ])
        end
        end
    end
end
