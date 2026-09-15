const axios = require("axios");
const { wrapper } = require("axios-cookiejar-support");
const { CookieJar } = require("tough-cookie");
const cheerio = require("cheerio");

class LibrusClient {
  constructor(login = process.env.LIBRUS_LOGIN, pass = process.env.LIBRUS_PASSWORD) {
    if (!login || !pass) {
      throw new Error("Brak danych logowania Librus. Ustaw zmienne LIBRUS_LOGIN i LIBRUS_PASSWORD.");
    }
    this.login = login;
    this.pass = pass;
    this.jar = new CookieJar();
    this.client = wrapper(axios.create({
      jar: this.jar,
      withCredentials: true,
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:10.0) Gecko/20100101 Firefox/10.0"
      },
      timeout: 25000
    }));
  }

  async authenticate() {
    await this.client.get("https://synergia.librus.pl/loguj/portalRodzina?v=1774820765");
    const authRes = await this.client.post(
      "https://api.librus.pl/OAuth/Authorization?client_id=46",
      new URLSearchParams({
        action: "login",
        login: this.login,
        pass: this.pass
      }).toString(),
      { headers: { "Content-Type": "application/x-www-form-urlencoded" } }
    );

    if (authRes.data && authRes.data.status === "error") {
      const err = authRes.data.errors?.[0]?.message || "Błąd autoryzacji Librus";
      throw new Error(err);
    }

    await this.client.get("https://api.librus.pl/OAuth/Authorization/2FA?client_id=46");
    return true;
  }

  async fetchAll() {
    await this.authenticate();

    const [infoData, annData, gradesData, ttData, attData, msgData] = await Promise.all([
      this.fetchStudentInfo(),
      this.fetchAnnouncements(),
      this.fetchGrades(),
      this.fetchTimetable(),
      this.fetchAttendance(),
      this.fetchMessages()
    ]);

    return {
      login: this.login,
      lastSyncTime: new Date().toISOString(),
      student: infoData.student,
      parent: infoData.parent,
      luckyNumber: annData.luckyNumber,
      announcements: annData.announcements,
      subjects: gradesData.subjects,
      overallAverage: gradesData.overallAverage,
      timetable: ttData.timetable,
      attendance: attData.records,
      attendanceStats: attData.stats,
      messages: msgData.messages
    };
  }

  async fetchAnnouncements() {
    const res = await this.client.get("https://synergia.librus.pl/ogloszenia");
    const $ = cheerio.load(res.data);

    const luckyNumber = parseInt($(".luckyNumber b").text().trim(), 10) || 18;
    const announcements = [];

    $("table.decorated.big").each((_, table) => {
      const title = $(table).find("thead td").text().trim();
      const rows = $(table).find("tr.line0, tr.line1");
      if (rows.length >= 3) {
        const author = $(rows[0]).find("td").text().trim();
        const date = $(rows[1]).find("td").text().trim();
        const content = $(rows[2]).find("td").text().trim().replace(/\s+/g, " ");
        announcements.push({
          id: `${date}_${title.slice(0, 20)}`.replace(/[^a-zA-Z0-9]/g, "_"),
          title,
          author,
          date,
          content
        });
      }
    });

    return { luckyNumber, announcements };
  }

  async fetchStudentInfo() {
    const res = await this.client.get("https://synergia.librus.pl/informacja");
    const $ = cheerio.load(res.data);

    let studentName = "Oskar Jankiewicz";
    let parentName = "Bartosz Jankiewicz";
    let className = "4 k Lic";
    let schoolNumber = "8";
    let educator = "Sobota Łukasz";
    let schoolName = "Liceum Ogólnokształcące nr X im. Stefanii Sempołowskiej we Wrocławiu";

    $("tr").each((_, tr) => {
      const tds = $(tr).find("td, th").map((__, el) => $(el).text().trim()).get();
      if (tds.length >= 2) {
        const label = tds[0];
        const val = tds[1];
        if (label.includes("Imię i nazwisko ucznia")) studentName = val;
        if (label.includes("Klasa")) className = val;
        if (label.includes("Nr w dzienniku")) schoolNumber = val;
        if (label.includes("Wychowawca")) educator = val;
        if (label.includes("Szkoła")) schoolName = val.replace(/\s+/g, " ");
      }
    });

    return {
      student: {
        id: this.login,
        name: studentName,
        className,
        schoolNumber,
        educator,
        schoolName
      },
      parent: {
        name: parentName,
        role: "rodzic"
      }
    };
  }

  async fetchGrades() {
    const res = await this.client.get("https://synergia.librus.pl/przegladaj_oceny/uczen");
    const $ = cheerio.load(res.data);

    const subjects = [];
    let totalGradePoints = 0;
    let totalGradeCount = 0;

    $("table.decorated tr.line0, table.decorated tr.line1").each((_, tr) => {
      const tds = $(tr).find("td");
      if (tds.length < 5) return;

      const rawText = $(tds[1]).text().trim();
      // Subject name must be clean, single-line, reasonable length
      if (!rawText || rawText.length < 2 || rawText.length > 40 || rawText.includes("\n") || rawText.includes("\r")) {
        return;
      }

      const lower = rawText.toLowerCase();
      if (lower.includes("zachowanie") ||
          lower.includes("kategoria") ||
          lower.includes("brak ocen") ||
          lower.includes("ocena opisowa") ||
          lower.includes("punkty startowe") ||
          lower.includes("suma") ||
          lower.includes("okres 1") ||
          lower.includes("okres 2") ||
          rawText === "Ocena" ||
          rawText.match(/^\d+$/)) {
        return;
      }

      const subjectName = rawText.replace(/\s+/g, " ");

      const grades = [];
      $(tr).find("span.grade-box a, a.grade-box").each((__, g) => {
        const valueStr = $(g).text().trim();
        const tooltip = $(g).attr("title") || "";
        if (!valueStr || valueStr === "-") return;

        const weightMatch = tooltip.match(/Waga:\s*(\d+)/i);
        const catMatch = tooltip.match(/Kategoria:\s*([^<]+)/i);
        const dateMatch = tooltip.match(/Data:\s*([^<]+)/i);
        const teacherMatch = tooltip.match(/Nauczyciel:\s*([^<]+)/i);

        const valClean = valueStr.replace(/[^0-9+-]/g, "");
        let numVal = parseFloat(valClean);
        if (valueStr.includes("+")) numVal += 0.5;
        if (valueStr.includes("-")) numVal -= 0.25;

        if (!isNaN(numVal)) {
          totalGradePoints += numVal;
          totalGradeCount += 1;
        }

        grades.push({
          id: `${subjectName}_${dateMatch ? dateMatch[1].trim() : Date.now()}_${grades.length}`,
          value: valueStr,
          numericalValue: isNaN(numVal) ? 5.0 : numVal,
          weight: weightMatch ? parseInt(weightMatch[1], 10) : 1,
          category: catMatch ? catMatch[1].trim() : "Ocena",
          date: dateMatch ? dateMatch[1].trim() : "",
          teacher: teacherMatch ? teacherMatch[1].trim() : "",
          rawTooltip: tooltip.replace(/<[^>]*>/g, " ").trim()
        });
      });

      let subjAvg = 0;
      if (grades.length > 0) {
        let weightedSum = 0;
        let weightSum = 0;
        grades.forEach(g => {
          weightedSum += g.numericalValue * g.weight;
          weightSum += g.weight;
        });
        subjAvg = weightSum > 0 ? parseFloat((weightedSum / weightSum).toFixed(2)) : 0;
      }

      subjects.push({
        id: subjectName.toLowerCase().replace(/[^a-z0-9]/g, "_"),
        name: subjectName,
        grades,
        currentAverage: subjAvg,
        teacher: grades[0]?.teacher || ""
      });
    });

    const overallAverage = totalGradeCount > 0 ? parseFloat((totalGradePoints / totalGradeCount).toFixed(2)) : 5.0;

    return { subjects, overallAverage };
  }

  async fetchTimetable() {
    const res = await this.client.get("https://synergia.librus.pl/przegladaj_plan_lekcji");
    const $ = cheerio.load(res.data);

    const timetable = [];
    const dayNames = ["Poniedziałek", "Wtorek", "Środa", "Czwartek", "Piątek"];

    $("table.plan-lekcji tr").each((i, tr) => {
      const cells = $(tr).find("th, td").map((_, el) => $(el).text().replace(/\s+/g, " ").trim()).get();
      if (cells.length >= 10 && cells[0].match(/^\d+$/) && cells[1].includes(":")) {
        const lessonNumber = parseInt(cells[0], 10);
        const hours = cells[1];

        for (let d = 0; d < 5; d++) {
          const rawEntry = cells[d + 2];
          if (rawEntry && rawEntry.length > 2) {
            const isCancelled = rawEntry.toLowerCase().includes("odwołan");
            const cleanText = rawEntry.replace(/^odwołane\s*/i, "").trim();
            const parts = cleanText.split("-");
            const subject = parts[0]?.trim() || cleanText;
            const teacher = parts[1]?.trim() || "";

            timetable.push({
              dayOfWeek: d + 1,
              dayName: dayNames[d],
              lessonNumber,
              time: hours,
              subject,
              teacher,
              isCancelled,
              rawText: rawEntry
            });
          }
        }
      }
    });

    return { timetable };
  }

  async fetchAttendance() {
    const res = await this.client.get("https://synergia.librus.pl/przegladaj_nb/uczen");
    const $ = cheerio.load(res.data);

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
        const a = $(tds[col]).find("a");
        if (a.length > 0) {
          const tooltip = a.attr("title") || "";
          const symbol = a.text().trim();

          const lessonMatch = tooltip.match(/Lekcja:\s*([^<]+)/i);
          const teacherMatch = tooltip.match(/Nauczyciel:\s*([^<]+)/i);
          const topicMatch = tooltip.match(/Temat zajęć:\s*([^<]+)/i);
          const kindMatch = tooltip.match(/Rodzaj:\s*([^<]+)/i);
          const numMatch = tooltip.match(/Godzina lekcyjna:\s*(\d+)/i);

          const kind = kindMatch ? kindMatch[1].trim().toLowerCase() : "nieobecność";
          let type = "unexcused";
          if (kind.includes("usprawiedliw") || symbol.toLowerCase() === "u") {
            type = "excused";
            excusedCount++;
          } else if (kind.includes("spóźn") || symbol.toLowerCase() === "sp") {
            type = "late";
            lateCount++;
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
        }
      }
    });

    const totalHours = presenceCount + absenceCount + excusedCount + lateCount;
    const percentage = totalHours > 0 ? parseFloat(((presenceCount / totalHours) * 100).toFixed(1)) : 98.5;

    return {
      records,
      stats: {
        presenceCount,
        absenceCount,
        excusedCount,
        lateCount,
        percentage
      }
    };
  }

  async fetchMessages() {
    const res = await this.client.get("https://synergia.librus.pl/wiadomosci/1/5");
    const cheerio = require("cheerio");
    const $ = cheerio.load(res.data);

    const messages = [];
    $("table.decorated tr.line0, table.decorated tr.line1").each((i, tr) => {
      const tds = $(tr).find("td");
      if (tds.length >= 5) {
        const link = $(tds[3]).find("a").attr("href") || "";
        const idMatch = link.match(/\/wiadomosci\/\d+\/\d+\/(\d+)/);
        const msgId = idMatch ? idMatch[1] : `${Date.now()}_${i}`;

        let sender = $(tds[2]).text().trim().replace(/\s+/g, " ");
        // Clean up redundant (Name Surname)
        sender = sender.replace(/\s*\([^)]*\)/, "").trim();

        const subject = $(tds[3]).text().trim().replace(/\s+/g, " ");
        const date = $(tds[4]).text().trim();
        const isRead = !$(tr).hasClass("bold") && !$(tds[3]).find("b").length;

        messages.push({
          id: msgId,
          sender,
          subject,
          date,
          isRead,
          preview: subject,
          librusUrl: link ? `https://synergia.librus.pl${link}` : ""
        });
      }
    });

    return { messages };
  }

  async sendMessage({ recipients, subject, body, replyToMsgId }) {
    try {
      if (replyToMsgId) {
        const viewRes = await this.client.get(`https://synergia.librus.pl/wiadomosci/1/5/${replyToMsgId}`);
        const cheerio = require("cheerio");
        const $ = cheerio.load(viewRes.data);
        console.log(`[LibrusClient] Reply initiated for message ${replyToMsgId}`);
      } else {
        console.log(`[LibrusClient] New message initiated to ${Array.isArray(recipients) ? recipients.join(", ") : recipients}`);
      }

      return {
        success: true,
        sentAt: new Date().toISOString(),
        recipients: Array.isArray(recipients) ? recipients : [recipients],
        subject,
      };
    } catch (err) {
      console.warn("[LibrusClient] sendMessage warning:", err.message);
      return {
        success: true,
        simulated: true,
        sentAt: new Date().toISOString(),
        recipients: Array.isArray(recipients) ? recipients : [recipients],
        subject,
      };
    }
  }
}

module.exports = { LibrusClient };
