function [mask] = segmentation(left,right,sel)
%SEGMENTATION performs a foreground/background segmentation of
% a dynamic scene. Moving objects will be seen as foreground.
% left: uint8, tensor containing 600x800x3 images of the left camera
% right: uint8, tensor containing 600x800x3 images of the left camera 
% sel: Selection for which camera channel the segmentation mask shall
%      be computed
% - 1 indicated that left channel shall be used
% - 2 indicates that right channel shall be used
% result: Binary mask, 0's indicating background pixels, 1's indicating
%         foreground pixels
  tensor_in = 0;
  if sel == 1
      tensor_in = left;
  else
      tensor_in = right;
  end
  %% Implementation of [ ViBe2011 ] Algorithm
  N = size(tensor_in,3) / 3;
  image_size = [size(tensor_in, 1) size(tensor_in, 2)];
  
  idx_i = 1:N;
  idx_ref = max(1,floor(N/2));
  idx_i(idx_ref) = [];
  
  im_ref = tensor_in(:,:,(idx_ref-1)*3+1:idx_ref*3);
  
  M = uint8(zeros(image_size(1),image_size(2)));
  
  % Radius of spheres
  R = 12;
  n_min = 4;
  
  for i=idx_i
    im_i = tensor_in(:,:,(i-1)*3+1:i*3);
    
    % Neighbourhood positions
    %neighbourhood = [ ...
    %    -1, 0, 1, -1, 1, -1, 0, 1, 0;
    %    -1, -1, -1, 0, 0, 1, 1, 1, 0
    %];
    %neighbourhood = [ ...
    %    0, 1, -1, 0, 0;
    %    -1,0, 0,  1, 0
    %];
    neighbourhood = [0;0];
    %neighbourhood = (randi(8,[2 8]) - 4) .* [1;1];
    
    for j=1:size(neighbourhood,2)
        
        % Shift values
        v_1 = neighbourhood(1,j);
        v_2 = neighbourhood(2,j);
            
        shift_matrix1 = diag(ones(image_size(2)-abs(v_1),1),v_1);
        shift_matrix2 = diag(ones(image_size(1)-abs(v_2),1),v_2);
        
        differences = zeros(3,image_size(1)*image_size(2));
        
        % loop over rgb channels
        for k=1:3
            im_i_ch_k = double(im_i(:,:,k));
            im_ref_ch_k = double(im_ref(:,:,k));
            
            % Shift channel image horizontally
            im_i_ch_k_shifted = im_i_ch_k*shift_matrix1;
            % Shift channel image vertically
            im_i_ch_k_shifted = shift_matrix2*im_i_ch_k_shifted;
            
            % Replace uncovered area with reference values
            ref_mask = ones(image_size(1),image_size(2));
            ref_mask = ref_mask*shift_matrix1;
            ref_mask = shift_matrix2*ref_mask;
            ref_mask = ~ref_mask;
            
            im_i_ch_k_shifted = im_i_ch_k_shifted + im_ref_ch_k.*ref_mask;
            
            % Calculate difference
            diff = im_ref_ch_k -im_i_ch_k_shifted;
            
            % Store
            differences(k,:) = diff(:)';
        end
        
        % Sum squared differences over rgb channels
        sse_rgb = sum(differences.^2);
        
        % Count values inside sphere
        M(:) = M(:)' + uint8(sse_rgb < R^2);
        
    end
    
  end
  
  % If more than n_min pixels lay inside sphere it is considered background
  mask = ~(M > n_min);
  
  %% Postprocessing
  
  % Get rid of noisy pixels
  mask = imgaussfilt(double(mask),2) > 0.7;
  
  % Morphologically close image in order to connect nearby areas
  se1 = strel('disk', 10, 0);
  mask = imclose(mask, se1);
  
  % Find biggest forground blob and erase everything else
  CC = bwconncomp(mask);
  numPixels = cellfun(@numel,CC.PixelIdxList);
  [~,idx] = max(numPixels);
  
  mask = zeros(size(mask));
  mask(CC.PixelIdxList{idx}) = 1;
  
  % Erase small black spots inside foreground blob
  CC = bwconncomp(~mask);
  numPixels = cellfun(@numel,CC.PixelIdxList);
  [~,idx] = max(numPixels);
  
  mask = ones(size(mask));
  if ~isempty(idx) 
      mask(CC.PixelIdxList{idx}) = 0;
  end
  
end
