(function () {
    'use strict';
    let nodes = [], expanded = new Set(), selected = '', searchText = '', mounted = false;
    let characteristics = [], selectionLabel = '', initializedExpansion = false;
    const invoke = (name, args) => Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(name, args);
    const make = (tag, cls, txt) => { const el = document.createElement(tag); if (cls) el.className = cls; if (txt !== undefined) el.textContent = txt; return el; };
    const compare = (a, b) => String(a.label || '').localeCompare(String(b.label || ''), 'uk-UA', {numeric:true, sensitivity:'base'});
    function sortTree(items) { items.sort(compare); items.forEach(n => sortTree(n.children || [])); }
    function tokens() { return searchText.toLocaleLowerCase('uk-UA').trim().split(/\s+/).filter(Boolean); }
    function textOf(n) { return ((n.label || '') + ' ' + (n.code || '')).toLocaleLowerCase('uk-UA'); }
    function visible(n, terms, ancestors) {
        const path = ancestors + ' ' + textOf(n);
        return !terms.length || terms.every(t => path.includes(t)) || (n.children || []).some(c => visible(c, terms, path));
    }
    function findNode(key, items = nodes) {
        for (const n of items) { if (n.key === key) return n; const child = findNode(key, n.children || []); if (child) return child; }
        return null;
    }
    function walk(items, fn) { items.forEach(n => { fn(n); walk(n.children || [], fn); }); }
    function fullModelLabel(node) {
        if (!node || node.kind !== 'model') return '';
        const path = [];
        function visit(items, ancestors) {
            for (const current of items) {
                const next = current.kind === 'root' ? ancestors : [...ancestors, current.label || current.code || ''];
                if (current.key === node.key) { path.push(...next); return true; }
                if (visit(current.children || [], next)) return true;
            }
            return false;
        }
        visit(nodes, []);
        return path.filter(Boolean).join(' ') || node.label || node.model || '';
    }
    function act(event) { const n = findNode(selected); if (n) invoke(event, [n.kind, n.type || '', n.brand || '', n.model || '']); }
    function choose(n) {
        selected = n.key;
        selectionLabel = fullModelLabel(n);
        if (n.kind === 'model') invoke('ModelSelected', [n.brand, n.model]);
        else { characteristics = []; invoke('SelectionCleared', []); }
        draw(); drawCharacteristics();
    }
    function draw() {
        const host = document.getElementById('si-vm-tree'); if (!host) return;
        host.replaceChildren();
        const terms = tokens();
        const add = (n, depth, ancestors) => {
            if (!visible(n, terms, ancestors)) return;
            const row = make('div', 'vm-row' + (selected === n.key ? ' vm-selected' : ''));
            row.style.paddingLeft = (8 + depth * 20) + 'px';
            const children = n.children || [], open = terms.length > 0 || expanded.has(n.key);
            const toggle = make('span', 'vm-toggle', children.length ? (open ? '▾' : '▸') : '·');
            toggle.addEventListener('click', e => { e.stopPropagation(); if (expanded.has(n.key)) expanded.delete(n.key); else expanded.add(n.key); draw(); });
            row.appendChild(toggle);
            const name = make('span', 'vm-label' + (n.kind !== 'model' ? ' vm-bold' : ''), n.label);
            if (n.kind === 'model') {
                name.classList.add('vm-link');
                name.title = 'Відкрити картку моделі';
                name.addEventListener('click', e => { e.stopPropagation(); choose(n); invoke('ModelOpenRequested', [n.brand, n.model]); });
            }
            row.appendChild(name);
            row.addEventListener('click', () => choose(n));
            host.appendChild(row);
            if (open) children.forEach(c => add(c, depth + 1, ancestors + ' ' + textOf(n)));
        };
        nodes.forEach(n => add(n, 0, ''));
    }
    function drawCharacteristics() {
        const host = document.getElementById('si-vm-characteristics'); if (!host) return;
        host.replaceChildren();
        const heading = document.getElementById('si-vm-selected-model');
        if (heading) heading.textContent = selectionLabel;
        if (!selected || !findNode(selected) || findNode(selected).kind !== 'model') {
            host.appendChild(make('div', 'vm-empty', 'Виберіть модель у дереві, щоб переглянути її характеристики.'));
            return;
        }
        if (!characteristics.length) {
            host.appendChild(make('div', 'vm-empty', 'Для цієї моделі характеристики не задано.'));
            return;
        }
        const table = make('table', 'vm-table');
        const thead = make('thead'); const hr = make('tr');
        ['Тип характеристики', 'Кількість', 'Одиниця вимірювання'].forEach(label => hr.appendChild(make('th', '', label)));
        thead.appendChild(hr); table.appendChild(thead);
        const body = make('tbody');
        characteristics.forEach(item => {
            const tr = make('tr');
            tr.appendChild(make('td', '', item.code || ''));
            tr.appendChild(make('td', 'vm-number', item.quantity || ''));
            tr.appendChild(make('td', '', item.uom || ''));
            body.appendChild(tr);
        });
        table.appendChild(body); host.appendChild(table);
    }
    function fitHeight() {
        const root = document.getElementById('controlAddIn');
        const work = document.getElementById('si-vm-workspace');
        if (!root || !work) return;
        const rect = root.getBoundingClientRect();
        const available = window.innerHeight - rect.top - 26;
        // Control Add-In host may impose a smaller height than the viewport.
        const hostHeight = root.parentElement ? root.parentElement.getBoundingClientRect().height : 0;
        const target = Math.max(340, Math.min(available, hostHeight > 380 ? hostHeight : available));
        root.style.height = Math.round(target) + 'px';
    }
    function init() {
        if (mounted) return;
        const root = document.getElementById('controlAddIn'); if (!root) return;
        mounted = true; root.replaceChildren(); root.classList.add('vm-root');
        const style = make('style');
        style.textContent = `
            .vm-root{box-sizing:border-box;display:flex;flex-direction:column;width:100%;min-height:340px;font-family:'Segoe UI',Arial,sans-serif;font-size:14px;color:inherit}
            .vm-root *{box-sizing:border-box}
            .vm-workspace{display:grid;grid-template-columns:minmax(0,1fr) minmax(290px,.92fr);gap:12px;flex:1;min-height:0}
            .vm-left,.vm-right{display:flex;flex-direction:column;min-width:0;min-height:0;border:1px solid #d4dbe0;border-radius:5px;overflow:hidden}
            .vm-left-head{padding:10px 10px 0;flex:none}
            .vm-toolbar{display:flex;flex-wrap:wrap;gap:6px;margin-bottom:9px}
            .vm-toolbar button,.vm-search button{padding:5px 9px;background:transparent;color:inherit;border:1px solid #aab4bb;border-radius:3px;cursor:pointer;font:inherit}
            .vm-search{display:flex;gap:6px;margin-bottom:10px}
            .vm-search input{flex:1;min-width:0;padding:7px;border:1px solid #aab4bb;background:transparent;color:inherit;font:inherit}
            .vm-tree-scroll,.vm-parameters-scroll{overflow:auto;min-height:0;flex:1;overscroll-behavior:contain}
            .vm-row{display:flex;align-items:center;gap:7px;min-height:32px;border-bottom:1px solid #e3e3e3;cursor:pointer;padding-right:8px}
            .vm-row:hover{background:#e5f1f4;color:#111}.vm-selected{background:#cce9ef;color:#111}
            .vm-toggle{width:17px;flex-shrink:0;text-align:center;user-select:none}
            .vm-label{min-width:0;overflow-wrap:anywhere}.vm-link:hover{text-decoration:underline;color:#0067a0}
            .vm-bold{font-weight:600}.vm-right-head{padding:15px 16px 11px;border-bottom:1px solid #d4dbe0;flex:none}
            .vm-right-title{font-weight:600;font-size:16px}.vm-subtitle{font-size:12px;color:#667783;margin-top:4px}
            .vm-parameters-scroll{padding:12px}.vm-table{width:100%;border-collapse:collapse;font-size:13px;table-layout:fixed}
            .vm-table th,.vm-table td{text-align:left;padding:9px 7px;border-bottom:1px solid #d4dbe0;overflow-wrap:anywhere}
            .vm-table th{font-size:12px;color:#667783;font-weight:500;background:rgba(130,145,155,.08)}
            .vm-table th:nth-child(1){width:43%}.vm-table th:nth-child(2){width:24%}.vm-table th:nth-child(3){width:33%}
            .vm-table .vm-number{text-align:right;font-variant-numeric:tabular-nums}
            .vm-empty{padding:14px 8px;color:#667783;font-size:13px}
            @media(max-width:720px){.vm-workspace{grid-template-columns:minmax(0,1fr) minmax(240px,.85fr);gap:6px}.vm-right-head{padding:10px}.vm-parameters-scroll{padding:6px}}
        `;
        root.appendChild(style);
        const workspace = make('div', 'vm-workspace'); workspace.id = 'si-vm-workspace';
        const left = make('section', 'vm-left'); const head = make('div', 'vm-left-head');
        const toolbar = make('div', 'vm-toolbar');
        [['Додати', () => act('AddRequested')], ['Видалити', () => act('DeleteRequested')],
         ['Розгорнути все', () => { walk(nodes, n => expanded.add(n.key)); draw(); }],
         ['Згорнути все', () => { expanded.clear(); draw(); }]].forEach(([label, fn]) => {
            const b = make('button', '', label); b.type = 'button'; b.addEventListener('click', fn); toolbar.appendChild(b);
        });
        head.appendChild(toolbar);
        const search = make('div', 'vm-search'); const input = make('input');
        input.placeholder = 'Пошук типу, бренду або моделі';
        input.addEventListener('input', () => { searchText = input.value; draw(); });
        const clear = make('button', '', 'Очистити'); clear.type = 'button';
        clear.addEventListener('click', () => { input.value = ''; searchText = ''; draw(); input.focus(); });
        search.appendChild(input); search.appendChild(clear); head.appendChild(search); left.appendChild(head);
        const tree = make('div', 'vm-tree-scroll'); tree.id = 'si-vm-tree'; left.appendChild(tree);
        const right = make('section', 'vm-right'); const rightHead = make('div', 'vm-right-head');
        rightHead.appendChild(make('div', 'vm-right-title', 'Характеристики моделі'));
        const subtitle = make('div', 'vm-subtitle'); subtitle.id = 'si-vm-selected-model'; rightHead.appendChild(subtitle);
        right.appendChild(rightHead);
        const params = make('div', 'vm-parameters-scroll'); params.id = 'si-vm-characteristics'; right.appendChild(params);
        workspace.appendChild(left); workspace.appendChild(right); root.appendChild(workspace);
        fitHeight(); window.addEventListener('resize', fitHeight);
        draw(); drawCharacteristics();
    }
    window.siVehicleTreeRender = function (json) {
        try { nodes = JSON.parse(json || '[]'); } catch (e) { nodes = []; }
        sortTree(nodes); init();
        if (!initializedExpansion) { walk(nodes, n => { if (n.kind !== 'model') expanded.add(n.key); }); initializedExpansion = true; }
        if (selected && !findNode(selected)) { selected = ''; selectionLabel = ''; characteristics = []; invoke('SelectionCleared', []); }
        draw(); drawCharacteristics(); fitHeight();
        // Refresh characteristics after the model card has been edited.
        const n = findNode(selected);
        if (n && n.kind === 'model') { selectionLabel = fullModelLabel(n); drawCharacteristics(); invoke('ModelSelected', [n.brand, n.model]); }
    };
    window.siVehicleCharacteristicsRender = function (json) {
        try { characteristics = JSON.parse(json || '[]'); } catch (e) { characteristics = []; }
        init(); drawCharacteristics();
    };
})();
