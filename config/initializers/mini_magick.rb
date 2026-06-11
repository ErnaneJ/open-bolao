# On macOS, Homebrew installs ImageMagick to /opt/homebrew/bin which may not
# be in PATH when Rails boots. Linux/Docker images have it in /usr/bin already.
if RUBY_PLATFORM.include?("darwin")
  ENV["PATH"] = "/opt/homebrew/bin:#{ENV['PATH']}" unless ENV["PATH"].to_s.include?("/opt/homebrew/bin")
end
