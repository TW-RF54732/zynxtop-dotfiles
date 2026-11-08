.pragma library

function monthCells(year, month) {
    const first = new Date(Date.UTC(year, month, 1));
    const offset = (first.getUTCDay() + 6) % 7;
    return Array.from({length: 42}, (_, index) => {
        const date = new Date(Date.UTC(year, month, 1 - offset + index));
        return {year: date.getUTCFullYear(), month: date.getUTCMonth(), day: date.getUTCDate()};
    });
}

function sameDay(cell, date) {
    // ClockService exposes UTC wall-clock fields in a local Date object.
    return cell.year === date.getFullYear() && cell.month === date.getMonth()
        && cell.day === date.getDate();
}

function pad2(value) { return String(value).padStart(2, "0"); }

function dateKey(year, month, day) {
    return year + "-" + pad2(month + 1) + "-" + pad2(day);
}

function cellKey(cell) { return dateKey(cell.year, cell.month, cell.day); }

function formatMinutes(minutes) {
    const clamped = Math.max(0, Math.min(24 * 60, minutes));
    return pad2(Math.floor(clamped / 60)) + ":" + pad2(clamped % 60);
}

function timeLabel(event) {
    if (event.allDay) return "全天";
    return formatMinutes(event.startMin) + " – " + formatMinutes(event.endMin);
}

// ---- date keys ("YYYY-MM-DD", calendar dates without a time zone) ----

function parseKey(key) {
    const parts = String(key).split("-").map(Number);
    return new Date(Date.UTC(parts[0], parts[1] - 1, parts[2]));
}

function keyOf(date) { return date.toISOString().slice(0, 10); }

function addDays(key, count) {
    const date = parseKey(key);
    date.setUTCDate(date.getUTCDate() + count);
    return keyOf(date);
}

// Monday of the week containing `key`.
function weekStart(key) { return addDays(key, -((parseKey(key).getUTCDay() + 6) % 7)); }

var WEEKDAYS = ["一", "二", "三", "四", "五", "六", "日"];

function weekday(key) { return WEEKDAYS[(parseKey(key).getUTCDay() + 6) % 7]; }

function dayOfMonth(key) { return parseKey(key).getUTCDate(); }

// "11/10 週二"
function shortDate(key) {
    const date = parseKey(key);
    return (date.getUTCMonth() + 1) + "/" + pad2(date.getUTCDate()) + " 週" + weekday(key);
}

// "11 月 9 日 – 15 日" or "11 月 30 日 – 12 月 6 日"
function weekTitle(start) {
    const first = parseKey(start);
    const last = parseKey(addDays(start, 6));
    const head = (first.getUTCMonth() + 1) + " 月 " + first.getUTCDate() + " 日";
    const tail = first.getUTCMonth() === last.getUTCMonth() ? last.getUTCDate() + " 日"
        : (last.getUTCMonth() + 1) + " 月 " + last.getUTCDate() + " 日";
    const year = first.getUTCFullYear() !== last.getUTCFullYear() ? first.getUTCFullYear() + " 年 " : "";
    return year + head + " – " + tail;
}

// ISO 8601 week number.
function isoWeek(key) {
    const date = parseKey(key);
    date.setUTCDate(date.getUTCDate() + 3 - (date.getUTCDay() + 6) % 7);
    const firstThursday = new Date(Date.UTC(date.getUTCFullYear(), 0, 4));
    return 1 + Math.round(((date - firstThursday) / 86400000 - 3 + (firstThursday.getUTCDay() + 6) % 7) / 7);
}

// "1 小時 30 分"
function durationLabel(minutes) {
    const hours = Math.floor(minutes / 60);
    const rest = minutes % 60;
    if (hours === 0) return rest + " 分";
    return hours + " 小時" + (rest ? " " + rest + " 分" : "");
}

// Accepts "9", "930", "0930", "9:30", "09:30"; returns minutes or -1.
function parseTime(text) {
    const match = /^(\d{1,2})(?::?(\d{2}))?$/.exec(String(text).trim());
    if (!match) return -1;
    let hours = Number(match[1]);
    let minutes = match[2] === undefined ? 0 : Number(match[2]);
    if (match[2] === undefined && match[1].length > 2) return -1;
    if (minutes >= 60 || hours * 60 + minutes > 24 * 60) return -1;
    return hours * 60 + minutes;
}

// ---- repeat rules ----

var REPEATS = ["", "DAILY", "WEEKLY", "MONTHLY", "YEARLY"];

function repeatLabel(repeat, key) {
    const date = parseKey(key);
    switch (repeat) {
    case "DAILY": return "每天";
    case "WEEKLY": return "每週" + weekday(key);
    case "MONTHLY": return "每月 " + date.getUTCDate() + " 號";
    case "YEARLY": return "每年 " + (date.getUTCMonth() + 1) + "/" + date.getUTCDate();
    default: return "不重複";
    }
}

function stepRepeat(repeat, direction) {
    const index = Math.max(0, REPEATS.indexOf(repeat));
    return REPEATS[(index + direction + REPEATS.length) % REPEATS.length];
}

// ---- calendar sources ----

// Stable tint per calendar id: "local" takes the first color, others hash into the rest.
function sourceColor(id, palette) {
    if (!palette || palette.length === 0) return "#ABB2BF";
    if (id === "local" || palette.length === 1) return palette[0];
    let hash = 0;
    for (let index = 0; index < id.length; index++) hash = (hash * 31 + id.charCodeAt(index)) >>> 0;
    return palette[1 + hash % (palette.length - 1)];
}

function sortEvents(events) {
    return (events || []).slice().sort((a, b) => {
        if (a.allDay !== b.allDay) return a.allDay ? -1 : 1;
        if (a.startMin !== b.startMin) return a.startMin - b.startMin;
        if (a.endMin !== b.endMin) return b.endMin - a.endMin;
        return String(a.title).localeCompare(String(b.title));
    });
}

// Places timed events in side-by-side columns. Events overlapping (directly or through
// a chain) form one cluster; every event in a cluster shares the cluster's column count.
// `minDuration` gives zero-length events a visible height for overlap purposes.
function layoutDay(events, minDuration) {
    const minimum = minDuration === undefined ? 15 : minDuration;
    const timed = sortEvents(events).filter(event => !event.allDay).map(event => {
        const start = Math.max(0, Math.min(24 * 60, event.startMin));
        const end = Math.max(start + minimum, Math.min(24 * 60, event.endMin));
        return {event: event, start: start, end: Math.min(24 * 60, end), column: 0, columns: 1};
    });
    const result = [];
    let cluster = [];
    let columnEnds = [];
    let clusterEnd = -1;
    function flush() {
        for (const item of cluster) item.columns = columnEnds.length;
        cluster = [];
        columnEnds = [];
    }
    for (const item of timed) {
        if (item.start >= clusterEnd) flush();
        let column = columnEnds.findIndex(end => end <= item.start);
        if (column < 0) { column = columnEnds.length; columnEnds.push(item.end); }
        else columnEnds[column] = item.end;
        item.column = column;
        cluster.push(item);
        result.push(item);
        clusterEnd = Math.max(clusterEnd, item.end);
    }
    flush();
    return result;
}
