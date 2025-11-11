FROM openproject/community:13

# Copy entrypoint wrapper
COPY docker-entrypoint-wrapper.sh /usr/local/bin/docker-entrypoint-wrapper.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-wrapper.sh

# Use wrapper as entrypoint (OpenProject uses ./docker-entrypoint.sh, not in /usr/local/bin)
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-wrapper.sh"]
