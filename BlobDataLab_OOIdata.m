%% 1. Explore and extract data from one year of OOI mooring data

addpath(genpath('C:\Users\nuhin\git\blob-data-lab-part-1-rocks_4_jocks\OOI_StationPapa_FLMB_CTDdata_BlobDataLab'))
%addpath(genpath('/Users/ilanajacobs/Palevsky_Lab/Classes/EESC6664/blob-data-lab-part-1-rocks_4_jocks/BlobDataLab_OOIdata.m'))

filename = 'deployment0001_GP03FLMB.nc';
%1a. Use the function "ncdisp" to display information about the data contained in this file
%-->

ncdisp(filename);

%1b. Use the function "ncreadatt" to extract the latitude and longitude
%attributes of this dataset
%-->
%-->

lat = ncreadatt(filename, '/', 'lat');
lon = ncreadatt(filename, '/', 'lon');
%1c. Use the function "ncread" to extract the variables "time" and
%"ctdmo_seawater_temperature"
%-->
%-->

time = ncread(filename, 'time');
temperature = ncread(filename, 'ctdmo_seawater_temperature');

% Extension option: Also extract the variable "pressure" (which, due to the
% increasing pressure underwater, tells us about depth - 1 dbar ~ 1 m
% depth). How deep in the water column was this sensor deployed?

%% 2. Converting the timestamp from the raw data to a format you can use
% Use the datenum function to convert the "time" variable you extracted
% into a MATLAB numerical timestamp (Hint: you will need to check the units
% of time from the netCDF file.)

% -->

% timeNormalized = (datenum(1900, 01, 01) + time) / (60*60*24);

time0 = datenum('1900-01-01'); 
timeFixed = time0 + time / (60*60*24);
timeCheck = datestr(timeFixed(1:5));

% Checking your work: Use the "datestr" function to check that your
% converted times match the time range listed in the netCDF file's
% attributes for time coverage

% 2b. Calculate the time resolution of the data (i.e. long from one
% measurement to the next) in minutes. Hint: the "diff" function will be
% helpful here.

timeResolution = diff(timeFixed) * (60 * 24);

%% 3. Make an initial exploration plot to investigate your data
% Make a plot of temperature vs. time, being sure to show each individual
% data point. What do you notice about the seasonal cycle? What about how
% the variability in the data changes over the year?
% Hint: Use the function "datetick" to make the time show up as
% human-readable dates rather than the MATLAB timestamp numbers

figure
plot(timeFixed, temperature, '.')
xlabel('Time')
ylabel('Temperature (°C)')
title('Temperature vs Time')
datetick('x', 'dd-mmm-yyyy')



%% 4. Dealing with data variability: smoothing and choosing a variability cutoff
% 4a. Use the movmean function to calculate a 1-day (24 hour) moving mean
% to smooth the data. Hint: you will need to use the time period between
% measurements that you calculated in 2b to determine the correct window
% size to use in the calculation.

% -->

movingmean = movmean(temperature, (24*60)/15);


% 4b. Use the movstd function to calculate the 1-day moving standard
% deviation of the data.

movingstd = movstd(temperature, (24*60)/15);

%% 5. Honing your initial investigation plot
% Building on the initial plot you made in #3 above, now add:
%5a. A plot of the 1-day moving mean on the same plot as the original raw data

subplot(2,1,1)

plot(timeFixed, temperature, '.', 'DisplayName', 'Raw Data')
hold on
plot(timeFixed, movingmean, 'r', 'LineWidth', 2, 'DisplayName', '1-day Moving Mean')

ylabel('Temperature (°C)')
title('Temperature vs Time with 1-Day Moving Mean')
legend

datetick('x', 'dd-mmm-yyyy')
grid on

