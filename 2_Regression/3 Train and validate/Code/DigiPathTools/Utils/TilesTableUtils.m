classdef TilesTableUtils
    %TileTableUtils
    %
    % A collection of uttilities to prepare and modify the tables
    % containing tile information in the format my python code currently
    % requires it to be.
    
    % Primary Author: Salma Dammak
    % Created: Jun 22, 2022
    
    methods (Static)
        
        function tTiles = MakeTableFromSlideFolder(sTileAndLabelmapDir, chTargetCSVFilepath)
            arguments
                sTileAndLabelmapDir (1,1) string {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
                chTargetCSVFilepath
            end
            
            stTileFilePaths = dir(fullfile(sTileAndLabelmapDir, QuPathUtils.sImageRegexp));
            c1chFullPaths = cellfun(@(a,b) [a, '\', b], {stTileFilePaths.folder}', {stTileFilePaths.name}', 'UniformOutput', false);
            tTiles = string(c1chFullPaths);            
            
            writecell(c1chFullPaths,chTargetCSVFilepath, 'FileType', 'text', 'delimiter',',');
            
        end
        
    end
end

