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
