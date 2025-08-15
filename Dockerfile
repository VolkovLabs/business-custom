# Use a specific version of Grafana OSS as the base image for reproducibility
FROM grafana/grafana-oss:12.1.1

# Label the image for better tracking and metadata
LABEL maintainer="Volkov Labs <support@volkovlabs.io>" \
      description="Customized Grafana image for Business Suite" \
      version="12.1.1"

# Switch to root user for system-level operations
USER root

##################################################################
# CONFIGURATION - Environment Variables for Grafana
##################################################################
ENV GF_ENABLE_GZIP=true \
    GF_USERS_DEFAULT_THEME=tron \
    GF_AUTH_ANONYMOUS_ENABLED=true \
    GF_AUTH_BASIC_ENABLED=false \
    GF_PANELS_DISABLE_SANITIZE_HTML=true \
    GF_ANALYTICS_CHECK_FOR_UPDATES=false \
    GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/etc/grafana/provisioning/dashboards/business.json \
    GF_SNAPSHOTS_ENABLED=false \
    GF_EXPLORE_ENABLED=false \
    GF_NEWS_NEWS_FEED_ENABLED=false \
    GF_ALERTING_ENABLED=false \
    GF_PUBLIC_DASHBOARDS_ENABLED=true \
    GF_UNIFIED_ALERTING_ENABLED=false \
#    GF_PLUGINS_PREINSTALL_DISABLED=true \
    GF_PATHS_PROVISIONING=/etc/grafana/provisioning \
    GF_PATHS_PLUGINS=/var/lib/grafana/plugins
#    GF_FEATURE_TOGGLES_ENABLE="kubernetesDashboards dashboardNewLayouts"

# Copy provisioning files with proper ownership
COPY --chown=grafana:root provisioning/ ${GF_PATHS_PROVISIONING}/

##################################################################
# VISUAL CUSTOMIZATION - Replace branding assets
##################################################################
COPY --chown=grafana:root img/fav32.png /usr/share/grafana/public/img/fav32.png
COPY --chown=grafana:root img/fav32.png /usr/share/grafana/public/img/apple-touch-icon.png

# Replace Logo
COPY img/logo.svg /usr/share/grafana/public/img/grafana_icon.svg
COPY img/logo.svg /tmp/logo.svg
RUN find /usr/share/grafana/public/build/static/img -type f -name 'grafana_icon.*.svg' -exec sh -c 'mv /tmp/logo.svg "$(dirname {})/$(basename {})" && chmod 644 "$(dirname {})/$(basename {})"' \;

## Update Background
COPY img/background.svg /tmp/background.svg
RUN find /usr/share/grafana/public/build/static/img -type f -name 'g8_login_dark.*.svg' -exec sh -c 'cp /tmp/background.svg "$(dirname {})/$(basename {})" && chmod 644 "$(dirname {})/$(basename {})"' \;
RUN find /usr/share/grafana/public/build/static/img -type f -name 'g8_login_light.*.svg' -exec sh -c 'mv /tmp/background.svg "$(dirname {})/$(basename {})" && chmod 644 "$(dirname {})/$(basename {})"' \;

##################################################################
# HTML & JS CUSTOMIZATION - Update titles, menus, and branding
##################################################################
# Update title and loading text in index.html
RUN sed -i 's|<title>\[\[.AppTitle\]\]</title>|<title>Business Suite</title>|g' /usr/share/grafana/public/views/index.html && \
    sed -i 's|Loading Grafana|Loading Business Suite|g' /usr/share/grafana/public/views/index.html

# Customize Mega and Help menu in index.html
RUN sed -i "s|\[\[.NavTree\]\],|nav,|g; \
    s|window.grafanaBootData = {| \
    let nav = [[.NavTree]]; \
    const dashboards = nav.find((element) => element.id === 'dashboards/browse'); \
    if (dashboards) { dashboards['children'] = [];} \
    const connections = nav.find((element) => element.id === 'connections'); \
    if (connections) { connections['url'] = '/datasources'; connections['children'].shift(); } \
    const help = nav.find((element) => element.id === 'help'); \
    if (help) { help['subTitle'] = 'Business Customization 12.1.1'; help['children'] = [];} \
    window.grafanaBootData = {|g" \
    /usr/share/grafana/public/views/index.html && \
    sed -i "s|window.grafanaBootData = {| \
    nav.splice(3, 1); \
    window.grafanaBootData = {|g" \
    /usr/share/grafana/public/views/index.html

