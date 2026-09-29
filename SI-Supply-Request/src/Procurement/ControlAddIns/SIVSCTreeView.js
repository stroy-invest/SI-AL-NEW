let siVscTreeData = [];
let siVscExpanded = new Set();
let siVscInitialized = false;

function RenderTree(treeJson) {
    const previousExpanded = new Set(siVscExpanded);
    siVscTreeData = JSON.parse(treeJson || '[]');

    if (!siVscInitialized) {
        collectGroupKeys(siVscTreeData).forEach(k => siVscExpanded.add(k));
        siVscInitialized = true;
    } else {
        siVscExpanded = previousExpanded;
    }

    renderVscTree();
}

function ExpandAll() {
    siVscExpanded.clear();
    collectGroupKeys(siVscTreeData).forEach(k => siVscExpanded.add(k));
    renderVscTree();
}

function CollapseAll() {
    siVscExpanded.clear();
    renderVscTree();
}

function collectGroupKeys(nodes) {
    const keys = [];
    (nodes || []).forEach(node => {
        if (node.children && node.children.length) {
            keys.push(node.key);
            keys.push(...collectGroupKeys(node.children));
        }
    });
    return keys;
}

function renderVscTree() {
    const root = document.getElementById('controlAddIn');
    root.innerHTML = '';
    root.style.height = '100%';
    root.style.boxSizing = 'border-box';
    root.style.fontFamily = '"Segoe UI", sans-serif';
    root.style.fontSize = '14px';
    root.style.color = '#323130';
    root.style.backgroundColor = '#ffffff';

    const style = document.createElement('style');
    style.textContent = `
        .vsc-wrap { height:100%; overflow:auto; border:1px solid #edebe9; box-sizing:border-box; background:#fff; }
        .vsc-grid { min-width:900px; width:100%; border-collapse:collapse; table-layout:fixed; }
        .vsc-grid th { position:sticky; top:0; z-index:2; background:#faf9f8; border-bottom:1px solid #d2d0ce; padding:9px 8px; text-align:left; font-weight:600; }
        .vsc-grid td { border-bottom:1px solid #edebe9; padding:7px 8px; vertical-align:middle; }
        .vsc-grid tr:hover td { background:#f3f2f1; }
        .vsc-name { width:46%; }
        .vsc-uom { width:11%; }
        .vsc-qty { width:15%; text-align:right; }
        .vsc-multiple { width:15%; text-align:right; }
        .vsc-lead { width:13%; }
        .vsc-node { display:flex; align-items:center; min-height:24px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
        .vsc-toggle { width:22px; min-width:22px; cursor:pointer; user-select:none; text-align:center; }
        .vsc-indent { display:inline-block; flex:0 0 auto; }
        .vsc-vendor { font-weight:700; }
        .vsc-category { font-weight:600; }
        .vsc-method { font-weight:600; }
        .vsc-leaf { cursor:pointer; }
        .vsc-leaf-code { color:#605e5c; font-size:12px; margin-left:6px; }
        .vsc-empty { padding:18px; color:#605e5c; }
    `;
    root.appendChild(style);

    if (!siVscTreeData.length) {
        const empty = document.createElement('div');
        empty.className = 'vsc-empty';
        empty.textContent = 'Канали постачання не налаштовані.';
        root.appendChild(empty);
        return;
    }

    const wrap = document.createElement('div');
    wrap.className = 'vsc-wrap';
    const table = document.createElement('table');
    table.className = 'vsc-grid';
    table.innerHTML = `<thead><tr>
        <th class="vsc-name">Постачальник / Категорія / Спосіб постачання</th>
        <th class="vsc-uom">Од. виміру</th>
        <th class="vsc-qty">Мін. кількість замовлення</th>
        <th class="vsc-multiple">Кратність замовлення</th>
        <th class="vsc-lead">Строк постачання</th>
    </tr></thead>`;
    const body = document.createElement('tbody');
    appendNodes(body, siVscTreeData, 0, true);
    table.appendChild(body);
    wrap.appendChild(table);
    root.appendChild(wrap);
}

function appendNodes(body, nodes, level, ancestorsVisible) {
    (nodes || []).forEach(node => {
        const isGroup = !!(node.children && node.children.length);
        const expanded = isGroup && siVscExpanded.has(node.key);
        const row = document.createElement('tr');
        row.style.display = ancestorsVisible ? '' : 'none';

        const nameCell = document.createElement('td');
        const nodeDiv = document.createElement('div');
        nodeDiv.className = 'vsc-node ' + (node.type === 'vendor' ? 'vsc-vendor' : node.type === 'category' ? 'vsc-category' : node.type === 'method' ? 'vsc-method' : 'vsc-leaf');

        const indent = document.createElement('span');
        indent.className = 'vsc-indent';
        indent.style.width = (level * 24) + 'px';
        nodeDiv.appendChild(indent);

        const toggle = document.createElement('span');
        toggle.className = 'vsc-toggle';
        toggle.textContent = isGroup ? (expanded ? '▼' : '▶') : '';
        nodeDiv.appendChild(toggle);

        const label = document.createElement('span');
        label.textContent = node.label || '';
        nodeDiv.appendChild(label);

        if (node.type === 'capability' && node.code) {
            nodeDiv.style.cursor = 'pointer';
            nodeDiv.ondblclick = () => Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('CapabilityOpenRequested', [node.code]);
        }

        if (isGroup) {
            nodeDiv.style.cursor = 'pointer';
            nodeDiv.onclick = () => {
                if (siVscExpanded.has(node.key)) siVscExpanded.delete(node.key); else siVscExpanded.add(node.key);
                renderVscTree();
            };
        }

        nameCell.appendChild(nodeDiv);
        row.appendChild(nameCell);
        appendValueCell(row, node.type === 'capability' ? node.uom : '', 'vsc-uom');
        appendValueCell(row, node.type === 'capability' ? node.minimumQty : '', 'vsc-qty');
        appendValueCell(row, node.type === 'capability' ? node.orderMultiple : '', 'vsc-multiple');
        appendValueCell(row, node.type === 'capability' ? node.leadTime : '', 'vsc-lead');
        body.appendChild(row);

        if (isGroup)
            appendNodes(body, node.children, level + 1, ancestorsVisible && expanded);
    });
}

function appendValueCell(row, value, className) {
    const cell = document.createElement('td');
    cell.className = className;
    cell.textContent = value === undefined || value === null ? '' : String(value);
    row.appendChild(cell);
}
