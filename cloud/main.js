'use strict';

// Back4App loads this file in its Cloud Code runtime. Parse is supplied globally.
require('./src/workspaces').mount();
require('./src/catalog').mount();
require('./src/bookings').mount();
require('./src/public').mount();
