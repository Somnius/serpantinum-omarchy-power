const assert = require("node:assert/strict")
const model = require("../Model.js")

const states = { Charging: 1, Discharging: 2, FullyCharged: 4, PendingCharge: 5 }

assert.equal(model.batteryFraction(null), 0)
assert.equal(model.batteryFraction({ isPresent: true, percentage: 1.4 }), 1)
assert.equal(model.batteryFraction({ isPresent: true, percentage: -1 }), 0)
assert.equal(model.batteryState(null, false, states), "desktop")
assert.equal(model.batteryState({ isPresent: true, percentage: 0.5, state: 1 }, false, states), "charging")
assert.equal(model.batteryState({ isPresent: true, percentage: 0.5, state: 2 }, true, states), "discharging")
assert.equal(model.batteryState({ isPresent: true, percentage: 0.8, state: 5 }, false, states), "holding")
assert.equal(model.batteryState({ isPresent: true, percentage: 1, state: 4 }, false, states), "full")

assert.deepEqual(model.parseKeyValue("cpu\t12%\ninvalid\nmemory\t3.4 GiB\n"), {
  cpu: "12%",
  memory: "3.4 GiB"
})
assert.deepEqual(model.parseProfiles("balanced\t1\npower-saver\t0\nbalanced\t0\n"), {
  profiles: ["balanced", "power-saver"],
  active: "balanced"
})
assert.equal(model.formatProfile("power-saver"), "Power Saver")

console.log("model tests passed")
