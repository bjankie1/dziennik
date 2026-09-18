/**
 * Evaluates whether background sync should execute based on Europe/Warsaw local time.
 * Handles DST automatically via Intl.DateTimeFormat.
 * 
 * Rules:
 * - D-01: Night silence between 22:30 and 06:30.
 * - D-02: Weekday daytime (06:30 - 16:30) every ~30-40 min (on-takt: minute < 15 or 30 <= minute < 45).
 * - D-02: Weekday evening (16:30 - 22:30) every 60 min (on-takt: minute < 15).
 * - D-03: Weekends (Sat/Sun): exactly 2 slots (11:00-11:14 and 19:00-19:14).
 * 
 * @param {Date} date - Optional Date to evaluate (defaults to new Date())
 * @returns {{ shouldRun: boolean, reason: string, jitterMaxMs?: number }}
 */
function evaluateScheduleWindow(date = new Date()) {
  const warsawFormatter = new Intl.DateTimeFormat("en-US", {
    timeZone: "Europe/Warsaw",
    weekday: "short",
    hour: "numeric",
    minute: "numeric",
    hour12: false
  });

  const parts = warsawFormatter.formatToParts(date);
  const weekday = parts.find(p => p.type === "weekday")?.value; // "Mon", "Tue", etc.
  const hour = parseInt(parts.find(p => p.type === "hour")?.value || "0", 10);
  const minute = parseInt(parts.find(p => p.type === "minute")?.value || "0", 10);

  const totalMinutes = hour * 60 + minute;
  const isWeekend = weekday === "Sat" || weekday === "Sun";

  // D-01: Cisza nocna (22:30 - 06:30)
  // 22:30 is 1350 minutes; 06:30 is 390 minutes
  if (totalMinutes >= 22 * 60 + 30 || totalMinutes < 6 * 60 + 30) {
    return {
      shouldRun: false,
      reason: `Night silence active in Warsaw (22:30 - 06:30). Current time: ${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}.`
    };
  }

  // D-03: Weekendy (Sobota i Niedziela) - tylko 2 okna na dobę (11:00 i 19:00)
  if (isWeekend) {
    const isMorningSlot = hour === 11 && minute < 15;
    const isEveningSlot = hour === 19 && minute < 15;

    if (isMorningSlot || isEveningSlot) {
      return {
        shouldRun: true,
        jitterMaxMs: 180000, // up to 3 minutes jitter
        reason: `Weekend scheduled sync slot (${hour}:00).`
      };
    }

    return {
      shouldRun: false,
      reason: `Weekend outside scheduled slots (11:00 and 19:00). Current time: ${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}.`
    };
  }

  // D-02: Dni powszednie (Poniedziałek - Piątek)
  // 1. Szczyt dzienny: 06:30 - 16:30 (co ~30 minut: takt :00 i :30)
  if (totalMinutes >= 6 * 60 + 30 && totalMinutes < 16 * 60 + 30) {
    const isHalfHourTakt = minute < 15 || (minute >= 30 && minute < 45);
    if (isHalfHourTakt) {
      return {
        shouldRun: true,
        jitterMaxMs: 240000, // up to 4 minutes jitter
        reason: `Weekday daytime slot (30-min cadence at ${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}).`
      };
    }
    return {
      shouldRun: false,
      reason: `Weekday daytime off-takt 15-min interval skip.`
    };
  }

  // 2. Popołudnia / wieczory: 16:30 - 22:30 (co 60 minut: takt :00)
  if (totalMinutes >= 16 * 60 + 30 && totalMinutes < 22 * 60 + 30) {
    const isHourlyTakt = minute < 15;
    if (isHourlyTakt) {
      return {
        shouldRun: true,
        jitterMaxMs: 180000, // up to 3 minutes jitter
        reason: `Weekday evening slot (60-min cadence at ${String(hour).padStart(2, "0")}:00).`
      };
    }
    return {
      shouldRun: false,
      reason: `Weekday evening off-takt interval skip.`
    };
  }

  return {
    shouldRun: false,
    reason: "Unmatched window fallback."
  };
}

module.exports = { evaluateScheduleWindow };
