const { describe, it } = require("node:test");
const assert = require("node:assert");
const { evaluateScheduleWindow } = require("../src/schedule_evaluator");

describe("Warsaw Timezone Schedule Evaluator", () => {
  // Helper to create a specific Date in Europe/Warsaw
  // Note: 2026-09-18 is Friday (Europe/Warsaw is UTC+2 during CEST)
  function createWarsawDate(year, month, day, hour, minute) {
    // CEST is UTC+2
    const utcHour = hour - 2;
    return new Date(Date.UTC(year, month - 1, day, utcHour, minute));
  }

  it("should enforce night silence between 22:30 and 06:30 (D-01)", () => {
    // 23:00 on Friday
    const d23 = createWarsawDate(2026, 9, 18, 23, 0);
    assert.strictEqual(evaluateScheduleWindow(d23).shouldRun, false, "23:00 must be night silence");

    // 01:30 on Saturday
    const d01 = createWarsawDate(2026, 9, 19, 1, 30);
    assert.strictEqual(evaluateScheduleWindow(d01).shouldRun, false, "01:30 must be night silence");

    // 04:15 on Wednesday
    const d04 = createWarsawDate(2026, 9, 16, 4, 15);
    assert.strictEqual(evaluateScheduleWindow(d04).shouldRun, false, "04:15 must be night silence");

    // 06:29 on Thursday
    const d0629 = createWarsawDate(2026, 9, 17, 6, 29);
    assert.strictEqual(evaluateScheduleWindow(d0629).shouldRun, false, "06:29 must still be night silence");

    // 22:30 boundary on Tuesday
    const d2230 = createWarsawDate(2026, 9, 15, 22, 30);
    assert.strictEqual(evaluateScheduleWindow(d2230).shouldRun, false, "22:30 must begin night silence");
  });

  it("should permit sync at 06:30 daytime boundary on weekdays (D-01/D-02)", () => {
    // 06:30 on Friday
    const d0630 = createWarsawDate(2026, 9, 18, 6, 30);
    const result = evaluateScheduleWindow(d0630);
    assert.strictEqual(result.shouldRun, true, "06:30 on weekday should start daytime sync");
    assert.ok(result.jitterMaxMs > 0, "Should have jitter");
  });

  it("should follow 30-min cadence on weekday school hours 06:30 - 16:30 (D-02)", () => {
    // Wednesday 10:00 (on-takt)
    const d1000 = createWarsawDate(2026, 9, 16, 10, 0);
    assert.strictEqual(evaluateScheduleWindow(d1000).shouldRun, true, "10:00 on-takt should run");

    // Wednesday 10:15 (off-takt)
    const d1015 = createWarsawDate(2026, 9, 16, 10, 15);
    assert.strictEqual(evaluateScheduleWindow(d1015).shouldRun, false, "10:15 off-takt should skip");

    // Wednesday 10:30 (on-takt)
    const d1030 = createWarsawDate(2026, 9, 16, 10, 30);
    assert.strictEqual(evaluateScheduleWindow(d1030).shouldRun, true, "10:30 on-takt should run");
  });

  it("should follow 60-min cadence on weekday evenings 16:30 - 22:30 (D-02)", () => {
    // Thursday 17:05 (on-takt)
    const d1705 = createWarsawDate(2026, 9, 17, 17, 5);
    assert.strictEqual(evaluateScheduleWindow(d1705).shouldRun, true, "17:05 should run in hourly takt");

    // Thursday 17:30 (off-takt)
    const d1730 = createWarsawDate(2026, 9, 17, 17, 30);
    assert.strictEqual(evaluateScheduleWindow(d1730).shouldRun, false, "17:30 should skip in hourly takt");
  });

  it("should restrict weekend sync to 11:00 and 19:00 slots (D-03)", () => {
    // Saturday 11:05 (morning slot)
    const sat11 = createWarsawDate(2026, 9, 19, 11, 5);
    assert.strictEqual(evaluateScheduleWindow(sat11).shouldRun, true, "Saturday 11:05 should run");

    // Saturday 14:00 (outside slots)
    const sat14 = createWarsawDate(2026, 9, 19, 14, 0);
    assert.strictEqual(evaluateScheduleWindow(sat14).shouldRun, false, "Saturday 14:00 should skip");

    // Sunday 19:10 (evening slot)
    const sun19 = createWarsawDate(2026, 9, 20, 19, 10);
    assert.strictEqual(evaluateScheduleWindow(sun19).shouldRun, true, "Sunday 19:10 should run");

    // Sunday 20:00 (outside slots)
    const sun20 = createWarsawDate(2026, 9, 20, 20, 0);
    assert.strictEqual(evaluateScheduleWindow(sun20).shouldRun, false, "Sunday 20:00 should skip");
  });
});
