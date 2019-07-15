Please note that this README is for lab use only, a second one will be coming soon for instructions on how to use this repository on any data set

compare_transformations contains everything you need to compare two transformations generated from different landmark files created using the FIJI BigWarp tool. This includes ways to visualize and quantify differences in the warp fields. The repository is based around a single matlab script and multiple folders containing relevant files and matlab functions. The repositry has the following elements

 - compare_transformations.m
 - functions
 - transform_1
 - transform_2
 - common

As the names suggest, transformation_1 holds files specific to the first transformation, transformation_2 holds files specific to the second transformation, and common holds files that are common between both transformations. Additonaly, there is a functions folder that contains all the functions needed in compare_transformations.m, as well as several other functions that can be useful when dealing with this kind of data. Make sure the functions folder is added to your matlab path. 

Set up for usage:

Let's say you have two landmark files and you want to compare their resulting transformations. Before runnign the script, you need to set up the files that will be read in as variables. The files contained in the common folder are already set up for this and require no editing. 

The first step is to change transform_1/landmarks_1 to be the first landmarks file you are interested in. After this is done, clear all the columns in transform_1/nn_points_trans_1 and transform_1/points_trans_1 (this prevents leftover points from lingering in case the number of points in changed). Now, run the FIJI plugin for transforming points using transform_1/landmarks_1 as you landmarks file, common/points as your input file, and transform_1/points_trans as your output file. When it is done, check to make sure that transform_1/points_trans has been filled with three columns of numbers. Next, run the fiji plugin again with the same landmarks file but this time using common/nn_points_trans as the input file and transform_1/nn_points_trans_1 as your output file. Again check to make sure that the transform_1/nn_points_trans_1 has been filled. 

Next, repeat all the steps above using the second landmark file and the files in transform_2.

Now you are almost ready to run the script. The last step is to change all the of the file path variables in the first section of the script to the proper file path on your computer. Once this is done, you are reeady to run the script!