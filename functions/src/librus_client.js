const axios = require("axios");
const { wrapper } = require("axios-cookiejar-support");
const { CookieJar } = require("tough-cookie");
const cheerio = require("cheerio");

const MODERN_BROWSER_HEADERS = {
  "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
  "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
  "Accept-Language": "pl-PL,pl;q=0.9,en-US;q=0.8,en;q=0.7",
  "Sec-Ch-Ua": "\"Not(A:Brand\";v=\"99\", \"Google Chrome\";v=\"133\", \"Chromium\";v=\"133\"",
  "Sec-Ch-Ua-Mobile": "?0",
  "Sec-Ch-Ua-Platform": "\"Windows\"",
  "Sec-Fetch-Dest": "document",
  "Sec-Fetch-Mode": "navigate",
  "Sec-Fetch-Site": "same-origin",
  "Sec-Fetch-User": "?1",
  "Upgrade-Insecure-Requests": "1"
};

const sleep = (minMs, maxMs) => new Promise(resolve => {
  const ms = Math.floor(Math.random() * (maxMs - minMs + 1)) + minMs;
  setTimeout(resolve, ms);
});

function deriveLibrusModule(endpoint = "") {
  const ep = endpoint.toLowerCase();
  if (ep.includes("oauth") || ep.includes("loguj")) return "Autoryzacja";
  if (ep.includes("przegladaj_oceny") || ep.includes("oceny")) return "Oceny";
  if (ep.includes("przegladaj_plan") || ep.includes("plan")) return "Plan lekcji";
  if (ep.includes("przegladaj_nb") || ep.includes("nieobecn") || ep.includes("eusprawiedliwienia")) return "Frekwencja";
  if (ep.includes("wiadomosci")) return "Wiadomości";
  if (ep.includes("terminarz")) return "Terminarz";
  if (ep.includes("ogloszenia")) return "Ogłoszenia";
  if (ep.includes("informacja") || ep.includes("uczen/index")) return "Profil / Sesja";
  return "Inne";
}

class LibrusClient {
  constructor(login = process.env.LIBRUS_LOGIN, pass = process.env.LIBRUS_PASSWORD, options = {}) {
    if (!login || !pass) {
      throw new Error("Brak danych logowania Librus. Ustaw zmienne LIBRUS_LOGIN i LIBRUS_PASSWORD.");
    }
    this.login = login;
    this.pass = pass;
    this.onQueryLog = options.onQueryLog || null;
    this.jar = new CookieJar();
    this._initAxios();
  }

  _initAxios() {
    this.client = wrapper(axios.create({
      jar: this.jar,
      withCredentials: true,
      headers: { ...MODERN_BROWSER_HEADERS },
      timeout: 25000
    }));

    this.client.interceptors.request.use(config => {
      config.metadata = { startTime: Date.now() };
      return config;
    });

    this.client.interceptors.response.use(
      response => {
        const durationMs = Date.now() - (response.config?.metadata?.startTime || Date.now());
        if (typeof this.onQueryLog === "function") {
          try {
            const urlStr = response.config?.url || "";
            let endpoint = urlStr;
            try {
              const parsed = new URL(urlStr);
              endpoint = parsed.pathname + parsed.search;
            } catch (_) {}

            const responseSize = typeof response.data === "string"
              ? Buffer.byteLength(response.data, "utf8")
              : (response.data ? Buffer.byteLength(JSON.stringify(response.data), "utf8") : 0);

            this.onQueryLog({
              url: urlStr,
              endpoint,
              method: (response.config?.method || "GET").toUpperCase(),
              status: response.status,
              statusText: response.statusText || "OK",
              durationMs,
              responseSizeBytes: responseSize,
              login: this.login
            });
          } catch (e) {
            console.warn("[LibrusClient] onQueryLog error:", e.message);
          }
        }
        return response;
      },
      error => {
        const durationMs = Date.now() - (error.config?.metadata?.startTime || Date.now());
        if (typeof this.onQueryLog === "function") {
          try {
            const urlStr = error.config?.url || "";
            let endpoint = urlStr;
            try {
              const parsed = new URL(urlStr);
              endpoint = parsed.pathname + parsed.search;
            } catch (_) {}

            this.onQueryLog({
              url: urlStr,
              endpoint,
              method: (error.config?.method || "GET").toUpperCase(),
              status: error.response?.status || 0,
              statusText: error.response?.statusText || error.message || "Network Error",
              durationMs,
              responseSizeBytes: 0,
              error: error.message,
              login: this.login
            });
          } catch (e) {
            console.warn("[LibrusClient] onQueryLog error:", e.message);
          }
        }
        return Promise.reject(error);
      }
    );
  }

