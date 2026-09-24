function cfg = config()
% config: returns the parameter struct used by every other function.
% cfg: struct holding all constants, orbit elements and solver settings.

cfg.mu = 398600.4418; % cfg.mu: Earth gravitational parameter [km^3/s^2]
cfg.Re = 6378.137; % cfg.Re: Earth equatorial radius [km]
cfg.J2 = 1.082626683e-3; % cfg.J2: Earth second zonal harmonic coefficient
cfg.Rsun = 695700; % cfg.Rsun: Sun mean radius [km]
cfg.AU = 149597870.7; % cfg.AU: astronomical unit [km]
cfg.S0 = 1361; % cfg.S0: solar constant, irradiance at 1 AU [W/m^2]

cfg.epoch = [2026 9 15 0 0 0]; % cfg.epoch: UTC calendar instant at sim start [yr mon day hr min s]

cfg.h = 800; % cfg.h: orbit altitude above cfg.Re [km]
cfg.inc = 98.6; % cfg.inc: orbit inclination [deg]
cfg.raan0 = 0; % cfg.raan0: initial right ascension of ascending node [deg]
cfg.argp0 = 0; % cfg.argp0: initial argument of perigee [deg]
cfg.nu0 = 0; % cfg.nu0: initial true anomaly [deg]
cfg.ecc = 0; % cfg.ecc: orbit eccentricity

cfg.use.J2 = true; % cfg.use.J2: enable the J2 acceleration term
cfg.use.eclipse = true; % cfg.use.eclipse: enable the Sun direction and Earth shadow history
cfg.use.drag = false; % cfg.use.drag: enable atmospheric drag [not implemented]
cfg.use.srp = false; % cfg.use.srp: enable solar radiation pressure [not implemented]

cfg.eclipse.model = 'conical'; % cfg.eclipse.model: shadow geometry, 'conical' or 'cylindrical'

cfg.ode.relTol = 1e-11; % cfg.ode.relTol: ode45 relative error tolerance
cfg.ode.absTol = 1e-11; % cfg.ode.absTol: ode45 absolute error tolerance
cfg.ode.dtOut = 60; % cfg.ode.dtOut: spacing of the uniform output time grid [s]

end
