(function () {
    'use strict';

    var host;
    var sourcePayload = { rows: [], emptyText: '' };

    var filters = {
        certificationStatus: '',
        administrativeStatus: '',
        applicability: '',
        validityType: '',
        projectionStatus: '',
        validFrom: '',
        validTo: ''
    };

    function ensureHost() {
        if (host) return host;
        host = document.getElementById('controlAddIn') || document.body;
        host.style.fontFamily = 'Segoe UI, Arial, sans-serif';
        host.style.fontSize = '12.5px';
        host.style.boxSizing = 'border-box';
        host.style.height = '100%';
        host.style.overflow = 'hidden';
        return host;
    }

    function invoke(name, args) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(name, args || []);
    }

    function el(tag, cls, text) {
        var n = document.createElement(tag);
        if (cls) n.className = cls;
        if (text !== undefined && text !== null) n.textContent = text;
        return n;
    }

    function uniqueValues(rows, field) {
        var seen = {};
        var values = [];
        rows.forEach(function (row) {
            var v = row[field] || '';
            if (v && !seen[v]) {
                seen[v] = true;
                values.push(v);
            }
        });
        values.sort();
        return values;
    }

    function makeSelect(rows, field, filterName) {
        var select = document.createElement('select');
        select.className = 'si-filter-control';

        var all = document.createElement('option');
        all.value = '';
        all.textContent = 'Усі';
        select.appendChild(all);

        uniqueValues(rows, field).forEach(function (v) {
            var opt = document.createElement('option');
            opt.value = v;
            opt.textContent = v;
            select.appendChild(opt);
        });

        select.value = filters[filterName] || '';
        select.addEventListener('change', function () {
            filters[filterName] = select.value;
            render(sourcePayload);
        });

        return select;
    }

    function makeDateFilter(filterName) {
        var input = document.createElement('input');
        input.type = 'date';
        input.className = 'si-filter-control si-filter-date';
        input.value = filters[filterName] || '';
        input.addEventListener('change', function () {
            filters[filterName] = input.value;
            render(sourcePayload);
        });
        return input;
    }

    function resetFilters() {
        filters = {
            certificationStatus: '',
            administrativeStatus: '',
            applicability: '',
            validityType: '',
            projectionStatus: '',
            validFrom: '',
            validTo: ''
        };
        render(sourcePayload);
    }

    function intersectsDateRange(row) {
        var filterFrom = filters.validFrom || '';
        var filterTo = filters.validTo || '';
        var rowFrom = row.validFromIso || '';
        var rowTo = row.validToIso || '';

        // Column semantics:
        // "Чинна з" filters Revision.ValidFrom >= selected date.
        // "Чинна до" filters Revision.ValidTo <= selected date.
        // Empty value means no restriction for that bound.
        if (filterFrom && rowFrom && rowFrom < filterFrom) return false;
        if (filterTo && rowTo && rowTo > filterTo) return false;
        return true;
    }

    function rowMatches(row) {
        if (filters.certificationStatus &&
            row.certificationStatus !== filters.certificationStatus) return false;

        if (filters.administrativeStatus &&
            row.administrativeStatus !== filters.administrativeStatus) return false;

        if (filters.applicability &&
            row.applicability !== filters.applicability) return false;

        if (filters.validityType &&
            row.validityType !== filters.validityType) return false;

        if (filters.projectionStatus &&
            row.projectionStatus !== filters.projectionStatus) return false;

        return intersectsDateRange(row);
    }

    function appendFilterCell(row, cls, control) {
        var cell = el('th', cls + ' si-filter-cell');
        if (control) cell.appendChild(control);
        row.appendChild(cell);
    }

    function render(payload) {
        sourcePayload = payload || { rows: [], emptyText: '' };

        var root = ensureHost();
        root.innerHTML = '';

        var style = document.createElement('style');
        style.textContent =
            '.si-root{height:100%;display:flex;flex-direction:column;box-sizing:border-box}' +
            '.si-toolbar{height:32px;display:flex;align-items:center;justify-content:flex-end;gap:10px;padding:2px 4px;box-sizing:border-box}' +
            '.si-count{color:#6b737b;white-space:nowrap}' +
            '.si-reset{height:27px;padding:2px 10px;border:1px solid #8b969f;background:#fff;cursor:pointer;font:inherit;white-space:nowrap}' +
            '.si-reset:hover{background:#eef2f4}' +
            '.si-wrap{flex:1;min-height:0;overflow:auto;border:1px solid #d6dce2;background:#fff;box-sizing:border-box}' +
            '.si-grid{width:100%;border-collapse:collapse;table-layout:fixed}' +
            '.si-grid th{font-weight:600;color:#3d4a57;text-align:left;background:#f7f8fa;border-bottom:1px solid #d6dce2;padding:5px 7px;white-space:nowrap;box-sizing:border-box}' +
            '.si-head-row th{position:sticky;top:34px;z-index:3}' +
            '.si-filter-row th{position:sticky;top:0;z-index:4;padding:4px 5px;background:#f7f8fa}' +
            '.si-filter-cell{height:34px;vertical-align:middle}' +
            '.si-filter-control{width:100%;height:26px;border:1px solid #b8c0c8;background:#fff;padding:1px 4px;box-sizing:border-box;font:inherit;min-width:0}' +
            '.si-filter-date{padding-right:1px}' +
            '.si-grid td{border-bottom:1px solid #e5e8eb;padding:5px 7px;height:30px;box-sizing:border-box;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}' +
            '.si-grid tr.data:hover{background:#f3f2f1}.si-link{color:#0066a1;text-decoration:underline;cursor:pointer}' +
            '.si-empty{padding:10px;color:#6b737b;font-style:italic}' +
            '.c-rev{width:7%}.c-cert{width:15%}.c-admin{width:14%}.c-app{width:13%}' +
            '.c-validity{width:11%}.c-from{width:11%}.c-to{width:11%}.c-proj{width:10%}.c-bom{width:8%}';
        root.appendChild(style);

        var rootBox = el('div', 'si-root');
        var rows = Array.isArray(sourcePayload.rows) ? sourcePayload.rows : [];
        var filteredRows = rows.filter(rowMatches);

        var toolbar = el('div', 'si-toolbar');
        toolbar.appendChild(el('div', 'si-count', 'Показано: ' + filteredRows.length + ' / ' + rows.length));

        var reset = el('button', 'si-reset', 'Скинути фільтри');
        reset.type = 'button';
        reset.addEventListener('click', resetFilters);
        toolbar.appendChild(reset);
        rootBox.appendChild(toolbar);

        var wrap = el('div', 'si-wrap');
        var table = el('table', 'si-grid');
        var thead = el('thead');

        // Filter row is built with exactly the same nine columns as the data grid.
        // This guarantees column-to-filter alignment.
        var fr = el('tr', 'si-filter-row');
        appendFilterCell(fr, 'c-rev', null);
        appendFilterCell(fr, 'c-cert', makeSelect(rows, 'certificationStatus', 'certificationStatus'));
        appendFilterCell(fr, 'c-admin', makeSelect(rows, 'administrativeStatus', 'administrativeStatus'));
        appendFilterCell(fr, 'c-app', makeSelect(rows, 'applicability', 'applicability'));
        appendFilterCell(fr, 'c-validity', makeSelect(rows, 'validityType', 'validityType'));
        appendFilterCell(fr, 'c-from', makeDateFilter('validFrom'));
        appendFilterCell(fr, 'c-to', makeDateFilter('validTo'));
        appendFilterCell(fr, 'c-proj', makeSelect(rows, 'projectionStatus', 'projectionStatus'));
        appendFilterCell(fr, 'c-bom', null);
        thead.appendChild(fr);

        var hr = el('tr', 'si-head-row');
        [
            ['Рев.','c-rev'],['Сертифікація','c-cert'],['Адміністративний','c-admin'],
            ['Актуальність','c-app'],['Валідність','c-validity'],['Чинна з','c-from'],
            ['Чинна до','c-to'],['Проєкція','c-proj'],['Версія BOM','c-bom']
        ].forEach(function (h) { hr.appendChild(el('th', h[1], h[0])); });
        thead.appendChild(hr);
        table.appendChild(thead);

        var tbody = el('tbody');

        if (!filteredRows.length) {
            var trEmpty = el('tr');
            var tdEmpty = el('td', 'si-empty',
                rows.length ? 'Немає ревізій, що відповідають вибраним фільтрам.' :
                (sourcePayload.emptyText || 'Немає ревізій.'));
            tdEmpty.colSpan = 9;
            trEmpty.appendChild(tdEmpty);
            tbody.appendChild(trEmpty);
        } else {
            filteredRows.forEach(function (row) {
                var tr = el('tr', 'data');

                var rev = el('td','c-rev');
                var revLink = el('span','si-link',String(row.revisionNo || ''));
                revLink.onclick = function(e) {
                    e.stopPropagation();
                    invoke('RevisionOpen',[row.recipeNo || '', Number(row.revisionNo || 0)]);
                };
                rev.appendChild(revLink);
                tr.appendChild(rev);

                tr.appendChild(el('td','c-cert',row.certificationStatus || ''));
                tr.appendChild(el('td','c-admin',row.administrativeStatus || ''));
                tr.appendChild(el('td','c-app',row.applicability || ''));
                tr.appendChild(el('td','c-validity',row.validityType || ''));
                tr.appendChild(el('td','c-from',row.validFrom || ''));
                tr.appendChild(el('td','c-to',row.validTo || ''));
                tr.appendChild(el('td','c-proj',row.projectionStatus || ''));

                var bom = el('td','c-bom');
                if (row.bomVersion) {
                    var bomLink = el('span','si-link',row.bomVersion);
                    bomLink.onclick = function(e) {
                        e.stopPropagation();
                        invoke('BOMVersionOpen',[row.recipeNo || '', Number(row.revisionNo || 0)]);
                    };
                    bom.appendChild(bomLink);
                }
                tr.appendChild(bom);

                tr.ondblclick = function() {
                    invoke('RevisionOpen',[row.recipeNo || '', Number(row.revisionNo || 0)]);
                };

                tbody.appendChild(tr);
            });
        }

        table.appendChild(tbody);
        wrap.appendChild(table);
        rootBox.appendChild(wrap);
        root.appendChild(rootBox);
    }

    window.RenderRows = function(rowsJson) {
        var payload = {};
        try { payload = JSON.parse(rowsJson || '{}'); } catch (e) { payload = {}; }
        render(payload);
    };

    render({rows:[]});
})();
