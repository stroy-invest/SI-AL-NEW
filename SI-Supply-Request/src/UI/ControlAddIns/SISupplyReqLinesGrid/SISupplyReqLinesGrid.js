function SetLines(data, canEdit) {
    var rows = [];
    try {
        rows = data ? JSON.parse(data) : [];
    } catch (e) {
        rows = [];
    }

    var root = document.getElementById('controlAddIn');
    if (!root) return;
    root.innerHTML = '';

    var toolbar = document.createElement('div');
    toolbar.className = 'si-sr-toolbar';

    // Command-driven model: New Line is always available.
    // AL validates Project / Required At / Request Sites when clicked.
    var add = btn('+ Створити рядок потреби', function () {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AddLine', []);
    });
    toolbar.appendChild(add);
    root.appendChild(toolbar);

    var wrap = document.createElement('div');
    wrap.className = 'si-sr-wrap';

    var table = document.createElement('table');
    table.className = 'si-sr-table';
    table.innerHTML = '<thead><tr>' +
        '<th>Буд. майданчик</th>' +
        '<th>Тип рядка</th>' +
        '<th>Товар</th>' +
        '<th>Варіант</th>' +
        '<th>Опис потреби</th>' +
        '<th>Заявлена кількість</th>' +
        '<th>Погоджена кількість</th>' +
        '<th>Од. вим.</th>' +
        '<th>Потрібно на об\'єкті</th>' +
        '<th>Коментар</th>' +
        '<th></th>' +
        '</tr></thead>';

    var body = document.createElement('tbody');

    rows.forEach(function (r) {
        var tr = document.createElement('tr');

        [
            r.siteName,
            r.lineType,
            r.itemNo,
            r.variantCode,
            r.description,
            r.requestedQty,
            r.approvedQty,
            r.uom,
            r.requiredAt,
            r.comment
        ].forEach(function (v) {
            var td = document.createElement('td');
            td.textContent = v == null ? '' : v;
            tr.appendChild(td);
        });

        var actions = document.createElement('td');
        actions.className = 'si-sr-actions';

        var edit = btn('Редагувати', function () {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('EditLine', [r.lineNo]);
        });
        actions.appendChild(edit);

        var del = btn('×', function () {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('DeleteLine', [r.lineNo]);
        });
        actions.appendChild(del);

        tr.appendChild(actions);
        tr.ondblclick = function () {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('EditLine', [r.lineNo]);
        };

        body.appendChild(tr);
    });

    table.appendChild(body);
    wrap.appendChild(table);
    root.appendChild(wrap);

    if (!rows.length) {
        var empty = document.createElement('div');
        empty.className = 'si-sr-empty';
        empty.textContent = 'Позицій потреби ще немає.';
        root.appendChild(empty);
    }
}

function btn(txt, fn) {
    var b = document.createElement('button');
    b.type = 'button';
    b.textContent = txt;
    b.onclick = fn;
    return b;
}
