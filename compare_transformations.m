clear all;
close all;

%% Set paths to files

boundary_points_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\common\LM_points.csv";
mesh_points_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\common\points.csv";
nn_mesh_points_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\common\nn_points.csv";

landmarks_1_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\transform_1\landmarks_190712.csv";
landmarks_2_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\transform_2\combined_190720.csv";

% trans_mesh_points_1_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\transform_1\points_trans_1.csv";
% trans_mesh_points_2_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\transform_2\points_trans_2.csv";
trans_nn_mesh_points_1_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\transform_1\nn_points_trans_1.csv";
trans_nn_mesh_points_2_path = "C:\Users\TracingPC1\Desktop\matlab_scripts\CompareBigWarpTransformations\transform_2\nn_points_trans_2.csv";

%% Load data from files

boundary_points = readtable(boundary_points_path);
mesh_points = readtable(mesh_points_path);
nn_mesh_points = readtable(nn_mesh_points_path);

% trans_mesh_points_1 = readtable(trans_mesh_points_1_path);
% trans_mesh_points_2 = readtable(trans_mesh_points_2_path);
trans_nn_mesh_points_1 = readtable(trans_nn_mesh_points_1_path);
trans_nn_mesh_points_2 = readtable(trans_nn_mesh_points_2_path);

boundary_points = table2array(boundary_points);
mesh_points = table2array(mesh_points);
nn_mesh_points = table2array(nn_mesh_points);
% trans_mesh_points_1 = table2array(trans_mesh_points_1);
% trans_mesh_points_2 = table2array(trans_mesh_points_2);
trans_nn_mesh_points_1 = table2array(trans_nn_mesh_points_1);
trans_nn_mesh_points_2 = table2array(trans_nn_mesh_points_2);

landmarks_1 = Landmarks2Array(landmarks_1_path);
landmarks_2 = Landmarks2Array(landmarks_2_path);

LM_landmarks_1 = landmarks_1(:, 1:3);
EM_landmarks_1 = landmarks_1(:,4:6);

LM_landmarks_2 = landmarks_2(:,1:3);
EM_landmarks_2 = landmarks_2(:,4:6);

% This loads in the trans_mesh_points without having to run a second
% transformation in FIJI
k = 7;
mesh_idx_list = knnsearch(nn_mesh_points, mesh_points, 'K', k);

trans_mesh_points_1 = trans_nn_mesh_points_1(mesh_idx_list(:,1),:);
trans_mesh_points_2 = trans_nn_mesh_points_2(mesh_idx_list(:,1),:);

%% Measure distances from aff_LM_landmarks to EM_landmarks

% Finds the distances between affine transformed landmarks and the BigWarp
% transformed landmarks. This metric is best for identifying landmarks that
% do not match.

[aff_LM_landmarks_1, affine_matrix_1] = ApplyBestFitAffineTrans(LM_landmarks_1, EM_landmarks_1);
[aff_LM_landmarks_2, affine_matrix_2] = ApplyBestFitAffineTrans(LM_landmarks_2, EM_landmarks_2);

landmark_1_dist = FindDistances(aff_LM_landmarks_1, EM_landmarks_1);
landmark_2_dist = FindDistances(aff_LM_landmarks_2, EM_landmarks_2);

%% Measure distances from aff_mesh_points to trans_mesh_points

% Finds the distance between the affine transformed mesh points and the
% BigWarp transformed mesh points. This metric is good for finding points
% in the transformation field where there was a lot of warping.

aff_mesh_points_1 = ApplyAffineTrans(mesh_points, affine_matrix_1);
aff_mesh_points_2 = ApplyAffineTrans(mesh_points, affine_matrix_2);

mesh_1_dist = FindDistances(aff_mesh_points_1, trans_mesh_points_1);
mesh_2_dist = FindDistances(aff_mesh_points_2, trans_mesh_points_2);



%% Find average nearest neighbor distances

% Finds the average distance to the 6 nearest neighbors in the point cloud.
% We don't really care about what the mean is, but what the spread around
% the mean is. The tighter the spread, the more uniform the warp field.

LM_to_EM_scale = 1.2745;

% This is just to get the indexes of the inner mesh points for later use
mesh_idx_list = knnsearch(nn_mesh_points, mesh_points, 'K', k);

points_to_measure_1 = trans_nn_mesh_points_1(mesh_idx_list(:,1),:);
points_to_measure_2 = trans_nn_mesh_points_2(mesh_idx_list(:,1),:);

[trans_mesh_idx_list_1, trans_mesh_nn_dist_list_1] = knnsearch(trans_nn_mesh_points_1, points_to_measure_1, 'K', k);
[trans_mesh_idx_list_2, trans_mesh_nn_dist_list_2] = knnsearch(trans_nn_mesh_points_2, points_to_measure_2, 'K', k);

% find the average nn distance and adjust for scaling from LM to EM
trans_mesh_nn_dist_list_1 = sum(trans_mesh_nn_dist_list_1, 2)/(6*LM_to_EM_scale);
trans_mesh_nn_dist_list_2 = sum(trans_mesh_nn_dist_list_2, 2)/(6*LM_to_EM_scale);

%% Find points in the area of the transformation

% This limits our analysis to points in the point mesh that are within the
% area of the origional LM point cloud. This will always check the same
% points no matter how they were transformed, which is what we want.

a = alphaShape(boundary_points(:,1:3));
in = inShape(a, mesh_points(:,1), mesh_points(:,2),  mesh_points(:,3));

