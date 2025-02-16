import { AppRootProps } from '@grafana/data';
import React from 'react';

import { PluginsPage } from './Plugins.page';

/**
 * App
 */
export const App: React.FC<AppRootProps> = () => {
  return <PluginsPage />;
};
