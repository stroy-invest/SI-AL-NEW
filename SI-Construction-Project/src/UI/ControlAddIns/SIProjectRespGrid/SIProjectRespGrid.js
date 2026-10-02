function SetAssignments(data) {
    var rows = [];
    try { rows = data ? JSON.parse(data) : []; } catch (e) { rows = []; }

    var root = document.getElementById('controlAddIn');
    if (!root) return;
    root.innerHTML = '';

    var toolbar = document.createElement('div');
    toolbar.className = 'si-pr-toolbar';
    var add = document.createElement('button');
    add.type = 'button';
    add.className = 'si-pr-add';
    add.textContent = '+ Додати';
    add.onclick = function () {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AddAssignment', []);
    };
    toolbar.appendChild(add);
    root.appendChild(toolbar);

    if (!rows.length) {
        var empty = document.createElement('div');
        empty.className = 'si-pr-empty';
        empty.textContent = 'Відповідальних ще не призначено.';
        root.appendChild(empty);
        return;
    }

    var table = document.createElement('table');
    table.className = 'si-pr-table';
    var thead = document.createElement('thead');
    thead.innerHTML = '<tr><th>Працівник</th><th>Чинний з</th><th>Чинний по</th><th class="si-pr-primary">Основний</th><th class="si-pr-actions"></th></tr>';
    table.appendChild(thead);
    var tbody = document.createElement('tbody');

    rows.forEach(function (r) {
        var tr = document.createElement('tr');
        tr.appendChild(lookupCell(r.employee || '—', function () {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('LookupEmployee', [r.lineNo]);
        }));
        tr.appendChild(dateCell(r.validFrom || '', function (value) {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('UpdateValidFrom', [r.lineNo, value]);
        }));
        tr.appendChild(dateCell(r.validTo || '', function (value) {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('UpdateValidTo', [r.lineNo, value]);
        }));

        var primaryTd = document.createElement('td');
        primaryTd.className = 'si-pr-primary';
        var check = document.createElement('input');
        check.type = 'checkbox';
        check.checked = !!r.primary;
        check.onchange = function () {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('UpdatePrimary', [r.lineNo, check.checked]);
        };
        primaryTd.appendChild(check);
        tr.appendChild(primaryTd);

        var actionTd = document.createElement('td');
        actionTd.className = 'si-pr-actions';
        var del = document.createElement('button');
        del.type = 'button';
        del.className = 'si-pr-delete';
        del.title = 'Видалити';
        del.textContent = '×';
        del.onclick = function () {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('DeleteAssignment', [r.lineNo]);
        };
        actionTd.appendChild(del);
        tr.appendChild(actionTd);
        tbody.appendChild(tr);
    });

    table.appendChild(tbody);

    var viewport = document.createElement('div');
    viewport.className = 'si-pr-grid-viewport';
    viewport.appendChild(table);
    root.appendChild(viewport);
}

function lookupCell(text, handler) {
    var td = document.createElement('td');
    var button = document.createElement('button');
    button.type = 'button';
    button.className = 'si-pr-lookup';
    button.textContent = text;
    button.onclick = handler;
    td.appendChild(button);
    return td;
}

function dateCell(value, handler) {
    var td = document.createElement('td');
    var input = document.createElement('input');
    input.type = 'date';
    input.className = 'si-pr-date';
    input.value = value || '';
    input.onchange = function () { handler(input.value); };
    td.appendChild(input);
    return td;
}
