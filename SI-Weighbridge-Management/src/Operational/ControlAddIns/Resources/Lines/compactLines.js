
(function () {
    "use strict";

    let rows = [];

    function root() {
        return document.getElementById("controlAddIn") || document.body;
    }

    function invoke(name, args) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
            name,
            args || [],
            false);
    }

    function esc(value) {
        return String(value === null || value === undefined ? "" : value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;");
    }

    function numberText(value) {
        if (value === null || value === undefined || value === "")
            return "";
        return String(value).replace(".", ",");
    }

    function render() {
        const host = root();

        let body = "";
        if (!rows.length) {
            body = '<div class="siwb-empty">Немає рядків</div>';
        } else {
            body = `
                <div class="siwb-grid-scroll">
                    <table class="siwb-grid">
                        <colgroup>
                            <col style="width:25%">
                            <col style="width:15%">
                            <col style="width:17%">
                            <col style="width:10%">
                            <col style="width:13%">
                            <col style="width:11%">
                            <col style="width:9%">
                        </colgroup>
                        <thead>
                            <tr>
                                <th>Товар</th>
                                <th>Варіант</th>
                                <th>Розподілена вага, кг</th>
                                <th>Од. вим. ваги</th>
                                <th>Кількість</th>
                                <th>Од. вим. товару</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            ${rows.map(renderRow).join("")}
                        </tbody>
                    </table>
                </div>`;
        }

        host.innerHTML = `
            <div class="siwb-wrap">
                <div class="siwb-toolbar">
                    <button class="siwb-btn" id="siwb-add-line">＋ Додати рядок</button>
                    <button class="siwb-btn" id="siwb-recalc-first">⟳ Перерахувати</button>
                </div>
                ${body}
            </div>`;

        const add = document.getElementById("siwb-add-line");
        if (add)
            add.onclick = () => invoke("AddLineRequested", []);

        const recalc = document.getElementById("siwb-recalc-first");
        if (recalc)
            recalc.onclick = () => {
                if (rows.length)
                    invoke("RecalculateRequested", [rows[0].lineNo]);
            };

        bindRows();
    }

    function renderRow(r) {
        const itemText = r.itemDisplay || r.itemNo || "";
        const variantText = r.variantDisplay || r.variantCode || "";

        return `
            <tr data-line="${r.lineNo}">
                <td>
                    <div class="siwb-lookup-cell">
                        <span class="siwb-lookup-text" title="${esc(itemText)}">${esc(itemText)}</span>
                        <button class="siwb-ellipsis" data-act="item" data-line="${r.lineNo}">⋮</button>
                    </div>
                </td>
                <td>
                    <div class="siwb-lookup-cell">
                        <span class="siwb-lookup-text" title="${esc(variantText)}">${esc(variantText)}</span>
                        <button class="siwb-ellipsis" data-act="variant" data-line="${r.lineNo}">⋮</button>
                    </div>
                </td>
                <td>
                    <input class="siwb-input"
                           data-act="weight"
                           data-line="${r.lineNo}"
                           value="${esc(numberText(r.allocatedWeight))}">
                </td>
                <td>${esc(r.weightUom || "")}</td>
                <td>${esc(numberText(r.quantity))}</td>
                <td>${esc(r.itemUom || "")}</td>
                <td class="siwb-actions-cell">
                    <button class="siwb-icon-btn" title="Перерахувати"
                            data-act="recalc" data-line="${r.lineNo}">⟳</button>
                    <button class="siwb-icon-btn" title="Видалити"
                            data-act="delete" data-line="${r.lineNo}">🗑</button>
                </td>
            </tr>`;
    }

    function bindRows() {
        document.querySelectorAll("[data-act='item']").forEach(el => {
            el.onclick = () => invoke(
                "ItemLookupRequested",
                [parseInt(el.dataset.line, 10)]);
        });

        document.querySelectorAll("[data-act='variant']").forEach(el => {
            el.onclick = () => invoke(
                "VariantLookupRequested",
                [parseInt(el.dataset.line, 10)]);
        });

        document.querySelectorAll("[data-act='recalc']").forEach(el => {
            el.onclick = () => invoke(
                "RecalculateRequested",
                [parseInt(el.dataset.line, 10)]);
        });

        document.querySelectorAll("[data-act='delete']").forEach(el => {
            el.onclick = () => invoke(
                "DeleteLineRequested",
                [parseInt(el.dataset.line, 10)]);
        });

        document.querySelectorAll("[data-act='weight']").forEach(el => {
            el.onchange = () => {
                const normalized = String(el.value || "")
                    .replace(/\s/g, "")
                    .replace(",", ".");
                const n = Number(normalized);

                if (!Number.isFinite(n)) {
                    render();
                    return;
                }

                invoke(
                    "AllocatedWeightChanged",
                    [parseInt(el.dataset.line, 10), n]);
            };
        });
    }

    window.SetData = function (dataJson) {
        try {
            rows = JSON.parse(dataJson || "[]");
            if (!Array.isArray(rows))
                rows = [];
        } catch (e) {
            rows = [];
        }

        render();
    };

    window.SIWBCompactLinesInitialize = function () {
        render();
    };
})();
