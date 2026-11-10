-- BigLinux
--
-- Make a newly connected output the default sink.
--
-- PulseAudio's module-switch-on-connect cannot do this inside pipewire-pulse,
-- which starts before WirePlumber has created the sound cards: every card looks
-- newly connected there, and the last one to appear replaces the person's
-- choice at each login. Here a sink becomes the default only when all of these
-- hold:
--
--   - it belongs to a device, which virtual sinks, filters and loopbacks lack;
--   - its device is a USB, FireWire or Bluetooth device, since a PCI card
--     that reappears was handed back by a program that reserved it, such as a
--     DAW;
--   - its device is not a microphone or webcam, which can show an output too;
--   - its device connected after start-up and this is its first output, since
--     a profile switch recreates the node of a device already there;
--   - the person never chose it: WirePlumber's "default-nodes" state holds the
--     configured sink and every earlier choice, so this also limits a USB card
--     handed back by a DAW to one switch.

log = Log.open_topic ("s-biglinux-switch-on-connect")

-- Cards, device reservations and Bluetooth reconnects keep arriving for seconds
-- after login with no signal that they are done, so this window stands for it.
-- A device plugged in during the window is not switched to.
STARTUP_USEC = 20 * 1000000

local started_usec = GLib.get_monotonic_time ()
local state = State ("default-nodes")

-- object.serial of the devices connected after start-up whose first output
-- has not appeared yet
local waiting_devices = {}

SimpleEventHook {
  name = "biglinux/switch-on-connect/device-added",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "device-added" },
      Constraint { "media.class", "=", "Audio/Device" },
    },
  },
  execute = function (event)
    local props = event:get_properties ()
    local bus = props ["device.bus"]
    local form_factor = props ["device.form-factor"]

    if props ["device.api"] == "alsa" and bus ~= "usb" and bus ~= "firewire" then
      return
    end
    if form_factor == "microphone" or form_factor == "webcam" then
      return
    end
    if GLib.get_monotonic_time () - started_usec >= STARTUP_USEC then
      waiting_devices [props ["object.serial"]] = true
    end
  end
}:register ()

SimpleEventHook {
  name = "biglinux/switch-on-connect/device-removed",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "device-removed" },
    },
  },
  execute = function (event)
    waiting_devices [event:get_properties () ["object.serial"]] = nil
  end
}:register ()

SimpleEventHook {
  name = "biglinux/switch-on-connect/node-added",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "node-added" },
      Constraint { "media.class", "=", "Audio/Sink", type = "pw-global" },
    },
  },
  execute = function (event)
    -- With this off, WirePlumber keeps no record of the person's choices.
    if not Settings.get_boolean ("node.restore-default-targets") then
      return
    end

    local props = event:get_subject ().properties
    local name = props ["node.name"]
    local api = props ["device.api"]
    local device_id = tonumber (props ["device.id"])

    if (api ~= "alsa" and api ~= "bluez5") or not device_id then
      return
    end

    local source = event:get_source ()
    local device = source:call ("get-object-manager", "device"):lookup {
      Constraint { "bound-id", "=", device_id, type = "gobject" },
    }
    local serial = device and device.properties ["object.serial"]

    if not serial or not waiting_devices [serial] then
      return
    end
    waiting_devices [serial] = nil

    local metadata = source:call ("get-object-manager", "metadata"):lookup {
      Constraint { "metadata.name", "=", "default" },
    }
    if not metadata then
      return
    end

    local configured = metadata:find (0, "default.configured.audio.sink")
    if configured and Json.Raw (configured):parse ().name == name then
      return
    end

    local stored = state:load ()
    local key = "default.configured.audio.sink"
    local index = 0
    while stored [key] do
      if stored [key] == name then
        log:info ("not switching to " .. name .. ": chosen before")
        return
      end
      key = "default.configured.audio.sink." .. tostring (index)
      index = index + 1
    end

    log:info ("switching to newly connected " .. name)
    metadata:set (0, "default.configured.audio.sink", "Spa:String:JSON",
        Json.Object { ["name"] = name }:to_string ())
  end
}:register ()
