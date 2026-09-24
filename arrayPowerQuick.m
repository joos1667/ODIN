function result = arrayPowerQuick(out, cfg, area_m2, overrides)
% ARRAYPOWERQUICK Preliminary power from ONE spacecraft's solar array.
% Put this file beside Alessandro's MATLAB files. Requires solarFlux.m.
% No transient thermal model; perfect Sun pointing; direct sunlight only.
% Areas are TOTAL PHYSICAL PANEL FACE AREA [m^2], including cell gaps.
% Values below are preliminary design assumptions, NOT fleet-wide averages.
%
% Call AFTER Alessandro has generated the chosen fixed orbit's out and cfg:
%   result = arrayPowerQuick(out, cfg, [0.05 0.10 0.15 0.20]);
%   disp(result.summary)
%   plot(result.time_s/60, result.busPlanning_W.'); grid on
%   xlabel('Time [min]'); ylabel('Available solar bus power [W]');
%   legend('0.05 m^2','0.10 m^2','0.15 m^2','0.20 m^2');
%
% Optional parameter changes, without editing this file:
%   changes = struct('sunTemperature_C', 70, 'agingRetained', 0.85);
%   result = arrayPowerQuick(out, cfg, [0.05 0.10], changes);
%
% OPTIONAL 600 km DEMONSTRATION (NOT a verified worst-case orbit):
%   cfg = config();
%   cfg.h = 600; cfg.use.eclipse = true; cfg.ode.dtOut = 5;
%   out = propagate(cfg, 1);
%   result = arrayPowerQuick(out, cfg, [0.05 0.10 0.15 0.20]);
% The demonstration retains Alessandro's default inclination, RAAN and date.
% Replace those with the agreed orbit before presenting worst-case results.
%
% Interpretation:
% - busBOL_W: beginning-of-life available solar power after stated losses.
% - busPlanning_W: same calculation with a 10% aging allowance by default.
% - The allowance is NOT a predicted EOL at any specified mission duration.
% - Default sunlight temperature is 127 C: the user's preliminary assumption
%   that only the front radiates. The illustrative equilibrium estimate omits
%   electrical power extraction, Earth heating and conduction; it is not a
%   verified maximum temperature. The power coefficient is extrapolated
%   beyond its published 15 to 75 C range, so the warning below is expected.
% - No battery losses, spacecraft loads or design margin are included.
% - Assumes MPPT and adequate EPS voltage/current/power capacity; no clipping.
% - Array loss factors must not be reapplied if already in a panel rating.
% - Statistics use the ACTUAL supplied time window. Alessandro's sampled propagation
%   may stop before the exact orbit endpoint. Window energy is not necessarily
%   energy for one complete orbit. Use eclipseTimes for eclipse durations.
%
% Sources / provenance (accessed 2026-09-18):
% NASA reports nominal 30% efficiency for modern multijunction space cells:
% https://www.nasa.gov/smallsat-institute/sst-soa/power-subsystems/
% Spectrolab XTE+ LEO: 32.2% at AM0=135.3 mW/cm^2, 28 C;
% BOL power temperature slope -92 microW/cm^2/C (valid 15 to 75 C).
% Relative slope = -92e-6/(0.322*135.3e-3) = -0.0021117 / C.
% We round this to -0.0021 / C as a representative, unselected-cell input.
% https://www.spectrolab.com/photovoltaics/XTE%2B%20LEO%20Data%20Sheet.pdf
% NASA PMAD Table 3-8 reports differing MAXIMUM conversion efficiencies;
% 95% here is a design assumption, not an average or guaranteed efficiency.
% Temperature, coverage and all other retention factors are assumptions.
% 600 km altitude alone does not determine panel temperature:
% https://www.nasa.gov/smallsat-institute/sst-soa/thermal-control/

if nargin < 4
    overrides = struct();
end

% Editable baseline. Retention 0.97 means 97% retained, i.e. 3% loss.
p.cellEfficiency = 0.30;       % representative space multijunction cell
p.cellCoverage = 0.80;         % assumed active-cell / panel-face area
p.referenceTemperature_C = 28;
p.sunTemperature_C = 127;      % assumed fixed cell temperature; front radiates
p.shadowTemperature_C = -20;   % display only in full eclipse; generation=0
p.powerTempCoeff_perC = -0.0021; % -0.21%/C, relative POWER coefficient
p.selfShadowRetained = 1.00;   % assumes unobstructed deployed array
p.mismatchRetained = 0.98;     % assumed 2% cell/string mismatch loss
p.opticalRetained = 0.97;      % assumed extra coverglass/assembly loss
p.wiringDiodeRetained = 0.97;  % assumed combined 3% harness/diode loss
p.mpptEfficiency = 0.98;       % assumed 2% maximum-power capture loss
p.converterEfficiency = 0.95; % assumed 5% conversion loss
p.agingRetained = 0.90;        % assumed 10% aging reserve; no assigned life

names = fieldnames(overrides);
for k = 1:numel(names)
    if ~isfield(p, names{k})
        error('arrayPowerQuick:parameter', 'Unknown parameter: %s', names{k});
    end
    p.(names{k}) = overrides.(names{k});
end

validateattributes(area_m2, {'numeric'}, ...
    {'real','finite','vector','nonempty','nonnegative'});
names = fieldnames(p);
for k = 1:numel(names)
    validateattributes(p.(names{k}), {'numeric'}, {'real','finite','scalar'});
end
fractionFields = {'cellEfficiency','cellCoverage','selfShadowRetained', ...
    'mismatchRetained','opticalRetained','wiringDiodeRetained', ...
    'mpptEfficiency','converterEfficiency','agingRetained'};
for k = 1:numel(fractionFields)
    validateattributes(p.(fractionFields{k}), {'numeric'}, {'>=',0,'<=',1});
end

t = out.t(:).';
illum = out.illum(:).';
validateattributes(t, {'numeric'}, {'real','finite','vector','nonempty'});
validateattributes(illum, {'numeric'}, ...
    {'real','finite','vector','>=',0,'<=',1});
if numel(t) < 2 || any(diff(t) <= 0) || numel(illum) ~= numel(t)
    error('arrayPowerQuick:time', 'Need >=2 increasing times and matching illumination.');
end

S = solarFlux(out, cfg);  % ALREADY includes Earth shadow and Sun distance!
S = S(:).';             % Do NOT multiply S by out.illum a second time.
if numel(S) ~= numel(t) || any(~isfinite(S)) || any(S < 0)
    error('arrayPowerQuick:flux', 'Invalid irradiance or time-grid mismatch.');
end

% Binary TEMPERATURE only: any direct illumination uses the hot temperature.
% Keep Alessandro's partial-eclipse attenuation in S; it costs no additional model.
isLit = illum > 0;
cellTemperature_C = p.shadowTemperature_C * ones(size(t));
cellTemperature_C(isLit) = p.sunTemperature_C;
if p.sunTemperature_C < 15 || p.sunTemperature_C > 75
    warning('arrayPowerQuick:temperature', ...
        ['Sun temperature is outside the example datasheet range 15 to 75 C; ' ...
         'the power temperature correction is an approximate extrapolation.']);
end
temperatureRetained = ones(size(t));
temperatureRetained(isLit) = 1 + p.powerTempCoeff_perC * ...
    (p.sunTemperature_C - p.referenceTemperature_C);
if any(temperatureRetained <= 0)
    error('arrayPowerQuick:temperature', 'Invalid temperature correction.');
end
% Do not extrapolate the temperature coefficient to cold eclipse conditions:
% the cold-state electrical output is already zero through S.

% W per m^2 of PHYSICAL panel, before and after EPS path losses.
arrayBOL_per_m2 = S .* temperatureRetained * p.cellEfficiency * ...
    p.cellCoverage * p.selfShadowRetained * p.mismatchRetained * ...
    p.opticalRetained;
busBOL_per_m2 = arrayBOL_per_m2 * p.wiringDiodeRetained * ...
    p.mpptEfficiency * p.converterEfficiency;

A = area_m2(:);
result.time_s = t;
result.area_m2 = A;
result.irradiance_W_m2 = S;
result.cellTemperature_C = cellTemperature_C;
result.arrayBOL_W = A * arrayBOL_per_m2;
result.arrayPlanning_W = result.arrayBOL_W * p.agingRetained;
result.busBOL_W = A * busBOL_per_m2;
result.busPlanning_W = result.busBOL_W * p.agingRetained;
result.params = p;
result.windowDuration_s = t(end) - t(1);
result.equivalentSunFraction = trapz(t, illum) / result.windowDuration_s;

energyBOL_Wh = trapz(t, result.busBOL_W, 2) / 3600;
energyPlanning_Wh = trapz(t, result.busPlanning_W, 2) / 3600;
averageBOL_W = energyBOL_Wh * 3600 / result.windowDuration_s;
averagePlanning_W = energyPlanning_Wh * 3600 / result.windowDuration_s;
result.summary = table(A, max(result.busBOL_W,[],2), ...
    max(result.busPlanning_W,[],2), averageBOL_W, averagePlanning_W, ...
    energyBOL_Wh, energyPlanning_Wh, 'VariableNames', ...
    {'Area_m2','PeakBOL_W','PeakPlanning_W','WindowAvgBOL_W', ...
     'WindowAvgPlanning_W','WindowEnergyBOL_Wh','WindowEnergyPlanning_Wh'});
end
