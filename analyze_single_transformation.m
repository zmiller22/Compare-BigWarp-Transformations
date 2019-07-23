clear all;
close all;

%% Set paths to files

boundary_points_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\common\new_boundary.csv";
mesh_points_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\common\points.csv";
nn_mesh_points_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\common\nn_points.csv";

landmarks_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\transform_1\landmarks_190712.csv";

trans_mesh_points_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\transform_1\points_trans_1.csv";
trans_nn_mesh_points_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\transform_1\nn_points_trans_1.csv";

fixed_points_nn_path = "C:\Users\TracingPC1\Desktop\BIGWARP\TRANSFORMS\testing\fixed_points_nn.csv";
fixed_points_warp_path = "C:\Users\TracingPC1\Desktop\BIGWARP\TRANSFORMS\testing\fixed_points_warp.csv";
nn_landmark_points_path = "C:\Users\TracingPC1\Desktop\BIGWARP\TRANSFORMS\testing\nn_landmarks.csv";

%% Load data from files

% boundary_points = Landmarks2Array(boundary_points_path);
mesh_points = readtable(mesh_points_path);
nn_mesh_points = readtable(nn_mesh_points_path);

trans_mesh_points = readtable(trans_mesh_points_path);
trans_nn_mesh_points = readtable(trans_nn_mesh_points_path);

% boundary_points = table2array(boundary_points);
mesh_points = table2array(mesh_points);
nn_mesh_points = table2array(nn_mesh_points);
trans_mesh_points = table2array(trans_mesh_points);
trans_nn_mesh_points = table2array(trans_nn_mesh_points);

boundary_points = Landmarks2Array(boundary_points_path);
landmarks = Landmarks2Array(landmarks_path);

LM_landmarks = landmarks(:, 1:3);
EM_landmarks = landmarks(:,4:6);
boundary_points = boundary_points(:,1:3);


%% Measure distances from aff_LM_landmarks to EM_landmarks

% Finds the distances between affine transformed landmarks and the BigWarp
% transformed landmarks. This metric is best for identifying landmarks that
% do not match.

[aff_LM_landmarks, affine_matrix] = ApplyBestFitAffineTrans(LM_landmarks, EM_landmarks);

landmark_dist = FindDistances(aff_LM_landmarks, EM_landmarks);

%% Measure distances from aff_mesh_points to trans_mesh_points

% Finds the distance between the affine transformed mesh points and the
% BigWarp transformed mesh points. This metric is good for finding points
% in the transformation field where there was a lot of warping.

aff_mesh_points = ApplyAffineTrans(mesh_points, affine_matrix);

warp_dist = FindDistances(aff_mesh_points, trans_mesh_points);


%% Find average nearest neighbor distances

% Finds the average distance to the 6 nearest neighbors in the point cloud.
% We don't really care about what the mean is, but what the spread around
% the mean is. The tighter the spread, the more uniform the warp field.

k = 7;
LM_to_EM_scale = 1.2745;

% This is just to get the indexes of mesh points in the nn_mesh_points list
mesh_idx_list = knnsearch(nn_mesh_points, mesh_points, 'K', k);

points_to_measure = trans_nn_mesh_points(mesh_idx_list(:,1),:);

[trans_mesh_idx_list, trans_mesh_nn_dist_list] = knnsearch(trans_nn_mesh_points, points_to_measure, 'K', k);

% find the average nn distance and adjust for scaling from LM to EM
trans_mesh_nn_dist_list = sum(trans_mesh_nn_dist_list, 2)/(6*LM_to_EM_scale);

%% Find points in the area of the transformation

% This limits our analysis to points in the point mesh that are within the
% area of the origional LM point cloud. This will always check the same
% points no matter how they were transformed, which is what we want.

a = alphaShape(boundary_points(:,1:3));
in = inShape(a, mesh_points(:,1), mesh_points(:,2),  mesh_points(:,3));

trans_mesh_points_in = trans_mesh_points(logical(in),:);
warp_dist_in = warp_dist(in);

trans_mesh_nn_dist_in = trans_mesh_nn_dist_list(logical(in),:);
trans_mesh_idx_list_in = trans_mesh_idx_list(logical(in),:);

%% Find bad points

% This finds points in the landmarks csv that might not coorespond to the
% same points in LM and EM and writes new landmark files with the
% bad_points edited out

[bad_point_idx_list_nn, bad_point_dist_list_nn] = FindBadNNPoints(landmarks_path, trans_mesh_nn_dist_in, trans_mesh_idx_list_in, trans_nn_mesh_points, 1, fixed_points_nn_path);
[bad_points_idx_list_warp, bad_point_dist_list_warp] = FindBadWarpPoints(landmarks_path, 35, 1, fixed_points_warp_path);

% TODO compare the idx_points to create a third output option where it only
% changes points that were bad for both warp and nn distance

%% Testing
CreateNNLandmarkFile(nn_mesh_points, trans_nn_mesh_points, trans_mesh_nn_dist_in, trans_mesh_idx_list_in, 0.3, nn_landmark_points_path);

%% Create plots

figure('color', 'w', 'units','inches','position',[1,1,7,5])
axes('position',[0.3 0.2 0.65 0.65], 'XGrid', 'on', 'YGrid', 'on', 'ZGrid', 'on')
hold on;
p = scatter3(trans_mesh_points_in(:,1), trans_mesh_points_in(:,2), trans_mesh_points_in(:,3), 15, warp_dist_in, 'filled');
colormap('jet');
color_max = max(warp_dist_in);
caxis([0, color_max]);
colorbar('ylim', [0,color_max]);
p.MarkerFaceAlpha = 0.85;
xlabel('X (pixels)', 'fontname', 'arial', 'fontsize',12)
ylabel('Y (pixels)','fontname','arial','fontsize',12)
zlabel('Z (pixels)', 'fontname', 'arial', 'fontsize',12)
set(gca, 'fontname','arial','fontsize',12)
hold on;
%trisurf(b, boundary_points(:,1), boundary_points(:,2), boundary_points(:,3),'Facecolor','red','FaceAlpha',0.05)
title('Transformation one warp field');
view(45,15);
hold off;

figure('color', 'w', 'units','inches','position',[9,1,7,5])
p = histogram(warp_dist_in, 20);
xlabel('Transformation one distances from affine to warping transformation', 'fontname', 'arial', 'fontsize',20)
ylabel('Count','fontname','arial','fontsize',12)
set(gca, 'fontname','arial','fontsize',12)
hold on;
line([mean(warp_dist_in), mean(warp_dist_in)], ylim, 'LineWidth', 2, 'Color', 'm');

figure('color', 'w', 'units','inches','position',[17,1,7,5])
p = histogram(trans_mesh_nn_dist_in, 50);
xlabel('Transform one average nn distances ', 'fontname', 'arial', 'fontsize',20)
ylabel('Count','fontname','arial','fontsize',12)
set(gca, 'fontname','arial','fontsize',12)
hold on;
line([mean(trans_mesh_nn_dist_in), mean(trans_mesh_nn_dist_in)], ylim, 'LineWidth', 2, 'Color', 'm');

