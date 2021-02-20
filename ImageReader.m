classdef ImageReader < handle
    
    properties
        src             % Data source
        L               % Left camera  (1 or 2)
        R               % Right camera (2 or 3)
        start           % Initial framenumber
        N               % Number of consecutive successors       
        iterator        % Offset from start to get current image
        loop            % loop variable for method 'next'
        names_cell_L    % List of all images in directory of left camera
        names_cell_R    % List of all images in directory of right camera
        framesL         % Path to directory of images of left camera
        framesR         % Path to directory of images of right camera
    end    
    
    methods
        % Define constructor
        function obj = ImageReader(src, L, R, start, N)           
            
            % Initialize with zero
            obj.iterator = 0;
            obj.loop = 0;
             
            %%% Check inputs %%%
            % If not all required inputs are given, return error
            if (nargin < 3)     
                error('[Error]: At least parameters "src", "L" and "R" have to be determined!');       
            % If only required inputs are given, set start and N to default             
            elseif (nargin < 4)       
                obj.src = src;
                obj.L = L;
                obj.R = R;
                obj.start = 1;      % Changed from 0 to 1
                obj.N = 1;               
                disp('[INFO]: No value for start and N parameter given, therefore set N=1 and start=1');
            % If only N is not given, set N to default    
            elseif (nargin < 5)              
                obj.src = src;
                obj.L = L;
                obj.R = R;
                obj.start = start;
                obj.N = 1;
                disp('[INFO]: No value for N parameter given, therefore set N=1');
            % If all inputs are given    
            elseif (nargin == 5)
                obj.src = src;
                obj.L = L;
                obj.R = R;
                obj.start = start;
                obj.N = N;
            end     
            
            %%% Check correctness and data type of input variables %%%
            % Check source value (src)
            if ~(isstring(obj.src) || ischar(obj.src))
               error('Data source "src" has to be a char (string) variable!'); 
            end
            % Check type of left camera value (L)
            if ~(isnumeric(obj.L))
                error('Left camera input parameter "L" must be numeric');
            end
            % Check correctness of L
            if ~(isequal(L, 1) || isequal(L, 2))
                error('Left camera input paramter "L" must be either 1 or 2');
            end
            % Check right camera value (R)
            if ~(isnumeric(obj.R))
                error('Right camera input parameter "R" must be numeric');
            end
            % Check correctness of R
            if ~(isequal(R, 2) || isequal(R, 3))
                error('Right camera input paramter "R" must be either 2 or 3');
            end
            % Check that L and R do not match
            if isequal(L, R)
                error('Left camera parameter "L" and right camera parameter "R" must be different!');
            end            
            % Check inital framenumber (start) 
            if ~(isnumeric(obj.start))
                error('Start paramater "start" must be numeric')
            elseif (obj.start < 0) 
                error('Start paramater "start" has to be greater or equal to zero');
            elseif contains(string(obj.start), '.') % Check if start is integer
                error('Start paramater "start" must be an integer');
            end            
            % Check consecutive successors (N) 
            if ~(isnumeric(obj.N))
                error('Consecutive successors paramater "N" must be numeric');
            elseif (obj.N < 1)
                error('Consecutive successors paramater "N" has to be greater or equal to one');
            elseif contains(string(obj.N), '.')  % Check if N is integer
                error('Consecutive successors parameter "N" must be an integer');
            end

            % Build data path to directory of images of left/right camera
            if (contains(obj.src, '\'))     % For Windows
                split = strsplit(obj.src, '\');
                obj.framesL = strcat(obj.src, '\', split{end}, '_C', int2str(obj.L));
                obj.framesR = strcat(obj.src, '\', split{end}, '_C', int2str(obj.R));                
            else % For Unix
                split = strsplit(obj.src, '/');
                obj.framesL = strcat(obj.src, '/', split{end}, '_C', int2str(obj.L));
                obj.framesR = strcat(obj.src, '/', split{end}, '_C', int2str(obj.R));                
            end
            
            % Load images directroy
            dinfoL = dir(obj.framesL);
            dinfoR = dir(obj.framesR);
            temp_names_cell_L = {dinfoL.name};
            temp_names_cell_R = {dinfoR.name};
            
            % Prepare name cells with image names only
            obj.names_cell_L = {};
            obj.names_cell_R = {};
            
            % Get all images within the directory
            j = 1;
            for i = 1:length(temp_names_cell_L)
               if (contains(temp_names_cell_L{i}, '.jpg') || contains(temp_names_cell_L{i}, '.jpeg'))                  
                  obj.names_cell_L{j} = temp_names_cell_L{i}; 
                  obj.names_cell_R{j} = temp_names_cell_R{i};
                  j = j + 1;
               end                   
            end       
            
            % Additional check: start must not exceed number of images
            if (obj.start > length(obj.names_cell_L))
                error('Start value is bigger than entries available in the dataset, please choose a smaller value');            
            end
            
        end       
        
        % Define method for loading images from directories
        function [left, right, loop] = next(obj)       
            
            % Assign properties to variables as the object properties might
            % be changed during the method
            n = obj.N;
            start_value = obj.start;
            counter     = obj.iterator;
 
            % Check if the current frame and all successors can be loaded
            % or if the end of the directory is reached     
            if start_value + counter + n > length(obj.names_cell_L)
                if n > 1
                    % If n is larger than 1, use all remainig successors  
                    % (n-1) and reset the object properties to start from
                    % beginning (start = 1) in the next call of next()
                    n = n - 1;
                    obj.start = 1;
                    obj.iterator = 0;
                    obj.loop = 1; 
                else
                    % If n is 1, no successors are remaining. Reset the 
                    % object properties to start from beginning (start = 1)
                    % in the next call of next() and set return values.
                    obj.start = 1;
                    obj.iterator = 0;
                    obj.loop = 1;
                    % Set return values
                    loop = obj.loop;
                    left = importdata(strcat(obj.framesL, '/', obj.names_cell_L{end}));
                    left = cat(3, left, left);
                    right = importdata(strcat(obj.framesL, '/', obj.names_cell_R{end}));
                    right = cat(3, right, right);
                    return;
                end
            end

            % Load first image into left and right image tensors
            temp_left = importdata(strcat(obj.framesL, '/', obj.names_cell_L{start_value+counter}));            
            left = temp_left;
            temp_right = importdata(strcat(obj.framesR, '/', obj.names_cell_R{start_value+counter}));            
            right = temp_right;

            % Load consecutive successors into left and right image tensors
            for i = 1:n
                temp_left = importdata(strcat(obj.framesL, '/', obj.names_cell_L{start_value+counter+i}));
                left = cat(3, left, temp_left);
                temp_right = importdata(strcat(obj.framesR, '/', obj.names_cell_R{start_value+counter+i}));
                right = cat(3, right, temp_right);
            end            

            %Increment iterator            
            obj.iterator = obj.iterator + 1;           
            
            % Set loop value
            loop = obj.loop;
            
        end
    end
end