% modifying this file to get it running on some of the demos on my laptop 
% so that I understand how it works on the cluster.
% will try use RES data for now
% need to flip all the slashes back for running on the cluster
% this all runs now with the RES data


baseWD = '/rigel/stats/users/ogw2103/pasf/';
%dataPath = strcat(baseWD, '\data\');

%NOTE: load GCaMP dataset
%load( strcat(baseWD, 'data/gcamp_raw.mat') );
%data = gcamp_raw;

%NOTE: load HbT dataset
%load( strcat(baseWD, 'data/chbt.mat') );
%load( strcat(baseWD, 'data/mask.mat') );

%NOTE: load the spatial mask to mask out artifacts
%spatialMask = double(boolean(imread('mask.bmp')));
%load('mask.mat');

%cm16_4_runC_stim4
%cm14_2_runJ_stim8


%dataset_name = 'grant';
dataset_name = 'RES';
%mask_name    = 'grant_mask';



%signal_type      = 'chbt';
%clusteringMethod = 'phase';

signal_type      = 'gcamp';
clusteringMethod = 'phase';

%clusteringMethod = 'modulus';

videoPlotFS      = 5;

% load( strcat(dataPath, dataset_name, '.mat') );
%load( strcat(dataPath, mask_name,    '.mat') );

% if exist('mask') == 1,
% 	spatialMask = boolean(mask);
% else
% 	spatialMask = boolean(spatialMask);
% end


% if strcmp( signal_type , 'chbt')
% 	data = chbt;
% 	videoPlotFS  = 30;
% elseif strcmp( signal_type , 'gcamp')
% 	data = gcamp_raw;
% 	videoPlotFS  = 5;
% else
% 	stop('undefined signal type!');
% end

simOpts = struct('noiseVar', 0.16, 'noiseCorrCoeff', 0, 'sourceEnergy', 6.3);
data    = rotating_energy_sources(1000, simOpts);
data = data(:, :, 500:end);
[d1, d2, d3]    = size(data);

%dataset_new_name = strcat(dataset_name, '500EndCropped', '_');

dirname      = strcat( baseWD, '/', dataset_name, '_', signal_type, '_', clusteringMethod);
%dirname      = strcat( baseWD, '/', dataset_new_name, '_', signal_type, '_', clusteringMethod);

bfilename    = strcat( dirname, '/pasf' );
if exist(dirname) ~= 7,  mkdir( dirname );  end


fprintf('The input data size is [%d,%d,%d]. \n', d1, d2, d3);
fprintf('The output file names start with %s. \n', bfilename);
fprintf('The number of computational threads is: %d. \n', maxNumCompThreads);


%NOTE: setting up the sampling rate.
if exist('frameRate') == 1,
	samplingRate = frameRate;
else
	samplingRate = 10.40;
	frameRate = 10.40;
end
sTime = (1:d3)/samplingRate;


%NOTE: pasf options
pasfOpts = struct('nTopEVs', 5, ...
	'saveData', 3, 'boolUseSavedData', 0, ...
	'SampleTimes', sTime, ...
	'cmethod', clusteringMethod, ... 
	'outlierThreshold', 0.9, ...
	'boolDemeanInput', 2, ...
	'spans', 35, ...
	'kmethod', 'triangle', ...
	'errorRate', 0.11, ...
	'kmeansReplicates', 2048, ...
	'bfilename', bfilename);

myOpts = struct('cmethod', 'phase', ... 
	'nTopEVs', 2, 'outlierThreshold', 0.7, ...
	'boolParfor', false, ... 
	'saveData', 0, 'boolUseSavedData', 0, ... 
	'kmethod', 'triangle', ...
	'spans', 21, 'errorRate', 0.1, 'bfilename', bfilename);


tic;
[Components, Clusters, ClusterInfo, SDFInfo] = pasf(data, 2, pasfOpts);
%Z = pasf(data, 2, myOpts);
toc;




% Commenting out below for time being, see if I can get it to work after
%load( strcat(bfilename, '_output.mat') );
ClusterInfo.CEnergy = squeeze( sum( sum( sum(Components.^2, 3), 2), 1) );
ClusterInfo.CEnergy = ClusterInfo.CEnergy./ClusterInfo.CEnergy(end);
ClusterInfo.CEnergy = ClusterInfo.CEnergy(1:end-2);

plot_PASF_outputs(Components, Clusters, ClusterInfo, SDFInfo, false, bfilename);
% some errors with this still. trying to isolate them
% have commented out lines 195 and 236

disp('-------------------');
Energy = squeeze( sum( sum( sum(Components.^2, 3), 2), 1) );
disp(Energy');
Energy = Energy./Energy(end);
disp(Energy');
disp(cumsum(Energy)');
disp('+++++++++++++++++++');

[d1, d2, d3, d4] = size(Components);
parfor i=1:d4,
	cName = strcat(bfilename, '_cmp', num2str(i));
	if i == d4-1,
		cName = strcat(bfilename, '_reminder');
	elseif i == d4,
		cName = strcat(bfilename, '_signal');
	end
	titleSeq = arrayfun(@(x)( strcat('time=', num2str(x/frameRate), '(sec)') ), 1:d3, 'UniformOutput', false);
    % getting error below with saving the movies. I think the function is
    % never defined anywhere...
	saveCmpVideo(Components(:, :, :, i), 1:d3, videoPlotFS, cName);%, titleSeq);
end

disp('done.');

