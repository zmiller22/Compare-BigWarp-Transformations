function [bad_point_numbers, warp_dist] = FindBadPoints(in_file, out_file, threshold, write)
% Find all points where the distance between the affine transformed
% LM_landmarks and the EM_landmarks is above a certain threshold. in_file
% should be the landmarks file, out_file is the file you want to write the
% list of bad points to (optional), threshold is the distance threshold to define a
% 'bad' point. Set write to 1 to write the points, or 0 to not write the
% points

%% Read in the data
landmarks = readtable(in_file);

% logical array of points that are already false
rows_false = strcmp(landmarks{:,2}, 'FALSE');

% points for the distance calcluation
num_landmarks = table2array(landmarks(:, 3:8));
LM_landmark_points = num_landmarks(:, 1:3);
EM_landmark_points = num_landmarks(:, 4:6);

% points to be considered when creating best-fit affine transfromation
LM_points_for_aff = LM_landmark_points;
EM_points_for_aff = EM_landmark_points;
LM_points_for_aff(rows_false,:) = [];
EM_points_for_aff(rows_false,:) = [];


%% Find and apply best fit affine transformation
LM_points_for_aff = [LM_points_for_aff, ones(size(LM_points_for_aff, 1), 1)]';
EM_points_for_aff = [EM_points_for_aff, ones(size(EM_points_for_aff, 1), 1)]';
LM_landmark_points = [LM_landmark_points, ones(size(LM_landmark_points, 1), 1)]';

affine_trans = LM_points_for_aff/EM_points_for_aff;

aff_LM_landmark_points = affine_trans\LM_landmark_points;

LM_landmark_points = LM_landmark_points';
aff_LM_landmark_points = aff_LM_landmark_points';

%% Calculate distance from affine transformed points to EM points
warp_dist = sqrt(sum((aff_LM_landmark_points(:,1:3)-EM_landmark_points(:,1:3)).^2, 2));

%% Find all rows with dist greater than some threshold that are not already false
bad_points = double(warp_dist > threshold);
bad_points(rows_false,:) = 0;

landmarks{logical(bad_points),2} = {'FALSE'};

bad_point_numbers = [find(bad_points)-1, warp_dist(logical(bad_points),:)];

%% Write bad_point_numbers to .csv file (optional)
if write == 1
    writetable(landmarks, out_file, 'WriteVariableNames', false);
end

end

