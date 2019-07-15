function [bad_point_numbers, warp_dist] = FindBadPoints(in_file, out_file, threshold, write)
% Find all points where the distance between the affine transformed
% LM_landmarks and the EM_landmarks is above a certain threshold. in_file
% should be the landmarks file, out_file is the file you want to write the
% list of bad points to (optional), threshold is the distance threshold to define a
% 'bad' point. Set write to 1 to write the points, or 0 to not write the
% points

%% Read in the data
landmarks = readtable(in_file);
landmarks = table2array(landmarks(:, 3:8));
LM_landmark_points = landmarks(:, 1:3);
EM_landmark_points = landmarks(:, 4:6);

%% Find and apply best fit affine transformation
LM_landmark_points = [LM_landmark_points, ones(size(LM_landmark_points, 1), 1)]';
EM_landmark_points = [EM_landmark_points, ones(size(EM_landmark_points, 1), 1)]';

affine_trans = LM_landmark_points/EM_landmark_points;

aff_LM_landmark_points = affine_trans\LM_landmark_points;

LM_landmark_points = LM_landmark_points';
EM_landmark_points = EM_landmark_points';
aff_LM_landmark_points = aff_LM_landmark_points';

%% Calculate distance from affine transformed points to EM points
warp_dist = sqrt(sum((aff_LM_landmark_points(:,1:3)-EM_landmark_points(:,1:3)).^2, 2));

%% Find all rows with dist greater than some threshold
bad_points = double(warp_dist > threshold);
bad_point_numbers = [find(bad_points)-1, warp_dist(logical(bad_points),:)];

%% Write bad_point_numbers to .csv file (optional)
if write == 1
    writematrix(bad_point_numbers, out_file);
end

end