%5b. A plot of the 1-day moving standard deviation, on a separate plot
%underneath, but with the same x-axis (hint: you can put two plots in the
%same figure by using "subplot" and you can specify

subplot(2,1,2)

plot(timeFixed, movingstd, 'k', 'LineWidth', 1.5)

ylabel('Std Dev (°C)')
xlabel('Time')
title('1-Day Moving Standard Deviation')

datetick('x', 'dd-mmm-yyyy')
grid on

%% 6. Identifying data to exclude from analysis
% Based on the plot above, you can see that there are time periods when the
% data are highly variable - these are time periods when the raw data won't
% be suitable for use to use in studying the Blob.

%6a. Based on your inspection of the data, select a cutoff value for the
%1-day moving standard deviation beyond which you will exclude the data
%from your analysis. Note that you will need to justify this choice in the
%methods section of your writeup for this lab.

std_cutoff= 0.25; % Chose it because there was a lot of noise in the data above this threshold 

%6b. Find the indices of the data points that you are not excluding based
%on the cutoff chosen in 6a.

good_idx= find(movingstd <= std_cutoff);

%6c. Update your figure from #5 to add the non-excluded data as a separate
%plotted set of points (i.e. in a new color) along with the other data you
%had already plotted.

figure
subplot(2,1,1)
plot(timeFixed, temperature, '.', 'Color', [0.7 0.7 0.7], 'DisplayName', 'Raw Data')
hold on
plot(timeFixed, movingmean, 'r', 'LineWidth', 2, 'DisplayName', '1-day Moving Mean')
plot(timeFixed(good_idx), temperature(good_idx), 'b.', 'DisplayName', 'Non-excluded Data')
ylabel('Temperature (°C)')
title('Temperature vs Time')
legend('Location', 'best')
datetick('x', 'mmm-yyyy', 'keeplimits')
grid on

subplot(2,1,2)
plot(timeFixed, movingstd, 'k', 'LineWidth', 1.5, 'DisplayName', 'Moving Std Dev')
hold on
yline(stdCutoff, 'r--', 'LineWidth', 2, 'DisplayName', ['Cutoff = ' num2str(stdCutoff) '°C'])
ylabel('Std Dev (°C)')
xlabel('Time')
title('1-Day Moving Standard Deviation')
legend('Location', 'best')
datetick('x', 'mmm-yyyy', 'keeplimits')
grid on


%% 7. Apply the approach from steps 1-6 above to extract data from all OOI deployments in years 1-6
% You could do this by writing a for-loop or a function to adapt the code
% you wrote above to something you can apply across all 5 netCDF files
% (note that deployment 002 is missing)

filenames = {
    'deployment0001_GP03FLMB.nc', ...
    'deployment0003_GP03FLMB.nc', ...
    'deployment0004_GP03FLMB.nc', ...
    'deployment0005_GP03FLMB.nc', ...
    'deployment0006_GP03FLMB.nc'
};

deploymentNums = [1, 3, 4, 5, 6];

% allocate struct to store results
allData = struct();

for i = 1:length(filenames)

    filename = filenames{i};
    depNum   = deploymentNums(i);

    % Extract coordiates, times, temps
    lat         = ncreadatt(filename, '/', 'lat');
    lon         = ncreadatt(filename, '/', 'lon');
    time        = ncread(filename, 'time');
    temperature = ncread(filename, 'ctdmo_seawater_temperature');

    % Convert Times

    time0     = datenum('1900-01-01');
    timeFixed = time0 + time / (60*60*24);

    timeResolution = diff(timeFixed) * (60 * 24);

    movingMean = movmean(temperature, (24*60)/15);
    movingStd = movstd(temperature, (24*60)/15);

    good_idx = find(movingStd <= std_cutoff);

    % Store data
    allData(i).deploymentNum = depNum;
    allData(i).filename = filename;
    allData(i).lat = lat;
    allData(i).lon = lon;
    allData(i).time = timeFixed;
    allData(i).temperature = temperature;
    allData(i).movingMean = movingMean;
    allData(i).movingStd = movingStd;
    allData(i).good_idx = good_idx;
    allData(i).timeResolution= timeResolution;


    % Plots 
figure('Name', sprintf('Deployment %04d', depNum), 'NumberTitle', 'off')

    subplot(2,1,1)
    plot(timeFixed, temperature, '.', 'Color', [0.7 0.7 0.7], ...
         'DisplayName', 'Raw Data')
    hold on
    plot(timeFixed, movingMean, 'r', 'LineWidth', 2, ...
         'DisplayName', '1-day Moving Mean')
    plot(timeFixed(good_idx), temperature(good_idx), 'b.', ...
         'DisplayName', 'QC-Filtered Data')
    ylabel('Temperature (°C)')
    title(sprintf('Deployment %04d — Temperature', depNum))
    legend('Location', 'best')
    datetick('x', 'mmm-yyyy', 'keeplimits')
    grid on

    subplot(2,1,2)
    plot(timeFixed, movingStd, 'k', 'LineWidth', 1.5)
    hold on
    yline(std_cutoff, 'r--', 'LineWidth', 2, ...
          'Label', ['Cutoff = ' num2str(std_cutoff) '°C'])
    ylabel('Std Dev (°C)')
    xlabel('Time')
    title(sprintf('Deployment %04d — 1-Day Moving Std Dev', depNum))
    datetick('x', 'mmm-yyyy', 'keeplimits')
    grid on

end