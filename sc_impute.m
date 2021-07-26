function [X]=sc_impute(X,varargin)
% Imputation 
% 
% See alos: SC_TRANSFORM

p = inputParser;
defaultType = 'MAGIC';
validTypes = {'MAGIC','McImpute'};
checkType = @(x) any(validatestring(x,validTypes));

addRequired(p,'X',@isnumeric);
addOptional(p,'type',defaultType,checkType)
parse(p,X,varargin{:})

   
switch lower(p.Results.type)
    case 'MAGIC'
        [X]=run.MAGIC(X,true);
    case 'McImpute'
        [X]=run.McImpute(X,true);
end
end