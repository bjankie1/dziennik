const test = require("node:test");
const assert = require("node:assert/strict");
const { parseMenGradeValue, normalizeStudentGradesData } = require("../src/librus_client");

test("parseMenGradeValue parses only MEN 1..6 grades and rejects 0, +, -, np, bz, nb", () => {
  assert.equal(parseMenGradeValue("5"), 5);
  assert.equal(parseMenGradeValue("4-"), 3.75);
  assert.equal(parseMenGradeValue("3+"), 3.5);
  assert.equal(parseMenGradeValue("1"), 1);
  assert.equal(parseMenGradeValue("6"), 6);
  assert.equal(parseMenGradeValue("0"), null);
  assert.equal(parseMenGradeValue("+"), null);
  assert.equal(parseMenGradeValue("-"), null);
  assert.equal(parseMenGradeValue("np"), null);
  assert.equal(parseMenGradeValue("bz"), null);
  assert.equal(parseMenGradeValue("nb"), null);
});

test("normalizeStudentGradesData heals Oskar's Firestore snapshot (11010033) and computes exact weighted averages", () => {
  const pollutedSnapshot = {
    overallAverage: 2.16,
    subjects: [
      { id: "biologia", name: "Biologia", currentAverage: 0, grades: [] },
      {
        id: "chemia",
        name: "Chemia",
        currentAverage: 3.75,
        grades: [
          {
            value: "5",
            numericalValue: 5,
            weight: 3,
            rawTooltip: "Kategoria: odpowiedź ustna (kolory w chemii nieorganicznej) Data: 2026-09-15 (wt.) Nauczyciel: Pietrzak Michał Licz do średniej: tak Waga: 3 Dodał: Pietrzak Michał"
          },
          {
            value: "0",
            numericalValue: 0,
            weight: 1,
            rawTooltip: "Kategoria: kartkówka z zadań maturalnych (systematyka zw. nieor.,charakt. pierw.) Data: 2026-10-08 (czw.) Nauczyciel: Pietrzak Michał Dodał: Pietrzak Michał"
          }
        ]
      },
      { id: "doradztwo_zawodowe", name: "Doradztwo zawodowe", currentAverage: 0, grades: [] },
      { id: "etyka", name: "Etyka", currentAverage: 0, grades: [] },
      {
        id: "historia",
        name: "Historia",
        currentAverage: 5,
        grades: [
          {
            value: "+",
            numericalValue: 5,
            weight: 1,
            rawTooltip: "Kategoria: zadanie Data: 2026-10-05 (pon.) Nauczyciel: Ćwikliński Piotr Dodał: Ćwikliński Piotr"
          }
        ]
      },
      {
        id: "j_zyk_angielski",
        name: "Język angielski",
        currentAverage: 3.36,
        grades: [
          {
            value: "4",
            numericalValue: 4,
            weight: 1,
            rawTooltip: "Kategoria: aktywność Data: 2026-09-29 (wt.) Nauczyciel: Tychańska Magdalena Licz do średniej: tak Waga: 1 Dodał: Tychańska Magdalena  Komentarz: artykuł"
          },
          {
            value: "3",
            numericalValue: 3,
            weight: 5,
            rawTooltip: "Kategoria: sprawdzian Data: 2026-09-30 (śr.) Nauczyciel: Tychańska Magdalena Licz do średniej: tak Waga: 5 Dodał: Tychańska Magdalena  Komentarz: unit 5"
          },
          {
            value: "4-",
            numericalValue: 3.75,
            weight: 3,
            rawTooltip: "Kategoria: odpowiedź ustna Data: 2026-10-09 (pt.) Nauczyciel: Tychańska Magdalena Licz do średniej: tak Waga: 3 Dodał: Tychańska Magdalena  Komentarz: zad 3"
          }
        ]
      },
      {
        id: "j_zyk_niemiecki",
        name: "Język niemiecki",
        currentAverage: 0,
        grades: [
          {
            value: "0",
            numericalValue: 0,
            weight: 1,
            rawTooltip: "Kategoria: zadanie Data: 2026-09-30 (śr.) Nauczyciel: Błaszkiewicz Marta Dodał: Błaszkiewicz Marta  Komentarz: karta pracy"
          }
        ]
      },
      {
        id: "j_zyk_polski",
        name: "Język polski",
        currentAverage: 1.13,
        grades: [
          {
            value: "5",
            numericalValue: 5,
            weight: 1,
            rawTooltip: "Kategoria: aktywność Data: 2026-09-10 (czw.) Nauczyciel: Melska Grażyna Licz do średniej: tak Waga: 1 Dodał: Melska Grażyna"
          },
          {
            value: "0",
            numericalValue: 0,
            weight: 1,
            rawTooltip: "Kategoria: Zagadnienia jawne Data: 2026-09-30 (śr.) Nauczyciel: Melska Grażyna Dodał: Melska Grażyna"
          },
          {
            value: "1",
            numericalValue: 1,
            weight: 4,
            rawTooltip: "Kategoria: Zagadnienia jawne Data: 2026-10-02 (pt.) Nauczyciel: Melska Grażyna Licz do średniej: tak Waga: 4 Dodał: Melska Grażyna"
          },
          {
            value: "0",
            numericalValue: 0,
            weight: 1,
            rawTooltip: "Kategoria: kartkówka Data: 2026-10-09 (pt.) Nauczyciel: Melska Grażyna Dodał: Melska Grażyna  Komentarz: Dżuma - znajomość treści lektury"
          },
          {
            value: "0",
            numericalValue: 0,
            weight: 1,
            rawTooltip: "Kategoria: Zagadnienia jawne Data: 2026-10-16 (pt.) Nauczyciel: Melska Grażyna Dodał: Melska Grażyna"
          }
        ]
      },
      {
        id: "matematyka",
        name: "Matematyka",
        currentAverage: 1,
        grades: [
          {
            value: "1",
            numericalValue: 1,
            weight: 5,
            rawTooltip: "Kategoria: sprawdzian Data: 2026-09-24 (czw.) Nauczyciel: Duda-Radicchio Wioletta Licz do średniej: tak Waga: 5 Dodał: Duda-Radicchio Wioletta  Komentarz: Rachunek różniczkowy 10.09.2026"
          }
        ]
      },
      { id: "religia", name: "Religia", currentAverage: 0, grades: [] },
      {
        id: "wychowanie_fizyczne",
        name: "Wychowanie fizyczne",
        currentAverage: 3.83,
        grades: [
          {
            value: "3+",
            numericalValue: 3.5,
            weight: 3,
            rawTooltip: "Kategoria: sprawdzian Data: 2026-10-04 (nd.) Nauczyciel: Herezo Maciej Licz do średniej: tak Waga: 3 Dodał: Herezo Maciej"
          },
          {
            value: "4",
            numericalValue: 4,
            weight: 6,
            rawTooltip: "Kategoria: Systematyczność w usprawnianiu. Data: 2026-10-04 (nd.) Nauczyciel: Herezo Maciej Licz do średniej: tak Waga: 6 Dodał: Herezo Maciej"
          }
        ]
      },
      { id: "zaj_cia_z_wychowawc_", name: "Zajęcia z wychowawcą", currentAverage: 0, grades: [] }
    ]
  };

  const { data, changed } = normalizeStudentGradesData(pollutedSnapshot);
  assert.equal(changed, true);

  const byName = Object.fromEntries(data.subjects.map(s => [s.name, s]));

  assert.equal(byName["Biologia"].currentAverage, 0);
  assert.equal(byName["Doradztwo zawodowe"].currentAverage, 0);
  assert.equal(byName["Etyka"].currentAverage, 0);
  assert.equal(byName["Religia"].currentAverage, 0);
  assert.equal(byName["Zajęcia z wychowawcą"].currentAverage, 0);

  assert.equal(byName["Chemia"].currentAverage, 5);
  assert.equal(byName["Chemia"].grades[0].isCountedToAverage, true);
  assert.equal(byName["Chemia"].grades[0].weight, 3);
  assert.equal(byName["Chemia"].grades[1].isCountedToAverage, false);
  assert.equal(byName["Chemia"].grades[1].weight, 0);
  assert.equal(byName["Chemia"].grades[1].numericalValue, 0);

  assert.equal(byName["Historia"].currentAverage, 0);
  assert.equal(byName["Historia"].grades[0].isCountedToAverage, false);
  assert.equal(byName["Historia"].grades[0].weight, 0);
  assert.equal(byName["Historia"].grades[0].numericalValue, 0);

  assert.equal(byName["Język angielski"].currentAverage, 3.36);
  assert.equal(byName["Język niemiecki"].currentAverage, 0);
  assert.equal(byName["Język niemiecki"].grades[0].isCountedToAverage, false);
  assert.equal(byName["Język niemiecki"].grades[0].weight, 0);

  assert.equal(byName["Język polski"].currentAverage, 1.8);
  assert.equal(byName["Matematyka"].currentAverage, 1);
  assert.equal(byName["Wychowanie fizyczne"].currentAverage, 3.83);
  assert.equal(data.overallAverage, 3.02);

  // Idempotency check
  const secondPass = normalizeStudentGradesData(data);
  assert.equal(secondPass.changed, false);
});
