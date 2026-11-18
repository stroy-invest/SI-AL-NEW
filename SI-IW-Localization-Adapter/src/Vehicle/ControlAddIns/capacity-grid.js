(function () {
    "use strict";
    window.SetData = function (dataJson) {
        const root = document.getElementById("si-iw-capacity-root");
        if (!root) return;
        let rows;
        try {
            const value = JSON.parse(dataJson);
            rows = Array.isArray(value) ? value : [];
        } catch (error) {
            root.textContent = "Помилка читання характеристик.";
            return;
        }
        root.replaceChildren();
        if (!rows.length) {
            const empty = document.createElement("div");
            empty.className = "si-iw-capacity-empty";
            empty.textContent = "Характеристики не визначені";
            root.appendChild(empty);
            return;
        }
        const table = document.createElement("table");
        table.className = "si-iw-capacity-table";
        const head = document.createElement("thead");
        const heading = document.createElement("tr");
        ["Характеристика", "Номінальне значення", "Реальне значення", "Одиниця вимірювання"].forEach(label => {
            const th = document.createElement("th");
            th.textContent = label;
            heading.appendChild(th);
        });
        head.appendChild(heading);
        table.appendChild(head);
        const body = document.createElement("tbody");
        function fmt(value) {
            const n = Number(value);
            return Number.isFinite(n) ? n.toLocaleString("uk-UA", {maximumFractionDigits: 5}) : "";
        }
        rows.forEach(item => {
            const tr = document.createElement("tr");
            [item.description || "", fmt(item.nominal), fmt(item.actual), item.uom || ""].forEach((value, index) => {
                const td = document.createElement("td");
                td.textContent = value;
                if (index === 1 || index === 2) td.className = "si-iw-capacity-number";
                tr.appendChild(td);
            });
            body.appendChild(tr);
        });
        table.appendChild(body);
        root.appendChild(table);
    };
})();
