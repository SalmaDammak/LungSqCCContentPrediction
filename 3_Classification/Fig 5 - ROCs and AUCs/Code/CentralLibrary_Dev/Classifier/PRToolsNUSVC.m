classdef PRToolsNUSVC < PRToolsClassifier
    %PRToolsNUSVC
    %
    % PRToolsNUSVC Classifier optimises a support vector classifier for the dataset by quadratic  programming.
    % The difference with the standard SVC routine is the use and
    % interpretation of the regularisation parameter NU. It is an
    % upperbound  for the expected classification error. By default NU is
    % estimated by the  leave-one-error of the 1_NN rule. For NU = NaN an
    % automatic optimisation  is performed using REGOPTC.
    
    % Primary Author: Salma Dammak
    % Created: Jun 8, 2023
    
     
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private
    properties (SetAccess = immutable, GetAccess = public)
        sName = "PRTools nu-Algorithm Support Vector Machine Classifier";
        hClassifier = [];
        lsValidHyperParameterNames = ["Adaboost","KernelType","KernelOrder","NU"]
    end
        
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static
    % *                          PUBLIC METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
    methods
        function obj = PRToolsNUSVC(chClassifierHyperParametersFileName,oHyperParameterOptimizer, NameValueArgs)      
            %obj = PRToolsNUSVC(chClassifierHyperParametersFileName)
            %
            % SYNTAX:
            %  obj = PRToolsNUSVC(chClassifierHyperParametersFileName)
            %
            % DESCRIPTION:
            %  Constructor for PRToolsNUSVC, it assigns the mapping and even though it has a path for
            %   optimization now, this is currently not implemented for PRTools.
            %
            % INPUT ARGUMENTS:
            %  chClassifierHyperParametersFileName This is a .mat file containing all the 
            %       hyperparameter information.
            %       A default settings mat file for this classifier is found under: 
            %       BOLT > DefaultInputs > Classifier
            %
            % OUTPUTS ARGUMENTS:
            %  obj: Constructed object
            
            % Primary Author: Salma Dammak
            % Created: Jun 8, 2023           
            arguments
                chClassifierHyperParametersFileName
                % This can be any concrete class inheriting from HyperParameterOptimizer since it
                % won't be used anywhere but to pass an object that can be checked by the parent
                % class which checks for the abstract parent class. Since we don't have a PRTools
                % optimizer right now we can just use the MATLAB one for validation purposes.
                oHyperParameterOptimizer = MATLABMachineLearningHyperParameterOptimizer.empty
                NameValueArgs.JournalingOn (1,1) logical = true
            end
            
            % Call PRToolsClassifier constructor
            obj@PRToolsClassifier(chClassifierHyperParametersFileName, oHyperParameterOptimizer)
            
            % Assign the prtools mapping
            obj.hClassifier = @nusvc; % This is a PRTools "mapping"
        end
    end
    
    % *********************************************************************
    % *                         PROTECTED METHODS                         *
    % *********************************************************************
  
    methods (Access = protected)
        function c1xHyperParams = GetImplementationSpecificParameters(obj) 
            %c1xHyperParams = GetImplementationSpecificParameters(obj)  
            %
            % SYNTAX:
            %  c1xHyperParams = GetImplementationSpecificParameters(obj) 
            %
            % DESCRIPTION:
            %  Grabs hyperparameters for classifier training that are specific
            %  to the PRTools classifier
            %
            % INPUT ARGUMENTS:
            %  obj: Classifier object        
            %
            % OUTPUTS ARGUMENTS:
            %  c1xHyperParams: hyper parameters that are in order of how they
            %  should appear as input to the function (PRTools classifiers are
            %  hardcoded this way)

            % Check for unused parameters - warning
            obj.CheckForUnusedParameters();
            
            % set up cell array to hold hyperparameters
            iKernelTypeIdx = find(cellfun(@(x)strcmp(x,"KernelType"),obj.tHyperParameterStates{:,'sName'}));
            iKernelOrderIdx = find(cellfun(@(x)strcmp(x,"KernelOrder"),obj.tHyperParameterStates{:,'sName'}));
            iNuIdx = find(cellfun(@(x)strcmp(x,"NU"),obj.tHyperParameterStates{:,'sName'}));
            
            chKernelType = obj.tHyperParameterStates{iKernelTypeIdx,'c1xUserInputValue'}{:};
            dKernelOrder = obj.tHyperParameterStates{iKernelOrderIdx,'c1xUserInputValue'}{:};
            fhKernel = proxm(chKernelType,dKernelOrder);
            
            dNu = obj.tHyperParameterStates{iNuIdx,'c1xUserInputValue'}{:};
            
            c1xHyperParams = {fhKernel, dNu};
        end
    end
end