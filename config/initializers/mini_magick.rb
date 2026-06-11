# MiniMagick 5.x auto-detects 'magick' (ImageMagick 7) in PATH.
# Ensure /opt/homebrew/bin is in PATH for macOS/CasaOS environments.
ENV["PATH"] = "/opt/homebrew/bin:#{ENV['PATH']}" unless ENV["PATH"].to_s.include?("/opt/homebrew/bin")
