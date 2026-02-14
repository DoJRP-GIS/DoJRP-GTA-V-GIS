/**
 * Run this function from the Apps Script editor.
 * It creates a new sheet called "_METADATA" with all named ranges,
 * named functions, and key formulas from Matrix 1.
 *
 * To run: Extensions > Apps Script > paste this > Run > extractAllMetadata
 */
function extractAllMetadata() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  // Create or clear the output sheet
  let outputSheet = ss.getSheetByName("_METADATA");
  if (outputSheet) {
    outputSheet.clear();
  } else {
    outputSheet = ss.insertSheet("_METADATA");
  }

  const output = [];

  // ===== SECTION 1: Named Ranges =====
  output.push(["--- NAMED RANGES ---"]);
  output.push(["Name", "Range (A1 notation)", "Sheet"]);
  const namedRanges = ss.getNamedRanges();
  if (namedRanges.length === 0) {
    output.push(["(none found)"]);
  }
  for (const nr of namedRanges) {
    const range = nr.getRange();
    output.push([
      nr.getName(),
      "'" + range.getSheet().getName() + "'!" + range.getA1Notation(),
      range.getSheet().getName()
    ]);
  }
  output.push([""]);

  // ===== SECTION 2: Sheet Names =====
  output.push(["--- ALL SHEETS ---"]);
  output.push(["Sheet Name", "Sheet ID (gid)", "Rows", "Columns"]);
  for (const sheet of ss.getSheets()) {
    output.push([
      sheet.getName(),
      sheet.getSheetId(),
      sheet.getMaxRows(),
      sheet.getMaxColumns()
    ]);
  }
  output.push([""]);

  // ===== SECTION 3: Matrix 1 Formulas =====
  output.push(["--- MATRIX 1 FORMULAS ---"]);
  output.push(["Cell", "Formula", "Displayed Value"]);
  const matrix1 = ss.getSheetByName("Matrix 1");
  if (matrix1) {
    const dataRange = matrix1.getDataRange();
    const formulas = dataRange.getFormulas();
    const values = dataRange.getDisplayValues();
    for (let r = 0; r < formulas.length; r++) {
      for (let c = 0; c < formulas[r].length; c++) {
        if (formulas[r][c] && formulas[r][c] !== "") {
          const cellRef = matrix1.getRange(r + 1, c + 1).getA1Notation();
          output.push([cellRef, formulas[r][c], values[r][c]]);
        }
      }
    }
  }
  output.push([""]);

  // ===== SECTION 4: Assignment Sheet Formulas =====
  output.push(["--- ASSIGNMENT SHEET FORMULAS ---"]);
  output.push(["Cell", "Formula", "Displayed Value"]);
  const assignment = ss.getSheetByName("Assignment");
  if (assignment) {
    const dataRange = assignment.getDataRange();
    const formulas = dataRange.getFormulas();
    const values = dataRange.getDisplayValues();
    for (let r = 0; r < formulas.length; r++) {
      for (let c = 0; c < formulas[r].length; c++) {
        if (formulas[r][c] && formulas[r][c] !== "") {
          const cellRef = assignment.getRange(r + 1, c + 1).getA1Notation();
          output.push([cellRef, formulas[r][c], values[r][c]]);
        }
      }
    }
  }
  output.push([""]);

  // ===== SECTION 5: RunningOrderFull Formulas (first 5 data rows) =====
  output.push(["--- RUNNINGORDERFULL FORMULAS (first 5 rows) ---"]);
  output.push(["Cell", "Formula"]);
  const rof = ss.getSheetByName("RunningOrderFull");
  if (rof) {
    const sampleRange = rof.getRange(1, 1, Math.min(8, rof.getMaxRows()), rof.getMaxColumns());
    const formulas = sampleRange.getFormulas();
    for (let r = 0; r < formulas.length; r++) {
      for (let c = 0; c < formulas[r].length; c++) {
        if (formulas[r][c] && formulas[r][c] !== "") {
          const cellRef = rof.getRange(r + 1, c + 1).getA1Notation();
          output.push([cellRef, formulas[r][c]]);
        }
      }
    }
  }
  output.push([""]);

  // ===== SECTION 6: Current Station Apparatus Formulas =====
  output.push(["--- CURRENT STATION APPARATUS FORMULAS (first 5 rows) ---"]);
  output.push(["Cell", "Formula"]);
  const csa = ss.getSheetByName("Current Station Apparatus");
  if (csa) {
    const sampleRange = csa.getRange(1, 1, Math.min(6, csa.getMaxRows()), csa.getMaxColumns());
    const formulas = sampleRange.getFormulas();
    for (let r = 0; r < formulas.length; r++) {
      for (let c = 0; c < formulas[r].length; c++) {
        if (formulas[r][c] && formulas[r][c] !== "") {
          const cellRef = csa.getRange(r + 1, c + 1).getA1Notation();
          output.push([cellRef, formulas[r][c]]);
        }
      }
    }
  }
  output.push([""]);

  // ===== SECTION 7: Override Core Apparatus Formulas =====
  output.push(["--- OVERRIDE CORE APPARATUS FORMULAS ---"]);
  output.push(["Cell", "Formula"]);
  const oca = ss.getSheetByName("Override Core Apparatus");
  if (oca) {
    const dataRange = oca.getDataRange();
    const formulas = dataRange.getFormulas();
    for (let r = 0; r < formulas.length; r++) {
      for (let c = 0; c < formulas[r].length; c++) {
        if (formulas[r][c] && formulas[r][c] !== "") {
          const cellRef = oca.getRange(r + 1, c + 1).getA1Notation();
          output.push([cellRef, formulas[r][c]]);
        }
      }
    }
  }
  output.push([""]);

  // ===== SECTION 8: Named Functions (custom LAMBDA) =====
  output.push(["--- NAMED FUNCTIONS ---"]);
  output.push(["NOTE: Google Sheets API cannot directly enumerate named functions."]);
  output.push(["To export them: Data > Named functions > click each one > copy definition"]);
  output.push(["Alternatively, check if any cells use named function calls:"]);

  // Search Matrix 1 formulas for function-like patterns that aren't built-in
  const builtins = new Set([
    "IF", "IFS", "IFERROR", "VLOOKUP", "HLOOKUP", "XLOOKUP", "INDEX", "MATCH",
    "SPLIT", "TEXTJOIN", "JOIN", "CONCATENATE", "CONCAT", "LEFT", "RIGHT", "MID",
    "LEN", "FIND", "SEARCH", "SUBSTITUTE", "REPLACE", "TRIM", "UPPER", "LOWER",
    "VALUE", "TEXT", "TO_TEXT", "ARRAYFORMULA", "FILTER", "SORT", "UNIQUE",
    "INDIRECT", "ROW", "COLUMN", "ROWS", "COLUMNS", "OFFSET", "ADDRESS",
    "SUM", "SUMIF", "SUMIFS", "SUMPRODUCT", "COUNT", "COUNTA", "COUNTIF",
    "COUNTIFS", "AVERAGE", "MIN", "MAX", "AND", "OR", "NOT", "TRUE", "FALSE",
    "ISBLANK", "ISERROR", "ISNA", "ISNUMBER", "ISTEXT", "REGEXMATCH",
    "REGEXEXTRACT", "REGEXREPLACE", "QUERY", "IMPORTRANGE", "HYPERLINK",
    "IMAGE", "SPARKLINE", "LAMBDA", "MAP", "REDUCE", "BYROW", "BYCOL",
    "MAKEARRAY", "SCAN", "LET", "SWITCH", "CHOOSE", "ABS", "MOD", "INT",
    "ROUND", "CEILING", "FLOOR", "CHAR", "CODE", "TRANSPOSE", "FLATTEN",
    "TOCOL", "TOROW", "WRAPROWS", "WRAPCOLS", "HSTACK", "VSTACK",
    "SEQUENCE", "LARGE", "SMALL", "RANK", "NOW", "TODAY", "ISEVEN", "ISODD",
    "EXACT", "TYPE", "N", "T", "NUMBERVALUE", "PROPER", "REPT", "EQ"
  ]);

  // Search ALL sheets for custom function calls, not just Matrix 1
  const sheetsToScan = [matrix1, assignment, rof, csa, oca];
  const sheetNames = ["Matrix 1", "Assignment", "RunningOrderFull", "Current Station Apparatus", "Override Core Apparatus"];
  const customFns = new Map(); // fn name -> set of sheets it appears in

  for (let s = 0; s < sheetsToScan.length; s++) {
    const sheet = sheetsToScan[s];
    if (!sheet) continue;
    const allFormulas = sheet.getDataRange().getFormulas();
    const fnPattern = /([A-Z_][A-Z_0-9]*)\s*\(/gi;
    for (const row of allFormulas) {
      for (const f of row) {
        if (!f) continue;
        let match;
        while ((match = fnPattern.exec(f)) !== null) {
          const fnName = match[1].toUpperCase();
          if (!builtins.has(fnName)) {
            if (!customFns.has(match[1])) {
              customFns.set(match[1], new Set());
            }
            customFns.get(match[1]).add(sheetNames[s]);
          }
        }
      }
    }
  }

  if (customFns.size > 0) {
    output.push(["Possible custom/named functions found:"]);
    output.push(["Function Name", "Used In Sheets"]);
    for (const [fn, sheets] of customFns) {
      output.push([fn, Array.from(sheets).join("; ")]);
    }
  } else {
    output.push(["No custom function calls detected"]);
  }
  output.push([""]);

  // ===== SECTION 9: Data Validations on Matrix 1 =====
  output.push(["--- MATRIX 1 DATA VALIDATIONS ---"]);
  output.push(["Cell", "Criteria Type", "Values"]);
  if (matrix1) {
    const dataRange = matrix1.getDataRange();
    for (let r = 1; r <= dataRange.getNumRows(); r++) {
      for (let c = 1; c <= dataRange.getNumColumns(); c++) {
        const cell = matrix1.getRange(r, c);
        const validation = cell.getDataValidation();
        if (validation) {
          const criteria = validation.getCriteriaType();
          const criteriaValues = validation.getCriteriaValues();
          output.push([
            cell.getA1Notation(),
            criteria.toString(),
            JSON.stringify(criteriaValues)
          ]);
        }
      }
    }
  }
  output.push([""]);

  // Pad all rows to same width
  const maxCols = Math.max(...output.map(r => r.length));
  const paddedOutput = output.map(r => {
    const row = [...r];
    while (row.length < maxCols) row.push("");
    return row;
  });

  // Format entire range as PLAIN TEXT before writing values
  // This prevents Sheets from interpreting formula strings (starting with =)
  // as actual formulas, which was causing #ERROR! on CSV export
  const outRange = outputSheet.getRange(1, 1, paddedOutput.length, maxCols);
  outRange.setNumberFormat("@");
  outRange.setValues(paddedOutput);

  // Auto-resize columns
  for (let c = 1; c <= 3; c++) {
    outputSheet.autoResizeColumn(c);
  }

  SpreadsheetApp.getUi().alert(
    "Metadata extracted to _METADATA sheet!\n\n" +
    "IMPORTANT: Also manually export your Named Functions:\n" +
    "Data > Named functions > click each one > copy the definition"
  );
}
