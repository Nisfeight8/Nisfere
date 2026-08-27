import QtQuick

// Simple sparkline (line + filled area) chart. Feed it a rolling array
// of normalized values (0.0–1.0) and it draws the rest.
// Usage:
//   Sparkline {
//       width: 120; height: 32
//       values: SystemStatsService.cpuHistory
//       lineColor: Theme.selected
//   }
Canvas {
    id: canvas

    property var values: []          // array of 0.0–1.0
    property color lineColor: Theme.selected
    property color fillColor: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.15)
    property real lineWidth: 2

    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onLineColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        if (values.length < 2)
            return;

        const step = width / (values.length - 1);

        // Auto-scale to the range actually present in this window,
        // instead of assuming the full 0.0–1.0 range is used. Without
        // this, real fluctuations that stay within a narrow band (e.g.
        // CPU bouncing between 15–25%) collapse visually into what
        // looks like a flat line, even though there's genuine movement
        // worth showing — matches how other system-monitor sparklines
        // typically render.
        let min = values[0];
        let max = values[0];
        for (let i = 1; i < values.length; i++) {
            if (values[i] < min)
                min = values[i];
            if (values[i] > max)
                max = values[i];
        }
        // Guard against a perfectly flat window (min === max) — would
        // otherwise divide by zero. Draws a flat mid-line instead.
        const range = (max - min) > 0.0001 ? (max - min) : 1;

        function yFor(v) {
            return height - ((v - min) / range) * height;
        }

        // Line
        ctx.beginPath();
        for (let i = 0; i < values.length; i++) {
            const x = i * step;
            const y = yFor(values[i]);
            if (i === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = lineWidth;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.stroke();

        // Filled area under the line, same path continued down to the
        // bottom corners — gives the "area chart" look for free.
        ctx.lineTo(width, height);
        ctx.lineTo(0, height);
        ctx.closePath();
        ctx.fillStyle = fillColor;
        ctx.fill();
    }
}
