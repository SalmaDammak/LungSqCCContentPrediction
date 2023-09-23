classdef DeconvolvedTileImagesUtils   
        
    methods (Access = public, Static = true)
        
        function m3iImage = ConvertTo3ChannelUint8Image(chPath, nameValueArgs)
            arguments
                chPath
                nameValueArgs.chWriteFilepath
            end
            
            % Read image
            m2sImage = imread(chPath);
            
            % make uint 8
            m2iImage = im2uint8(m2sImage);
                        
            % Make 3 channel
            m3iImage = cat(3, m2iImage, m2iImage, m2iImage);
            
            % Write image
            if contains(fields(nameValueArgs),'chWriteFilepath')
                imwrite(m3iImage, nameValueArgs.chWriteFilepath);
            end          
            
        end
        
        function chHematoxylinTileName = FindHematoxylinEquivalentName(chRawTileName, chHematoxylinDir)
            arguments
                chRawTileName (1,:) char
                chHematoxylinDir (1,:) char
            end
            
            % Get locations for information in brackets (has tile location
            % info)
            [dStartIdx, dEndIdx] = regexp(chRawTileName,'[.*\]');
            chLastBit = chRawTileName(dStartIdx:dEndIdx);
            chFirstBit = chRawTileName(1:dStartIdx-2);
                        
            % Add 'tif instead
            chLastBit = [chLastBit,'.tif'];
            
            % Should return exactly 1
            stTile = dir([chHematoxylinDir,'\',chFirstBit,'*',chLastBit]);
            if size(stTile,1) > 1
                error("More than one equivalent tile found.")
            elseif size(stTile,1) < 1
                error("No equivalent tiles found.")
            else            
            chHematoxylinTileName = stTile.name;
            end
            
        end
    end
    
end