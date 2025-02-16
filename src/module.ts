import { AppPlugin } from '@grafana/data';

import { App } from './components';

/**
 * App Plugin
 */
export const plugin = new AppPlugin().setRootPage(App);
