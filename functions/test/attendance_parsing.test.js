const { describe, it } = require("node:test");
const assert = require("node:assert");
const cheerio = require("cheerio");

describe("Attendance Parsing & Reconciliation", () => {
  function parseHtmlAttendance(html) {
    const $ = cheerio.load(html);
    const records = [];
    let presenceCount = 142;
    let absenceCount = 0;
    let excusedCount = 0;
    let lateCount = 0;

    $("table.decorated tr.line0, table.decorated tr.line1").each((_, tr) => {
      const tds = $(tr).find("td");
      const dateText = $(tds[0]).text().trim();
      if (!dateText) return;

      for (let col = 1; col <= 13; col++) {
        $(tds[col]).find("a").each((_, aEl) => {
          const tooltip = $(aEl).attr("title") || "";
          const symbol = $(aEl).text().trim();
          if (!tooltip && !symbol) return;

          const lessonMatch = tooltip.match(/Lekcja:\s*([^<]+)/i);
          const teacherMatch = tooltip.match(/Nauczyciel:\s*([^<]+)/i);
          const topicMatch = tooltip.match(/Temat zajęć:\s*([^<]+)/i);
          const kindMatch = tooltip.match(/Rodzaj:\s*([^<]+)/i);
          const numMatch = tooltip.match(/Godzina lekcyjna:\s*(\d+)/i);

          const kind = kindMatch ? kindMatch[1].trim().toLowerCase() : "";
          const lowerTooltip = tooltip.toLowerCase();
          const lowerSymbol = symbol.toLowerCase();

          let type = "unexcused";
          if (
            kind.includes("uspr") ||
            kind.includes("usprawiedliw") ||
            lowerSymbol === "u" ||
            lowerSymbol.startsWith("u") ||
            lowerSymbol.includes("unb") ||
            lowerTooltip.includes("e-usprawiedliwienia") ||
            lowerTooltip.includes("usprawiedliwienie dodane")
          ) {
            type = "excused";
            excusedCount++;
          } else if (
            kind.includes("zwoln") ||
            lowerSymbol.startsWith("zw")
          ) {
            type = "exempted";
            excusedCount++;
          } else if (
            kind.includes("spóźn") ||
            lowerSymbol.startsWith("sp")
          ) {
            type = "late";
            lateCount++;
          } else if (
            !kind.includes("nieobecn") &&
            (kind.includes("obecn") || lowerSymbol === "ob" || lowerSymbol === "•")
          ) {
            type = "present";
            presenceCount++;
          } else {
            type = "unexcused";
            absenceCount++;
          }

          records.push({
            id: `att_${dateText.split(' ')[0]}_${col}_${records.length}`,
            date: dateText.split(' ')[0],
            dateDisplay: dateText,
            lessonNumber: numMatch ? parseInt(numMatch[1], 10) : col - 1,
            subjectName: lessonMatch ? lessonMatch[1].trim() : "Lekcja",
            teacher: teacherMatch ? teacherMatch[1].trim() : "",
            topic: topicMatch ? topicMatch[1].trim() : "",
            type,
            symbol,
            rawTooltip: tooltip.replace(/<[^>]*>/g, " ").trim()
          });
        });
      }
    });

    return { records, stats: { presenceCount, absenceCount, excusedCount, lateCount } };
  }

  function reconcileAttendanceWithJustifications(records, stats, justList) {
    if (!Array.isArray(justList) || justList.length === 0) return;
    records.forEach(rec => {
      for (const just of justList) {
        const statusLower = (just.status || "").toLowerCase();
        const isApproved = statusLower.includes("uspr") || statusLower.includes("zaakcept");
        const isPending = statusLower.includes("oczekuj") || statusLower.includes("przesłan") || statusLower.includes("nowe");
        const period = just.period || "";

        if (rec.date && period.includes(rec.date)) {
          const mentionsLesson = /lekcj/i.test(period);
          const lessonRegex = new RegExp(`\\b${rec.lessonNumber}\\b`);
          if (!mentionsLesson || lessonRegex.test(period)) {
            if (isApproved) {
              if (rec.type === "unexcused") {
                rec.type = "excused";
                if (stats) {
                  stats.absenceCount = Math.max(0, (stats.absenceCount || 1) - 1);
                  stats.excusedCount = (stats.excusedCount || 0) + 1;
                }
              }
              rec.justificationStatus = "approved";
              rec.justificationReason = just.content || "e-Usprawiedliwienie zaakceptowane";
            } else if (isPending) {
              rec.justificationStatus = "requested";
              rec.justificationReason = just.content || "e-Usprawiedliwienie w trakcie weryfikacji";
            }
            break;
          }
        }
      }
    });
  }

  it("should correctly classify 'nieobecność uspr.' with unb symbol as excused", () => {
    const html = `
      <table class="decorated">
        <tr class="line0">
          <td>2026-09-01 (wt.)</td>
          <td></td>
          <td>
            <a title="Rodzaj: nieobecność uspr.<br>Data: 2026-09-01 (wt.)<br>Lekcja: Zajęcia z wychowawcą<br>Godzina lekcyjna: 2<br>Usprawiedliwienie dodane za pomocą modułu e-Usprawiedliwienia">unb</a>
          </td>
        </tr>
      </table>
    `;
    const res = parseHtmlAttendance(html);
    assert.strictEqual(res.records.length, 1);
    assert.strictEqual(res.records[0].type, "excused");
    assert.strictEqual(res.records[0].lessonNumber, 2);
    assert.strictEqual(res.records[0].symbol, "unb");
    assert.strictEqual(res.stats.excusedCount, 1);
    assert.strictEqual(res.stats.absenceCount, 0);
  });

  it("should correctly classify 'zwolnienie' with zw symbol as exempted", () => {
    const html = `
      <table class="decorated">
        <tr class="line1">
          <td>2026-09-18 (pt.)</td>
          <td>
            <a title="Rodzaj: zwolnienie<br>Data: 2026-09-18 (pt.)<br>Lekcja: Zajęcia z wychowawcą<br>Godzina lekcyjna: 0">zw</a>
          </td>
        </tr>
      </table>
    `;
    const res = parseHtmlAttendance(html);
    assert.strictEqual(res.records.length, 1);
    assert.strictEqual(res.records[0].type, "exempted");
    assert.strictEqual(res.records[0].lessonNumber, 0);
    assert.strictEqual(res.stats.excusedCount, 1);
    assert.strictEqual(res.stats.absenceCount, 0);
  });

  it("should correctly classify 'nieobecność' with nb symbol as unexcused (not present)", () => {
    const html = `
      <table class="decorated">
        <tr class="line0">
          <td>2026-09-01 (wt.)</td>
          <td>
            <a title="Rodzaj: nieobecność<br>Data: 2026-09-01 (wt.)<br>Lekcja: Zajęcia z wychowawcą<br>Godzina lekcyjna: 3">nb</a>
          </td>
        </tr>
      </table>
    `;
    const res = parseHtmlAttendance(html);
    assert.strictEqual(res.records.length, 1);
    assert.strictEqual(res.records[0].type, "unexcused");
    assert.strictEqual(res.records[0].lessonNumber, 3);
    assert.strictEqual(res.stats.absenceCount, 1);
  });

  it("should reconcile unexcused record with approved e-Usprawiedliwienie", () => {
    const records = [
      { id: "att_1", date: "2026-09-01", lessonNumber: 2, type: "unexcused" },
      { id: "att_2", date: "2026-09-05", lessonNumber: 1, type: "unexcused" }
    ];
    const stats = { absenceCount: 2, excusedCount: 0 };
    const justList = [
      {
        period: "2026-09-01, lekcja: 2",
        status: "usprawiedliwione (Sobota Łukasz)",
        content: "Wizyta lekarska"
      }
    ];

    reconcileAttendanceWithJustifications(records, stats, justList);

    assert.strictEqual(records[0].type, "excused");
    assert.strictEqual(records[0].justificationStatus, "approved");
    assert.strictEqual(records[0].justificationReason, "Wizyta lekarska");
    assert.strictEqual(stats.absenceCount, 1);
    assert.strictEqual(stats.excusedCount, 1);

    assert.strictEqual(records[1].type, "unexcused");
    assert.strictEqual(records[1].justificationStatus, undefined);
  });
});