# Update JavaScript files for branding and feature toggles
RUN find /usr/share/grafana/public/build/ -name "*.js" -type f \
    -exec sed -i 's|AppTitle="Grafana"|AppTitle="Business Suite"|g' {} \; \
    -exec sed -i 's|LoginTitle="Welcome to Grafana"|LoginTitle="Business Suite for Grafana"|g' {} \; \
    -exec sed -i 's|\[{target:"_blank",id:"documentation".*grafana_footer"}\]|\[\]|g' {} \; \
    -exec sed -i 's|({target:"_blank",id:"license",.*licenseUrl})|()|g' {} \; \
    -exec sed -i 's|({target:"_blank",id:"version",text:..versionString,url:.?"https://github.com/grafana/grafana/blob/main/CHANGELOG.md":void 0})|()|g' {} \; \
    -exec sed -i 's|.push({target:"_blank",id:"version",text:`${..edition}${.}`,url:..licenseUrl,icon:"external-link-alt"})||g' {} \;

# Update feature toggles in configuration
RUN sed -i 's|\[feature_toggles\]|\[feature_toggles\]\npinNavItems=false\nonPremToCloudMigrations=false\ncorrelations=false|g' /usr/share/grafana/conf/defaults.ini

##################################################################
# CLEANUP - Remove unused data sources and panels
##################################################################
# Remove native data sources
RUN rm -rf \
    /usr/share/grafana/public/app/plugins/datasource/elasticsearch \
    /usr/share/grafana/public/build/elasticsearch* \
    /usr/share/grafana/public/app/plugins/datasource/graphite \
    /usr/share/grafana/public/build/graphite* \
    /usr/share/grafana/public/app/plugins/datasource/opentsdb \
    /usr/share/grafana/public/build/opentsdb* \
    /usr/share/grafana/public/app/plugins/datasource/influxdb \
    /usr/share/grafana/public/build/influxdb* \
    /usr/share/grafana/public/app/plugins/datasource/mssql \
    /usr/share/grafana/public/build/mssql* \
    /usr/share/grafana/public/app/plugins/datasource/mysql \
    /usr/share/grafana/public/build/mysql* \
    /usr/share/grafana/public/app/plugins/datasource/tempo \
    /usr/share/grafana/public/build/tempo* \
    /usr/share/grafana/public/app/plugins/datasource/jaeger \
    /usr/share/grafana/public/build/jaeger* \
    /usr/share/grafana/public/app/plugins/datasource/zipkin \
    /usr/share/grafana/public/build/zipkin* \
    /usr/share/grafana/public/app/plugins/datasource/azuremonitor \
    /usr/share/grafana/public/build/azureMonitor* \
    /usr/share/grafana/public/app/plugins/datasource/cloudwatch \
    /usr/share/grafana/public/build/cloudwatch* \
    /usr/share/grafana/public/app/plugins/datasource/cloud-monitoring \
    /usr/share/grafana/public/build/cloudMonitoring* \
    /usr/share/grafana/public/app/plugins/datasource/parca \
    /usr/share/grafana/public/build/parca* \
    /usr/share/grafana/public/app/plugins/datasource/phlare \
    /usr/share/grafana/public/build/phlare* \
    /usr/share/grafana/public/app/plugins/datasource/grafana-pyroscope-datasource \
    /usr/share/grafana/public/build/pyroscope*

# Remove Cloud and Enterprise categories from JS files
RUN find /usr/share/grafana/public/build/ -name "*.js" -type f \
    -exec sed -i 's|.id==="enterprise"|.id==="notanenterprise"|g' {} \; \
    -exec sed -i 's|.id==="cloud"|.id==="notacloud"|g' {} \;

# Remove native panels
RUN rm -rf \
    /usr/share/grafana/public/app/plugins/panel/alertlist \
    /usr/share/grafana/public/app/plugins/panel/annolist \
    /usr/share/grafana/public/app/plugins/panel/dashlist \
    /usr/share/grafana/public/app/plugins/panel/news \
    /usr/share/grafana/public/app/plugins/panel/geomap \
    /usr/share/grafana/public/app/plugins/panel/table-old \
    /usr/share/grafana/public/app/plugins/panel/traces \
    /usr/share/grafana/public/app/plugins/panel/flamegraph

##################################################################
# FINALIZE - Switch back to non-root user for security
##################################################################
USER grafana

# Healthcheck to ensure Grafana is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# Expose Grafana default port
EXPOSE 3000