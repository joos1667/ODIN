% main_demo: runs the motion model and plots the resulting trajectory.

clear; close all; clc;

cfg = config(); % cfg: parameter struct
out = propagate(cfg, 10); % out: state history struct from propagate.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calling ArrayPowerQuick for rough array sizing trade
cfg = config();
cfg.h = 600;                  % Your chosen altitude [km]

out = propagate(cfg, 10);     % Ale's orbit calculation

% Calculate array power for different physical areas [m^2]
areas = [0.05 0.09 0.10 0.15 0.20];

arrayResult = arrayPowerQuick(out, cfg, areas);

% Display peak power, average power, and energy
disp(arrayResult.summary)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% RAAN recovered from the angular momentum vector, whose ECI components are
% h = |h| * [sin(inc)*sin(RAAN); -sin(inc)*cos(RAAN); cos(inc)]
raan = unwrap(atan2(out.hvec(1,:), -out.hvec(2,:)));
% raan: 1 x N unwrapped right ascension of the ascending node [rad]

ps = plotScale(out, cfg); % ps: axis units and averaging settings for this run length
alt = vecnorm(out.r) - cfg.Re; % alt: 1 x N altitude above cfg.Re [km]
lbl = sprintf('h_0 = %g km, i = %g deg, %.0f orbits', cfg.h, cfg.inc, ps.nOrb);
% lbl: run identifying figure title

figure('Color','w','Position',[100 100 900 450]);

subplot(2,1,1);
if ps.dense
    altLo = movmin(alt, ps.wOrb); % altLo: 1 x N per orbit minimum altitude [km]
    altHi = movmax(alt, ps.wOrb); % altHi: 1 x N per orbit maximum altitude [km]
    plot(ps.t(ps.dec), altLo(ps.dec), 'LineWidth', 1.0); grid on; hold on;
    plot(ps.t(ps.dec), altHi(ps.dec), 'LineWidth', 1.0);
    legend('per orbit min', 'per orbit max', 'Location', 'best');
else
    plot(ps.t, alt, 'LineWidth', 1.3); grid on;
end
ylabel('altitude [km]');
title(lbl);

subplot(2,1,2);
plot(ps.t(ps.dec), rad2deg(raan(ps.dec) - raan(1)), 'LineWidth', 1.3); grid on;
ylabel('\Delta RAAN [deg]'); xlabel(sprintf('time [%s]', ps.tName));

if cfg.use.eclipse
    S = solarFlux(out, cfg); % S: 1 x N solar irradiance at the spacecraft [W/m^2]

    figure('Color','w','Position',[100 100 900 450]);

    if ps.dense
        subplot(2,1,1);
        plot(ps.zt, S(ps.zoom), 'LineWidth', 1.3); grid on;
        ylabel('irradiance [W/m^2]'); xlabel('time [min]');
        title([lbl ', leading orbits']);

        Sbar = movmean(S, ps.w); % Sbar: 1 x N running mean irradiance [W/m^2]

        subplot(2,1,2);
        plot(ps.t(ps.dec), Sbar(ps.dec), 'LineWidth', 1.5); grid on;
        ylabel(sprintf('%d orbit average [W/m^2]', ps.nAvg));
        xlabel(sprintf('time [%s]', ps.tName));
    else
        plot(ps.t, S, 'LineWidth', 1.3); grid on;
        ylabel('irradiance [W/m^2]'); xlabel(sprintf('time [%s]', ps.tName));
        title(lbl);
    end
end

figure('Color','w');
plot3(out.r(1,:), out.r(2,:), out.r(3,:), 'LineWidth', 1.1);
axis equal; grid on; hold on;

if cfg.use.eclipse
    rEcl = out.r; % rEcl: 3 x N position history with the sunlit samples blanked out [km]
    rEcl(:, out.illum == 1) = NaN;
    plot3(rEcl(1,:), rEcl(2,:), rEcl(3,:), 'LineWidth', 1.1);
    legend('sunlit', 'eclipsed');
end

xlabel('X [km]'); ylabel('Y [km]'); zlabel('Z [km]');
title('ECI trajectory');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot of array trade
figure('Color', 'w');

plot(arrayResult.time_s / 60, ...
     arrayResult.busPlanning_W.', 'LineWidth', 1.5);

grid on;
xlabel('Time [min]');
ylabel('Available solar power [W]');
title('Array power at 127°C, including aging allowance');

legend('0.05 m²', '0.09 m²', '0.10 m²', ...
       '0.15 m²', '0.20 m²', 'Location', 'best');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
