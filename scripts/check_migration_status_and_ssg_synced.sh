#!/usr/bin/bash

MAX_INIT_TIMEOUT_SECONDS=${MAX_INIT_TIMEOUT_SECONDS:-120}

# Fast pre-check: wait for Database socket to open before booting full Rails framework
bundle exec ruby -r clowder-common-ruby -r socket -e '
  host, port = if ClowderCommonRuby::Config.clowder_enabled?
    cfg = ClowderCommonRuby::Config.load
    [cfg.database.hostname, cfg.database.port]
  else
    [ENV.fetch("POSTGRESQL_HOST", "localhost"), ENV.fetch("POSTGRESQL_PORT", "5432").to_i]
  end

  puts "Waiting for database socket at #{host}:#{port}..."
  120.times do
    begin
      if host.start_with?("/")
        UNIXSocket.new("#{host}/.s.PGSQL.#{port}").close
      else
        TCPSocket.new(host, port).close
      end
      puts "Database socket is open!"
      exit 0
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EHOSTUNREACH, Errno::ENOENT, SocketError
      sleep 1
    end
  end
  puts "Timed out waiting for database socket at #{host}:#{port}"
  exit 1
' || exit 1

for ((i=1;i<=MAX_INIT_TIMEOUT_SECONDS;i++)); do
    if bundle exec rake --trace db:debug db:migrate ssg:check_synced; then
        exit 0
    else
        sleep 1
    fi
done

exit 1
