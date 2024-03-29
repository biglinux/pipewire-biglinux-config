
alsa_monitor.rules = {
    apply_properties = {
      --["node.nick"]              = "My Node",
      --["node.description"]       = "My Node Description",
      --["priority.driver"]        = 100,
      --["priority.session"]       = 100,
      --["node.pause-on-idle"]     = false,
      --["monitor.channel-volumes"] = false
      --["resample.quality"]       = 4,
      --["resample.disable"]       = false,
      --["channelmix.normalize"]   = false,
      --["channelmix.mix-lfe"]     = false,
      --["channelmix.upmix"]       = true,
      --["channelmix.upmix-method"] = "psd",  -- "none" or "simple"
      --["channelmix.lfe-cutoff"]  = 150,
      --["channelmix.fc-cutoff"]   = 12000,
      --["channelmix.rear-delay"]  = 12.0,
      --["channelmix.stereo-widen"] = 0.0,
      --["channelmix.hilbert-taps"] = 0,
      --["channelmix.disable"]     = false,
      --["dither.noise"]           = 0,
      --["dither.method"]          = "none",  -- "rectangular", "triangular" or "shaped5"
      --["audio.channels"]         = 2,
      --["audio.format"]           = "S16LE",
      --["audio.rate"]             = 44100,
      --["audio.allowed-rates"]    = "32000,96000",
      --["audio.position"]         = "FL,FR",
      --["api.alsa.period-size"]   = 1024,
      --["api.alsa.period-num"]    = 2,
      ["api.alsa.headroom"]      = 1024,
      --["api.alsa.start-delay"]   = 0,
      --["api.alsa.disable-mmap"]  = false,
      --["api.alsa.disable-batch"] = false,
      --["api.alsa.use-chmap"]     = false,
      --["api.alsa.multirate"]     = true,
      --["latency.internal.rate"]  = 0
      --["latency.internal.ns"]    = 0
      --["clock.name"]             = "api.alsa.0"
      --["session.suspend-timeout-seconds"] = 5,  -- 0 disables suspend
  },
}