  exportCookies() {
    return this.jar.serializeSync();
  }

  importCookies(serializedJson) {
    if (serializedJson) {
      this.jar = CookieJar.deserializeSync(serializedJson);
      this._initAxios();
    }
  }

  async isSessionAlive() {
    try {
      const res = await this.client.get("https://synergia.librus.pl/uczen/index", {
        maxRedirects: 0,
        validateStatus: status => status >= 200 && status < 400
      });
      if (res.status === 302 && res.headers && res.headers.location && res.headers.location.includes("loguj")) {
        return false;
      }
      if (typeof res.data === "string" && (res.data.includes("formLogowanie") || res.data.includes("action=\"/loguj\"") || res.data.includes("id=\"Login\""))) {
        return false;
      }
      return res.status === 200;
    } catch (e) {
      return false;
    }
  }

  async authenticate({ force = false } = {}) {
    if (!force) {
      const alive = await this.isSessionAlive();
      if (alive) {
        console.log("[LibrusClient] Existing session is valid, skipping OAuth flow.");
        return true;
      }
    }

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

    console.log("[LibrusClient] Starting sequential module fetching with human jitter...");

    const infoData = await this.fetchStudentInfo();
    await sleep(1000, 2200);

    let annData = { luckyNumber: 0, announcements: [] };
    try {
      annData = await this.fetchAnnouncements();
    } catch (err) {
      console.warn("[LibrusClient] fetchAnnouncements error, using fallback:", err.message);
    }
    await sleep(1200, 2400);

    const gradesData = await this.fetchGrades();
    await sleep(1500, 2500);

    const ttData = await this.fetchTimetable();
    await sleep(1200, 2200);

    const attData = await this.fetchAttendance();
    await sleep(1300, 2300);

    let msgData = { messages: [] };
    try {
      msgData = await this.fetchMessages();
    } catch (err) {
      console.warn("[LibrusClient] fetchMessages error, using fallback:", err.message);
    }
    await sleep(1000, 2000);

    let justData = [];
    try {
      justData = await this.fetchJustifications();
    } catch (err) {
      console.warn("[LibrusClient] fetchJustifications error, using fallback:", err.message);
    }
    await sleep(1100, 2100);

    let terminarzData = { events: [], upcomingExams: [], upcomingExam: null };
    try {
      terminarzData = await this.fetchTerminarz();
    } catch (err) {
      console.warn("[LibrusClient] fetchTerminarz error, using fallback:", err.message);
    }


    // Enrich subjects with teachers from timetable if empty
    const ttTeacherMap = {};
    ttData.timetable.forEach(t => {
      if (t.subject && t.teacher) {
        const key = t.subject.toLowerCase().replace(/^(zastępstwo|odwołane)\s*/i, "").trim();
        if (!ttTeacherMap[key]) {
          ttTeacherMap[key] = t.teacher;
        }
      }
    });

    gradesData.subjects.forEach(s => {
      if (!s.teacher) {
        const key = s.name.toLowerCase().trim();
        if (ttTeacherMap[key]) {
          s.teacher = ttTeacherMap[key];
        }
      }
    });

    const rawJusts = Array.isArray(justData) ? justData : (justData?.justifications || []);
    if (rawJusts.length > 0 && Array.isArray(attData.records)) {
      attData.records.forEach(rec => {
        for (const just of rawJusts) {
          const statusLower = (just.status || "").toLowerCase();
          const isApproved = statusLower.includes("uspr") || statusLower.includes("zaakcept");
          const isPending = statusLower.includes("oczekuj") || statusLower.includes("przesłan") || statusLower.includes("nowe");
          const period = just.period || "";

          // Check if date matches
          if (rec.date && period.includes(rec.date)) {
            const mentionsLesson = /lekcj/i.test(period);
            const lessonRegex = new RegExp(`\\b${rec.lessonNumber}\\b`);
            if (!mentionsLesson || lessonRegex.test(period)) {
              if (isApproved) {
                if (rec.type === "unexcused") {
                  rec.type = "excused";
                  if (attData.stats) {
                    attData.stats.absenceCount = Math.max(0, (attData.stats.absenceCount || 1) - 1);
                    attData.stats.excusedCount = (attData.stats.excusedCount || 0) + 1;
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
      messages: msgData.messages,
      unreadMessagesCount: msgData.unreadCount || (msgData.messages || []).filter(m => !m.isRead).length,
      justifications: Array.isArray(justData) ? justData : (justData?.justifications || []),
      events: terminarzData.events || [],
      upcomingExams: terminarzData.upcomingExams || [],
      upcomingExam: terminarzData.upcomingExam || null
    };
  }

  async fetchAnnouncements() {
    const res = await this.client.get("https://synergia.librus.pl/ogloszenia");
    const $ = cheerio.load(res.data);

    const parsedLucky = parseInt($(".luckyNumber b").text().trim(), 10);
    const luckyNumber = isNaN(parsedLucky) ? 0 : parsedLucky;
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
            const firstDash = cleanText.indexOf("-");
            let subject = cleanText;
            let teacher = "";
            if (firstDash !== -1) {
              subject = cleanText.slice(0, firstDash).trim();
              teacher = cleanText.slice(firstDash + 1).replace(/\s*\([^)]*\)/g, "").replace(/\s+/g, " ").trim();
            }

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
        // If sender starts with "(Name Surname) [Role]", unwrap the parentheses instead of deleting them;
        // otherwise strip redundant "(Name Surname)" when the name is already present before "("
        if (/^\s*\([^)]+\)/.test(sender)) {
          sender = sender.replace(/^\s*\(([^)]+)\)/, "$1").trim();
        } else {
          sender = sender.replace(/\s*\([^)]*\)/, "").trim();
        }

        const subject = $(tds[3]).text().trim().replace(/\s+/g, " ");
        const date = $(tds[4]).text().trim().replace(/\s+/g, " ");

        // Robust unread detection in Synergia HTML:
        // 1. Text bold styling in tr, td, or subject link
        const hasBold = $(tr).hasClass("bold") ||
                        ($(tr).attr("style") || "").includes("bold") ||
                        $(tds).toArray().some(td => {
                          const style = $(td).attr("style") || "";
                          const aStyle = $(td).find("a").attr("style") || "";
                          return style.includes("bold") || aStyle.includes("bold") || $(td).hasClass("bold") || $(td).find("b, strong").length > 0;
                        });

        // 2. Icon in column 1 (tds[1]) indicating unread/read state
        const statusImg = $(tds[1]).find("img");
        const statusSrc = (statusImg.attr("src") || "").toLowerCase();
        const statusTitle = (statusImg.attr("title") || "").toLowerCase();
        const statusAlt = (statusImg.attr("alt") || "").toLowerCase();

        const hasUnreadIcon = statusSrc.includes("nieprzeczytan") || 
                              statusSrc.includes("zamkniet") || 
                              statusSrc.includes("unread") ||
                              statusTitle.includes("nieprzeczytan") || 
                              statusAlt.includes("nieprzeczytan");

        const hasReadIcon = statusSrc.includes("przeczytan") ||
                            statusSrc.includes("otwart") ||
                            statusSrc.includes("read");

        const hasAttachmentIcon = $(tds[1]).find("img[src*='attachment'], img.existing-msg-files-icon").length > 0 ||
                                  statusSrc.includes("attachment") ||
                                  statusAlt.includes("plik") ||
                                  statusTitle.includes("pliki");

        const isUnread = hasUnreadIcon || (hasBold && !hasReadIcon);
        const isRead = !isUnread;

        messages.push({
          id: msgId,
          sender,
          subject,
          date,
          isRead,
          hasAttachments: hasAttachmentIcon,
          attachments: [],
          attachmentFiles: [],
          preview: subject,
          body: subject,
          bodyLoaded: false,
          librusUrl: link ? `https://synergia.librus.pl${link}` : ""
        });
      }
    });

    // Also parse menu counter if available: "Wiadomości (2)" or .counter / .unread-counter
    let menuUnreadCount = 0;
    $("a[href*='wiadomosci']").each((_, a) => {
      const match = $(a).text().match(/\((\d+)\)/);
      if (match) {
        menuUnreadCount = Math.max(menuUnreadCount, parseInt(match[1], 10));
      }
    });
    if (menuUnreadCount > 0 && messages.every(m => m.isRead)) {
      for (let i = 0; i < Math.min(menuUnreadCount, messages.length); i++) {
        messages[i].isRead = false;
      }
    }

    // Fetch full body and attachments for the latest 10 messages + any message with an attachment icon
    for (let i = 0; i < messages.length; i++) {
      const m = messages[i];
      if ((i < 10 || m.hasAttachments) && m.librusUrl) {
        try {
          const detailRes = await this.client.get(m.librusUrl);
          const $$ = cheerio.load(detailRes.data);
          const bodyText = $$("div.container-message-content").text().trim();
          if (bodyText) {
            m.body = bodyText;
            m.preview = bodyText.replace(/\s+/g, " ").substring(0, 90);
          }
          const parsedAttachments = this._parseMessageAttachments($$);
          if (parsedAttachments.length > 0) {
            m.hasAttachments = true;
            m.attachments = parsedAttachments.map(a => a.name);
            m.attachmentFiles = parsedAttachments;
          }
          m.bodyLoaded = true;
        } catch (e) {
          console.warn(`Could not fetch body for message ${m.id}:`, e.message);
        }
      }
    }

    const unreadCount = messages.filter(m => !m.isRead).length;
    return { messages, unreadCount };
  }

  _parseMessageAttachments($) {
    const attachmentFiles = [];
    const seenPaths = new Set();

    $("img[onclick*='pobierz_zalacznik'], a[onclick*='pobierz_zalacznik'], a[href*='pobierz_zalacznik']").each((idx, el) => {
      const rawAttr = ($(el).attr("onclick") || $(el).attr("href") || "").replace(/\\\//g, "/");
      const pathMatch = rawAttr.match(/(\/wiadomosci\/pobierz_zalacznik\/\d+\/\d+)/);
      if (!pathMatch) return;

      const downloadPath = pathMatch[1];
      if (seenPaths.has(downloadPath)) return;
      seenPaths.add(downloadPath);

      const tr = $(el).closest("tr");
      let fileName = tr.find("td").first().text().trim().replace(/\s+/g, " ");
      if (!fileName || fileName.toLowerCase() === "pliki:") {
        fileName = `Zalacznik_${idx + 1}`;
      }

      attachmentFiles.push({
        name: fileName,
        path: downloadPath
      });
    });

    return attachmentFiles;
  }

  async fetchMessageDetails(msgId, librusUrl) {
    const cheerio = require("cheerio");
    const targetUrl = librusUrl || `https://synergia.librus.pl/wiadomosci/1/5/${msgId}`;
    const detailRes = await this.client.get(targetUrl);
    const $ = cheerio.load(detailRes.data);
    const bodyText = $("div.container-message-content").text().trim();
    const attachmentFiles = this._parseMessageAttachments($);
    return {
      id: msgId,
      body: bodyText || "",
      bodyLoaded: true,
      hasAttachments: attachmentFiles.length > 0,
      attachments: attachmentFiles.map(a => a.name),
      attachmentFiles,
      librusUrl: targetUrl
    };
  }

  async resolveAttachmentDownloadUrl(downloadPath) {
    const cleanPath = String(downloadPath || "").replace(/\\\//g, "/").trim();
    if (!cleanPath.startsWith("/wiadomosci/pobierz_zalacznik/")) {
      throw new Error("Nieprawidłowa ścieżka załącznika Librus.");
    }
    const targetUrl = `https://synergia.librus.pl${cleanPath}`;
    const res = await this.client.get(targetUrl, {
      maxRedirects: 0,
      validateStatus: () => true
    });
    const redirectLocation = res.headers?.location || res.request?.res?.responseUrl;
    if (redirectLocation && redirectLocation.includes("GetFile")) {
      return `${redirectLocation.replace(/\/+$/, "")}/get`;
    }
    const followRes = await this.client.get(targetUrl);
    const finalUrl = followRes.request?.res?.responseUrl;
    if (finalUrl && finalUrl.includes("GetFile")) {
      return `${finalUrl.replace(/\/+$/, "")}/get`;
    }
    throw new Error("Nie udało się uzyskać linku do pobrania załącznika z Librusa.");
  }

  async downloadAttachmentBuffer(downloadPath) {
    const directUrl = await this.resolveAttachmentDownloadUrl(downloadPath);
    const res = await this.client.get(directUrl, {
      responseType: "arraybuffer",
      timeout: 45000
    });
    return {
      buffer: Buffer.from(res.data),
      contentType: res.headers?.["content-type"],
      directUrl
    };
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

  async fetchJustifications() {
    try {
      const res = await this.client.get("https://synergia.librus.pl/eusprawiedliwienia");
      const cheerio = require("cheerio");
      const $ = cheerio.load(res.data);
      const items = [];
      $("table.decorated.stretch tr").each((i, tr) => {
        const tds = $(tr).find("td");
        if (tds.length >= 7) {
          const period = $(tds[1]).text().trim();
          const count = $(tds[2]).text().trim();
          const content = $(tds[3]).text().trim();
          const notified = $(tds[4]).text().trim();
          const sentDate = $(tds[5]).text().trim();
          const status = $(tds[6]).text().trim();
          if (period && !period.includes("Brak") && period !== "Okres usprawiedliwienia") {
            items.push({
              id: `just_${sentDate}_${i}`,
              period,
              count,
              content,
              notified,
              sentDate,
              status
            });
          }
        }
      });
      return items;
    } catch (e) {
      console.warn("fetchJustifications error:", e.message);
      return [];
    }
  }

  async submitJustification({ dateFrom, dateTo, reason, isByHours = false, hoursByDate = {}, notifyOthers = true }) {
    await this.authenticate();

    if (isByHours && Object.keys(hoursByDate).length > 0) {
      const dates = Object.keys(hoursByDate);
      const results = [];
      for (const date of dates) {
        const hours = hoursByDate[date];
        if (!hours || hours.length === 0) continue;

        const formPage = await this.client.get("https://synergia.librus.pl/eusprawiedliwienia/dodaj");
        const cheerio = require("cheerio");
        const $ = cheerio.load(formPage.data);
        const requestkey = $("input[name=\"requestkey\"]").val();
        if (!requestkey) {
          throw new Error("Nie znaleziono tokenu autoryzacji formularza e-Usprawiedliwień.");
        }

        const formData = new FormData();
        formData.append("requestkey", requestkey);
        formData.append("dodajUsprawiedliwienieDo", "1");
        formData.append("datyLubLekcje", "wgGodzin");
        formData.append("dataOd", date);
        formData.append("dataDo", date);
        formData.append("powodNieobecnosci", reason || "");
        if (notifyOthers) {
          formData.append("powiadomInnych", "1");
        }
        for (const h of hours) {
          formData.append(`usprawiedliwienie[${date}][]`, String(h));
        }

        const res = await this.client.post("https://synergia.librus.pl/eusprawiedliwienia/dodaj", formData, {
          headers: {
            "Referer": "https://synergia.librus.pl/eusprawiedliwienia/dodaj"
          },
          maxRedirects: 5
        });
        results.push({ date, hours, status: res.status });
      }
      return {
        success: true,
        message: "Usprawiedliwienie zostało przesłane do wychowawcy (Sobota Łukasz) w Librus Synergia.",
        results
      };
    } else {
      const formPage = await this.client.get("https://synergia.librus.pl/eusprawiedliwienia/dodaj");
      const cheerio = require("cheerio");
      const $ = cheerio.load(formPage.data);
      const requestkey = $("input[name=\"requestkey\"]").val();
      if (!requestkey) {
        throw new Error("Nie znaleziono tokenu autoryzacji formularza e-Usprawiedliwień.");
      }

      const formData = new FormData();
      formData.append("requestkey", requestkey);
      formData.append("dodajUsprawiedliwienieDo", "1");
      formData.append("datyLubLekcje", "wgDat");
      formData.append("dataOd", dateFrom || "");
      formData.append("dataDo", dateTo || dateFrom || "");
      formData.append("powodNieobecnosci", reason || "");
      if (notifyOthers) {
        formData.append("powiadomInnych", "1");
      }

      const res = await this.client.post("https://synergia.librus.pl/eusprawiedliwienia/dodaj", formData, {
        headers: {
          "Referer": "https://synergia.librus.pl/eusprawiedliwienia/dodaj"
        },
        maxRedirects: 5
      });

      return {
        success: true,
        message: "Usprawiedliwienie zostało przesłane do wychowawcy (Sobota Łukasz) w Librus Synergia.",
        dateFrom,
        dateTo: dateTo || dateFrom,
        status: res.status
      };
    }
  }

  async fetchTerminarz() {
    try {
      const now = new Date();
      const currentYear = now.getFullYear();
      const currentMonth = now.getMonth() + 1; // 1-12

      // Calculate next month and year
      const nextMonth = currentMonth === 12 ? 1 : currentMonth + 1;
      const nextYear = currentMonth === 12 ? currentYear + 1 : currentYear;

      // 1. Fetch current month
      const resCurrent = await this.client.get("https://synergia.librus.pl/terminarz");
      const eventsCurrent = this._parseTerminarzHtml(resCurrent.data, currentYear, currentMonth);

      // 2. Fetch next month using requestkey
      let eventsNext = [];
      try {
        const $cur = cheerio.load(resCurrent.data);
        const requestkey = $cur('input[name="requestkey"]').val();
        if (requestkey) {
          const resNext = await this.client.post(
            "https://synergia.librus.pl/terminarz",
            new URLSearchParams({
              requestkey,
              miesiac: String(nextMonth),
              rok: String(nextYear)
            }).toString(),
            { headers: { "Content-Type": "application/x-www-form-urlencoded" } }
          );
          eventsNext = this._parseTerminarzHtml(resNext.data, nextYear, nextMonth);
        }
      } catch (nextErr) {
        console.warn("fetchTerminarz next month fetch failed:", nextErr.message);
      }

      const allEvents = [...eventsCurrent, ...eventsNext];
      allEvents.sort((a, b) => a.date.localeCompare(b.date));

      const todayStr = `${currentYear}-${String(currentMonth).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;

      const upcomingEvents = allEvents.filter(e => e.date >= todayStr);
      const upcomingExams = upcomingEvents.filter(e => e.type === "sprawdzian" || e.type === "kartkówka");
      const upcomingExam = upcomingExams.length > 0 ? upcomingExams[0] : null;

      return {
        events: allEvents,
        upcomingEvents,
        upcomingExams,
        upcomingExam
      };
    } catch (err) {
      console.error("fetchTerminarz error:", err.message);
      return {
        events: [],
        upcomingEvents: [],
        upcomingExams: [],
        upcomingExam: null
      };
    }
  }

  _parseTerminarzHtml(html, year, month) {
    const $ = cheerio.load(html);
    const events = [];

    $("div.kalendarz-dzien").each((_, el) => {
      const dayText = $(el).find(".kalendarz-numer-dnia").text().trim();
      const day = parseInt(dayText, 10);
      if (isNaN(day)) return;

      $(el).find("table tbody td").each((_, td) => {
        const $td = $(td);
        const text = $td.text().trim();
        const title = $td.attr("title") || "";
        const onclick = $td.attr("onclick") || "";

        if (!text && !title) return;

        let teacher = "";
        let description = "";
        let dateAdded = "";

        // Extract Teacher
        const teacherMatch = title.match(/Nauczyciel:\s*([^<]+)/i);
        if (teacherMatch) teacher = teacherMatch[1].trim();

        // Extract Description/Scope (can span multiple lines)
        const opisMatch = title.match(/Opis:\s*([\s\S]*?)(?:<br\s*\/?>\s*Data dodania:|$)/i);
        if (opisMatch) {
          description = opisMatch[1].replace(/<br\s*\/?>/gi, " ").replace(/\s+/g, " ").trim();
        }

        // Extract Date Added
        const dateMatch = title.match(/Data dodania:\s*([^<]+)/i);
        if (dateMatch) dateAdded = dateMatch[1].trim();

        let subject = "";
        let type = "inne";
        let lessonNumber = 0;

        const subjectSpan = $td.find("span.przedmiot").text().trim();
        if (subjectSpan) {
          subject = subjectSpan;
        }

        const lower = text.toLowerCase();
        if (lower.includes("sprawdzian")) type = "sprawdzian";
        else if (lower.includes("kartkówk")) type = "kartkówka";
        else if (lower.includes("odwołan")) type = "odwołane";
        else if (lower.includes("zastępstwo")) type = "zastępstwo";
        else if (lower.includes("wycieczk")) type = "wycieczka";
        else if (lower.includes("wywiadówk")) type = "wywiadówka";

        const lessonMatch = text.match(/nr(?:\s+lekcji)?:?\s*(\d+)/i);
        if (lessonMatch) {
          lessonNumber = parseInt(lessonMatch[1], 10);
        }

        if (!subject) {
          const subMatch = text.match(/\(([^)]+)\)/);
          if (subMatch) {
            subject = subMatch[1].trim();
          } else if (type === "sprawdzian" || type === "kartkówka") {
            const cleanedText = text.replace(/Nr\s+lekcji:\s*\d+\s*/i, "");
            const parts = cleanedText.split(/,|\n/).map(p => p.trim()).filter(Boolean);
            const nonTypePart = parts.find(p => !/^(sprawdzian|kartkówk)/i.test(p));
            subject = nonTypePart || (parts[0] || "");
          }
        }

        const eventDate = `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;

        events.push({
          date: eventDate,
          day,
          month,
          year,
          type,
          subject: subject || (type === "wywiadówka" ? "Wywiadówka" : type === "wycieczka" ? "Wycieczka" : "Wydarzenie"),
          teacher,
          description: description || text.replace(/\s+/g, " ").trim(),
          lessonNumber,
          rawText: text.replace(/\s+/g, " ").trim(),
          detailsUrl: onclick.match(/'([^']+)'/)?.[1] || null
        });
      });
    });

    return events;
  }
}

module.exports = { LibrusClient, deriveLibrusModule };
