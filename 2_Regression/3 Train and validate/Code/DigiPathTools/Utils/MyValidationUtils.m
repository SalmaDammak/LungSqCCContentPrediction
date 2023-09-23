classdef MyValidationUtils
    
    % DIR
    methods (Static = true, Access = public)
        
        function MustBeDirPath(chDirPath)
            arguments
                chDirPath (1,:) char
            end
            
            % Directory paths must end in a backslash
            if ~strcmp(chDirPath(end),'\')
                error("Directory paths must end in a backslash.")
            end            
        end
        
        function MustBeExistingDir(chDirPath)
            arguments
                chDirPath (1,:)
            end
            
            if ~exist(chDirPath, 'Dir')
                error("Directory does not exist.")
            end
        end        
        
        function MustBeNonEmptyDir(chDirPath)
            arguments
                chDirPath (1,:)
            end
            
            stDirContent = dir(chDirPath);
            
            % Remove the '.' '..' since they artificially makt eht
            % directory look non-empty
            stDirContent = stDirContent(~ismember({stDirContent.name},{'.','..'}));

            if isempty(stDirContent)
                error("The target directory is empty. Please provide an alternative directory that isn't.")
            end
        end
    end
    
    % FILE
    methods (Static)
        
        function MustBeExistingFile(chFilePath)
            arguments
                chFilePath (1,:)
            end
            
            if ~exist(chFilePath, 'file')
                error("File does not exist.")
            end
        end
        
        function MustBeA2DImageFilepath(chFilePath)
            % fileparts fails silently if there is a period in the name, so
            % 
            chExtentsion = regexp(chFilePath, '.*\.([a-zA-Z]+)', 'tokens','once');
            
            vsAllowableImageExtensions = ["png","tif","tiff"];
            sExtension = intersect(string(chExtentsion), vsAllowableImageExtensions);
            
            if isempty(sExtension)
                error("Not a 2D image. Allowable types are: png, tif, or tiff.")
            end
        
        end
    end
    
end