trans_mesh_points_in_1 = trans_mesh_points_1(logical(in),:);
trans_mesh_points_in_2 = trans_mesh_points_2(logical(in),:);

mesh_1_dist_in = mesh_1_dist(in);
mesh_2_dist_in = mesh_2_dist(in);

nn_dist_1_in = trans_mesh_nn_dist_list_1(logical(in),:);
nn_dist_2_in = trans_mesh_nn_dist_list_2(logical(in),:);

%% Create plots

% Sets x lims for plots automatically, but you may need to adjust y lims 
% manually
warp_dist_x_lims = [0 max([max(mesh_1_dist_in), max(mesh_2_dist_in)])];
warp_dist_y_lims = [0, 2000];
nn_dist_x_lims = [min([min(nn_dist_1_in), min(nn_dist_2_in)]) max([max(nn_dist_1_in), max(nn_dist_2_in)])];
nn_dist_y_lims = [0, 1200];

figure('color', 'w', 'units','inches','position',[1,1,7,5])
axes('position',[0.3 0.2 0.65 0.65], 'XGrid', 'on', 'YGrid', 'on', 'ZGrid', 'on')
hold on;
p = scatter3(trans_mesh_points_in_1(:,1), trans_mesh_points_in_1(:,2), trans_mesh_points_in_1(:,3), 15, mesh_1_dist_in, 'filled');
colormap('jet');
color_max = max([max(mesh_1_dist_in), max(mesh_2_dist_in)]);
caxis([0, color_max]);
colorbar('ylim', [0,color_max]);
p.MarkerFaceAlpha = 0.85;
xlabel('X (pixels)', 'fontname', 'arial', 'fontsize',12)
ylabel('Y (pixels)','fontname','arial','fontsize',12)
zlabel('Z (pixels)', 'fontname', 'arial', 'fontsize',12)
set(gca, 'fontname','arial','fontsize',12)
%trisurf(b,EM_points(:,1), EM_points(:,2), EM_points(:,3),'Facecolor','red','FaceAlpha',0.05)
title('Transformation one warp field');
view(45,15);
hold off;

figure('color', 'w', 'units','inches','position',[9,1,7,5])
p = histogram(mesh_1_dist_in, 20);
xlabel('Transformation one distances from affine to warping transformation', 'fontname', 'arial', 'fontsize',20)
ylabel('Count','fontname','arial','fontsize',12)
set(gca, 'fontname','arial','fontsize',12, 'xlim', warp_dist_x_lims, 'ylim', warp_dist_y_lims)
hold on;
line([mean(mesh_1_dist_in), mean(mesh_1_dist_in)], ylim, 'LineWidth', 2, 'Color', 'm');

figure('color', 'w', 'units','inches','position',[1,7,7,5])
axes('position',[0.3 0.2 0.65 0.65], 'XGrid', 'on', 'YGrid', 'on', 'ZGrid', 'on')
hold on;
p = scatter3(trans_mesh_points_in_2(:,1), trans_mesh_points_in_2(:,2), trans_mesh_points_in_2(:,3), 15, mesh_2_dist_in, 'filled');
colormap('jet');
caxis([0, color_max]);
colorbar('ylim', [0,color_max]);
p.MarkerFaceAlpha = 0.85;
xlabel('X (pixels)', 'fontname', 'arial', 'fontsize',12)
ylabel('Y (pixels)','fontname','arial','fontsize',12)
zlabel('Z (pixels)', 'fontname', 'arial', 'fontsize',12)
set(gca, 'fontname','arial','fontsize',12)
%trisurf(b,EM_points(:,1), EM_points(:,2), EM_points(:,3),'Facecolor','red','FaceAlpha',0.05)
title('Transformation two warp field');
view(45,15);
hold off;

figure('color', 'w', 'units','inches','position',[9,7,7,5])
p = histogram(mesh_2_dist_in, 20);
xlabel('Transformation two distances from affine to warping transformation', 'fontname', 'arial', 'fontsize',20)
ylabel('Count','fontname','arial','fontsize',12)
set(gca, 'fontname','arial','fontsize',12, 'xlim', warp_dist_x_lims, 'ylim', warp_dist_y_lims)
hold on;
line([mean(mesh_2_dist_in), mean(mesh_2_dist_in)], ylim, 'LineWidth', 2, 'Color', 'm');


figure('color', 'w', 'units','inches','position',[17,1,7,5])
p = histogram(nn_dist_1_in, 50);
xlabel('Transform one average nn distances ', 'fontname', 'arial', 'fontsize',20)
ylabel('Count','fontname','arial','fontsize',12)
set(gca, 'fontname','arial','fontsize',12, 'xlim', nn_dist_x_lims, 'ylim', nn_dist_y_lims)
hold on;
line([mean(nn_dist_1_in), mean(nn_dist_1_in)], ylim, 'LineWidth', 2, 'Color', 'm');

figure('color', 'w', 'units','inches','position',[17,7,7,5])
p = histogram(nn_dist_2_in, 50);
xlabel('Transform two average nn distances', 'fontname', 'arial', 'fontsize',20)
ylabel('Count','fontname','arial','fontsize',12)
set(gca, 'fontname','arial','fontsize',12, 'xlim', nn_dist_x_lims, 'ylim', nn_dist_y_lims)
hold on;
line([mean(nn_dist_2_in), mean(nn_dist_2_in)], ylim, 'LineWidth', 2, 'Color', 'm');
