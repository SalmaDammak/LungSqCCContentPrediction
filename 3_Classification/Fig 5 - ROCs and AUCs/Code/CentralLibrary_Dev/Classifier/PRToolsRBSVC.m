classdef PRToolsRBSVC < PRToolsClassifier
    %PRToolsRBSVC
    %
    % PRToolsRBSVC Classifier optimises a support vector classifier for the
    % dataset using the radial basis kernel. 
    % See: http://prtools.tudelft.nl/prhtml/prtools/rbsvc.html
    % "This routine computes a classifier by NUSVC using a radial basis kernel  
    % with an optimised standard deviation by REGOPTC. The resulting classifier  
    % W is identical to NUSVC(A,KERNEL,NU). As the kernel optimisation is based  
    % on internal cross-validation the dataset A should be sufficiently large.  
    % Moreover it is very time-consuming as the kernel optimisation needs  
    % about 100 calls to SVC.
    % If any class in A has less than 20 objects, the kernel is not optimised  
    % by a grid search but by PKSVM, using the Parzen kernel.
    % Note that SVC is basically a two-class classifier. The kernel may
    % thereby be different for all base classifiers and is separately optimised  for each of them."
    %
    % Primary Author: Salma Dammak
    % Created: Jun 8, 2023
    
     
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private
    properties (SetAccess = immutable, GetAccess = public)
        sName = "PRTools Trainable Automatic Radial Basis Support Vector Classifier";
        hClassifier = [];
        lsValidHyperParameterNames = []; % none
    end
        
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static
    % *                          PUBLIC METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
    methods
        function obj = PRToolsRBSVC(chClassifierHyperParametersFileName,oHyperParameterOptimizer,NameValueArgs)      
            %obj = PRToolsRBSVC(chClassifierHyperParametersFileName)
            %
            % SYNTAX:
            %  obj = PRToolsRBSVC(chClassifierHyperParametersFileName)
            %
            % DESCRIPTION:
            %  Constructor for PRToolsRBSVC, it assigns the mapping and even though it has a path for
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
            
            if ~isempty(oHyperParameterOptimizer)
                warning("RBSVC has a built in hyper parameter optimization and takes no hyperparmeter input values, so it cannot be optimized externally.")
            end

            % Call PRToolsClassifier constructor
            obj@PRToolsClassifier(chClassifierHyperParametersFileName, oHyperParameterOptimizer)
            
            % Assign the prtools mapping
            obj.hClassifier = @rbsvc; % This is a PRTools "mapping"
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

            c1xHyperParams = {}; % RBSVC does not take any hyperparameters
        end
    end
end