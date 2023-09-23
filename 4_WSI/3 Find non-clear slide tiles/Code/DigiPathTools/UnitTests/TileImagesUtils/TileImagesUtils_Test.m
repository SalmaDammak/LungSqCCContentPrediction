classdef TileImagesUtils_Test < matlab.unittest.TestCase
    
    properties
        sTargetResolution = "0.2520";
        dTargetSize_pixels = 224;
        sBasePath = pwd + "\UnitTests\TileImagesUtils\tiles\57microns\";
        sScannedAtPoint2520 = "TCGA-33-4547-01Z-00-DX1.7009df06-03f9-497a-b7bd-f8ef4244d152";
        sScannedAtPoint5040 = "TCGA-39-5022-01Z-00-DX1.1bf6a4da-0b59-4478-bcf1-b004f0356342";
        sScannedAtPoint2517 = "TCGA-58-A46N-01Z-00-DX1.5D51252C-5294-4E40-ABB2-31C3BE1039F8";
        sScannedAtPoint2265 = "TCGA-94-A5I4-01Z-00-DX1.F0CE4558-63A7-45FB-BA8C-1B20AB29A847";        
    end
    
    % *********************************************************************
    % *                    ResizeTilesAndLabelmaps                        *
    % ********************************************************************* 
    methods (Test)
       
        % Correct use
        function SizeUp(testCase)            
            sSlideDir = testCase.sBasePath + testCase.sScannedAtPoint5040 + "\";
            sOutputDir = testCase.sBasePath + testCase.sScannedAtPoint5040 + "_temp\";
            mkdir(sOutputDir)

            % Call to function that I want to test
            TileImagesUtils.ResizeTilesAndLabelmaps(sSlideDir, testCase.dTargetSize_pixels, 'chOutputDir', sOutputDir)
            
        end      
        
    end
    
    % *********************************************************************
    % *                 MoveTilesAndLabelmapsOfClearSlide                 *
    % *********************************************************************
    methods(Test)
        function MoveClearSlide_CorrectUse(testCase)
            chInputDir = 'E:\Users\sdammak\Repos\DigiPathTools\UnitTests\TileImagesUtils\ClearSlide\';            
            chOutputDir = 'E:\Users\sdammak\Repos\DigiPathTools\UnitTests\TileImagesUtils\ClearSlide\output\';
            
            % Run test and compare to manually slected expected tiles
            vsClearTiles = TileImagesUtils.MoveTilesAndLabelmapsOfClearSlide(...
                chInputDir, chOutputDir, 'dMaxPercentClear',0.50);
            vsExpectedTiles = [...
                "TCGA-22-5489-01Z-00-DX1.0518AF53-5642-40FB-A631-4C50D7707C8F [d=0.99802,x=11848,y=61925,w=224,h=224].png",...
                "TCGA-33-6738-01Z-00-DX5.4af96952-d323-4d2e-9871-e590b7c5f59d [x=3136,y=26656,w=224,h=224].png",...
                "TCGA-33-6738-01Z-00-DX5.4af96952-d323-4d2e-9871-e590b7c5f59d [x=3360,y=23744,w=224,h=224].png",...
                "TCGA-33-6738-01Z-00-DX5.4af96952-d323-4d2e-9871-e590b7c5f59d [x=3808,y=25312,w=224,h=224].png","TCGA-NK-A5CX-01Z-00-DX1.CA1C230C-7A29-491B-A124-7D3B600DAFB7 [d=0.99723,x=168428,y=67907,w=224,h=224].png"];
            
            verifyEqual(testCase, vsClearTiles, vsExpectedTiles);
            
            % Return tiles to original folder
            stMovedFiles = dir(chOutputDir);
            stMovedFiles(1:2) = [];
            if ~isempty(stMovedFiles)
                for iFile = 1:length(stMovedFiles)
                    chMovedFile = [chOutputDir, stMovedFiles(iFile).name];
                    copyfile(chMovedFile, chInputDir)
                    delete(chMovedFile)
                end
            end
            
        end
    end
end