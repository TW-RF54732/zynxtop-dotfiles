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
