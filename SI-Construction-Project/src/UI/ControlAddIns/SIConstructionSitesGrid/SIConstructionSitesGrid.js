var siSitesSelectedCode = '';
var siSitesRows = [];

function SetSites(data, showingAll) {
    var rows = [];
    try { rows = data ? JSON.parse(data) : []; } catch (e) { rows = []; }
    siSitesRows = rows;

    var root = document.getElementById('controlAddIn');
    if (!root) return;
    root.innerHTML = '';

    if (!rows.some(function (r) { return r.siteCode === siSitesSelectedCode; }))
        siSitesSelectedCode = rows.length ? (rows[0].siteCode || '') : '';

    var toolbar = document.createElement('div');
    toolbar.className = 'si-sites-toolbar';

    toolbar.appendChild(siteButton('+ Додати', function () {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AddSite', []);
    }));

    var selected = getSelectedSite();
    toolbar.appendChild(siteButton('↗ Відкрити', function () {
        invokeForSelected('OpenSite');
    }, !selected));
    toolbar.appendChild(siteButton('★ Зробити основним', function () {
        invokeForSelected('SetDefaultSite');
    }, !selected || !selected.canSetDefault));
    toolbar.appendChild(siteButton('Заморозити', function () {
        invokeForSelected('FreezeSite');
    }, !selected || !selected.canFreeze));
    toolbar.appendChild(siteButton('Відновити', function () {
        invokeForSelected('RestoreSite');
    }, !selected || !selected.canRestore));
    toolbar.appendChild(siteButton('Анулювати', function () {
        invokeForSelected('AnnulateSite');
    }, !selected || !selected.canAnnulate));
    toolbar.appendChild(siteButton(showingAll ? 'Приховати анульовані' : 'Показати всі', function () {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ToggleShowAll', [!showingAll]);
    }));
    root.appendChild(toolbar);

    if (!rows.length) {
        var empty = document.createElement('div');
        empty.className = 'si-sites-empty';
        empty.textContent = 'Будівельних майданчиків немає.';
        root.appendChild(empty);
        return;
    }

    var table = document.createElement('table');
    table.className = 'si-sites-table';
    var thead = document.createElement('thead');
    thead.innerHTML = '<tr><th>Майданчик</th><th class="si-sites-default">Основний</th><th class="si-sites-status">Стан</th></tr>';
    table.appendChild(thead);
    var tbody = document.createElement('tbody');

    rows.forEach(function (r) {
        var tr = document.createElement('tr');
        tr.dataset.siteCode = r.siteCode || '';
        if (r.siteCode === siSitesSelectedCode) tr.className = 'si-sites-selected';

        var name = document.createElement('td');
        name.textContent = r.name || r.siteCode || '—';
        tr.appendChild(name);

        var def = document.createElement('td');
        def.className = 'si-sites-default';
        def.textContent = r.isDefault ? '✓' : '';
        tr.appendChild(def);

        var status = document.createElement('td');
        status.className = 'si-sites-status';
        status.textContent = r.status || '';
        tr.appendChild(status);

        tr.onclick = function () {
            siSitesSelectedCode = r.siteCode || '';
            SetSites(JSON.stringify(siSitesRows), showingAll);
        };
        tr.ondblclick = function () {
            if (r.siteCode)
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OpenSite', [r.siteCode]);
        };
        tbody.appendChild(tr);
    });

    table.appendChild(tbody);
    var viewport = document.createElement('div');
    viewport.className = 'si-sites-grid-viewport';
    viewport.appendChild(table);
    root.appendChild(viewport);
}

function getSelectedSite() {
    for (var i = 0; i < siSitesRows.length; i++)
        if (siSitesRows[i].siteCode === siSitesSelectedCode) return siSitesRows[i];
    return null;
}

function invokeForSelected(eventName) {
    if (siSitesSelectedCode)
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(eventName, [siSitesSelectedCode]);
}

function siteButton(text, handler, disabled) {
    var button = document.createElement('button');
    button.type = 'button';
    button.textContent = text;
    button.disabled = !!disabled;
    button.onclick = handler;
    return button;
}
