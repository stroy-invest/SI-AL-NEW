function sortTreeNodesAlphabetically(nodes) {
    if (!Array.isArray(nodes)) {
        return [];
    }

    nodes.sort((a, b) =>
        (a.name || '').localeCompare(
            (b.name || ''),
            'uk-UA',
            { sensitivity: 'base', numeric: true }
        )
    );

    nodes.forEach(node => {
        if (Array.isArray(node.children) && node.children.length > 0) {
            sortTreeNodesAlphabetically(node.children);
        }
    });

    return nodes;
}

let siTreeNodeMap = {};
let siTreeSelectedRow = null;
let siTreeContextMenu = null;
let siTreeAddButton = null;
let siTreeSelectedCode = '';
let siTreeSelectionMode = false;

function SelectNode(groupCode) {
    const entry = siTreeNodeMap[groupCode || ''];
    if (!entry) {
        return;
    }

    let parentCode = entry.node.parentCode || '';
    while (parentCode) {
        const parentEntry = siTreeNodeMap[parentCode];
        if (!parentEntry) {
            break;
        }

        setTreeNodeExpanded(parentEntry.treeNode, true);
        parentCode = parentEntry.node.parentCode || '';
    }

    if (siTreeSelectedRow) {
        siTreeSelectedRow.classList.remove('si-selected');
    }

    entry.row.classList.add('si-selected');
    siTreeSelectedRow = entry.row;
    siTreeSelectedCode = groupCode || '';

    if (siTreeAddButton) {
        siTreeAddButton.disabled = false;
    }

    entry.row.scrollIntoView({ block: 'nearest' });
}

function SetSelectionMode(isSelectionMode) {
    siTreeSelectionMode = !!isSelectionMode;
    const maintenanceButtons = document.querySelectorAll('.si-tree-maintenance-button');
    maintenanceButtons.forEach(btn => {
        btn.style.display = siTreeSelectionMode ? 'none' : '';
    });
}

function setTreeNodeExpanded(treeNode, expanded) {
    if (!treeNode || !treeNode.hasChildren) {
        return;
    }

    treeNode.childrenContainer.style.display = expanded ? 'block' : 'none';
    treeNode.toggle.textContent = expanded ? '▼' : '▶';
}

function RenderTree(treeJson) {
    siTreeNodeMap = {};
    siTreeSelectedRow = null;
    siTreeSelectedCode = '';
    siTreeAddButton = null;

    const data = sortTreeNodesAlphabetically(JSON.parse(treeJson || '[]'));
    const root = document.getElementById('controlAddIn');

    root.innerHTML = '';
    root.style.height = '100%';
    root.style.boxSizing = 'border-box';
    root.style.fontFamily = '"Segoe UI", sans-serif';
    root.style.fontSize = '14px';
    root.style.textAlign = 'left';
    root.style.backgroundColor = '#ffffff';
    root.style.color = '#323130';

    const style = document.createElement('style');
    style.textContent = `
        .si-tree-panel {
            height: 290px;
            border: 1px solid #d2d0ce;
            border-radius: 2px;
            background: #ffffff;
            color: #323130;
            box-sizing: border-box;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        .si-tree-toolbar {
            min-height: 42px;
            padding: 6px 10px;
            border-bottom: 1px solid #edebe9;
            background: #faf9f8;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            box-sizing: border-box;
        }

        .si-tree-toolbar-title {
            font-size: 15px;
            font-weight: 600;
            color: #323130;
            white-space: nowrap;
        }

        .si-tree-toolbar-buttons {
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .si-tree-button {
            min-height: 30px;
            padding: 4px 10px;
            border: 1px solid #8a8886;
            border-radius: 2px;
            background: #ffffff;
            color: #323130;
            font-family: "Segoe UI", sans-serif;
            font-size: 14px;
            cursor: pointer;
            white-space: nowrap;
        }

        .si-tree-button:hover {
            background: #f3f2f1;
            border-color: #605e5c;
        }

        .si-tree-button:active {
            background: #edebe9;
        }

        .si-tree-button:disabled {
            cursor: default;
            color: #a19f9d;
            border-color: #d2d0ce;
            background: #f3f2f1;
        }

        .si-tree-scroll {
            flex: 1 1 auto;
            min-height: 0;
            overflow: auto;
            background: #ffffff;
        }

        .si-tree-grid {
            min-width: 850px;
        }

        .si-tree-header,
        .si-tree-row {
            display: grid;
            grid-template-columns: minmax(280px, 1fr) 120px 170px 190px;
            align-items: center;
            box-sizing: border-box;
        }

        .si-tree-header {
            position: sticky;
            top: 0;
            z-index: 5;
            min-height: 36px;
            padding: 0 10px;
            border-bottom: 1px solid #d2d0ce;
            background: #ffffff;
            color: #323130;
            font-weight: 600;
        }

        .si-tree-body {
            padding: 6px 4px 8px 4px;
            background: #ffffff;
        }

        .si-tree-row {
            min-height: 26px;
            padding: 3px 10px;
            border-left: 3px solid transparent;
            border-radius: 2px;
            color: #323130;
            background: transparent;
            cursor: pointer;
            user-select: none;
        }

        .si-tree-row:hover {
            background: #f3f2f1;
        }

        .si-tree-row.si-selected {
            background: #deecf9;
            border-left-color: #008575;
            font-weight: 600;
        }

        .si-tree-category-cell {
            display: flex;
            align-items: center;
            min-width: 0;
            white-space: nowrap;
        }

        .si-tree-toggle {
            display: inline-block;
            flex: 0 0 16px;
            width: 16px;
            margin-right: 4px;
            text-align: center;
            color: #323130;
        }

        .si-tree-label,
        .si-tree-value {
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .si-tree-label {
            color: #007e87;
            cursor: pointer;
            text-decoration: none;
        }

        .si-tree-label:hover {
            text-decoration: underline;
        }

        .si-tree-label:focus {
            outline: 1px dotted #605e5c;
            outline-offset: 2px;
        }

        .si-tree-value {
            padding-right: 12px;
        }

        .si-tree-context-menu {
            position: fixed;
            z-index: 10000;
            min-width: 170px;
            padding: 4px 0;
            border: 1px solid #c8c6c4;
            border-radius: 2px;
            background: #ffffff;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.18);
            font-family: "Segoe UI", sans-serif;
            font-size: 14px;
        }

        .si-tree-context-item {
            padding: 7px 12px;
            cursor: pointer;
            white-space: nowrap;
        }

        .si-tree-context-item:hover {
            background: #f3f2f1;
        }
    `;
    root.appendChild(style);

    const panel = document.createElement('div');
    panel.className = 'si-tree-panel';

    const toolbar = document.createElement('div');
    toolbar.className = 'si-tree-toolbar';

    const toolbarTitle = document.createElement('div');
    toolbarTitle.className = 'si-tree-toolbar-title';
    toolbarTitle.textContent = 'Групи товарів';

    const toolbarButtons = document.createElement('div');
    toolbarButtons.className = 'si-tree-toolbar-buttons';

    const expandBtn = document.createElement('button');
    expandBtn.type = 'button';
    expandBtn.className = 'si-tree-button';
    expandBtn.textContent = 'Розгорнути все';

    const collapseBtn = document.createElement('button');
    collapseBtn.type = 'button';
    collapseBtn.className = 'si-tree-button';
    collapseBtn.textContent = 'Згорнути все';

    const addBtn = document.createElement('button');
    addBtn.type = 'button';
    addBtn.className = 'si-tree-button si-tree-maintenance-button';
    addBtn.textContent = 'Додати елемент';
    addBtn.title = 'Створити нову категорію відносно поточної вибраної категорії';
    addBtn.disabled = true;
    siTreeAddButton = addBtn;

    const deleteBtn = document.createElement('button');
    deleteBtn.type = 'button';
    deleteBtn.className = 'si-tree-button si-tree-maintenance-button';
    deleteBtn.textContent = 'Видалити елемент';
    deleteBtn.title = 'Видалити поточну вибрану категорію';
    deleteBtn.disabled = !siTreeSelectedCode;

    toolbarButtons.appendChild(addBtn);
    toolbarButtons.appendChild(deleteBtn);
    if (siTreeSelectionMode) {
        addBtn.style.display = 'none';
        deleteBtn.style.display = 'none';
    }
    toolbarButtons.appendChild(expandBtn);
    toolbarButtons.appendChild(collapseBtn);
    toolbar.appendChild(toolbarTitle);
    toolbar.appendChild(toolbarButtons);

    const scrollContainer = document.createElement('div');
    scrollContainer.className = 'si-tree-scroll';

    const grid = document.createElement('div');
    grid.className = 'si-tree-grid';

    const header = document.createElement('div');
    header.className = 'si-tree-header';

    ['Категорія', 'Базова UoM', 'Вид категорії', 'Вид готової продукції']
        .forEach(caption => {
            const cell = document.createElement('div');
            cell.textContent = caption;
            header.appendChild(cell);
        });

    const body = document.createElement('div');
    body.className = 'si-tree-body';

    grid.appendChild(header);
    grid.appendChild(body);
    scrollContainer.appendChild(grid);
    panel.appendChild(toolbar);
    panel.appendChild(scrollContainer);
    root.appendChild(panel);

    const treeNodes = [];

    function createValueCell(value) {
        const cell = document.createElement('div');
        cell.className = 'si-tree-value';
        cell.textContent = value || '';
        cell.title = value || '';
        return cell;
    }

    function setExpanded(treeNode, expanded) {
        setTreeNodeExpanded(treeNode, expanded);
    }

    function createNode(node, level) {
        const wrapper = document.createElement('div');

        const row = document.createElement('div');
        row.className = 'si-tree-row';

        const categoryCell = document.createElement('div');
        categoryCell.className = 'si-tree-category-cell';
        categoryCell.style.paddingLeft = (level * 18) + 'px';

        const hasChildren = Array.isArray(node.children) && node.children.length > 0;

        const toggle = document.createElement('span');
        toggle.className = 'si-tree-toggle';
        toggle.textContent = hasChildren ? '▶' : '•';

        const label = document.createElement('span');
        label.className = 'si-tree-label';
        label.textContent = node.name || node.code || '';
        label.title = 'Відкрити картку категорії: ' + (node.name || node.code || '');
        label.tabIndex = 0;
        label.setAttribute('role', 'link');

        function openCategoryCard(event) {
            event.stopPropagation();

            if (siTreeSelectedRow) {
                siTreeSelectedRow.classList.remove('si-selected');
            }

            row.classList.add('si-selected');
            siTreeSelectedRow = row;
            siTreeSelectedCode = node.code || '';
            deleteBtn.disabled = !siTreeSelectedCode;
            addBtn.disabled = false;

            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeSelected', [node.code || '']);
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeOpenRequested', [node.code || '']);
        }

        label.onclick = openCategoryCard;
        label.onkeydown = function (event) {
            if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                openCategoryCard(event);
            }
        };

        categoryCell.appendChild(toggle);
        categoryCell.appendChild(label);

        row.appendChild(categoryCell);
        row.appendChild(createValueCell(node.baseUomCode));
        row.appendChild(createValueCell(node.categoryKind));
        row.appendChild(createValueCell(node.finishedProductType));

        const childrenContainer = document.createElement('div');
        childrenContainer.style.display = 'none';

        if (hasChildren) {
            node.children.forEach(child => {
                childrenContainer.appendChild(createNode(child, level + 1));
            });
        }

        const treeNode = {
            hasChildren: hasChildren,
            toggle: toggle,
            childrenContainer: childrenContainer
        };
        treeNodes.push(treeNode);
        siTreeNodeMap[node.code || ''] = { row: row, node: node, treeNode: treeNode };

        row.onclick = function (event) {
            event.stopPropagation();

            if (siTreeSelectedRow) {
                siTreeSelectedRow.classList.remove('si-selected');
            }

            row.classList.add('si-selected');
            siTreeSelectedRow = row;
            siTreeSelectedCode = node.code || '';
            deleteBtn.disabled = !siTreeSelectedCode;
            addBtn.disabled = false;

            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeSelected', [node.code || '']);

            if (hasChildren) {
                const expanded = childrenContainer.style.display === 'none';
                setExpanded(treeNode, expanded);
            }
        };

        row.oncontextmenu = function (event) {
            event.preventDefault();
            event.stopPropagation();

            if (siTreeSelectedRow) {
                siTreeSelectedRow.classList.remove('si-selected');
            }

            row.classList.add('si-selected');
            siTreeSelectedRow = row;
            siTreeSelectedCode = node.code || '';
            deleteBtn.disabled = !siTreeSelectedCode;
            addBtn.disabled = false;
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeSelected', [node.code || '']);

            showContextMenu(event.clientX, event.clientY, node.code || '');
        };

        wrapper.appendChild(row);
        wrapper.appendChild(childrenContainer);

        return wrapper;
    }

    function hideContextMenu() {
        if (siTreeContextMenu && siTreeContextMenu.parentNode) {
            siTreeContextMenu.parentNode.removeChild(siTreeContextMenu);
        }
        siTreeContextMenu = null;
    }

    // A click outside the Control Add-In is not delivered to this document.
    // Closing on window blur makes the context menu behave like a native BC menu.
    window.addEventListener('blur', hideContextMenu);
    window.addEventListener('keydown', function (event) {
        if (event.key === 'Escape') {
            hideContextMenu();
        }
    });

    function showContextMenu(x, y, groupCode) {
        hideContextMenu();

        const menu = document.createElement('div');
        menu.className = 'si-tree-context-menu';
        menu.style.left = x + 'px';
        menu.style.top = y + 'px';

        const addItem = document.createElement('div');
        addItem.className = 'si-tree-context-item';
        addItem.textContent = 'Додати елемент';
        addItem.onclick = function (event) {
            event.stopPropagation();
            hideContextMenu();
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AddCategoryRequested', [groupCode || '']);
        };

        const deleteItem = document.createElement('div');
        deleteItem.className = 'si-tree-context-item';
        deleteItem.textContent = 'Видалити елемент';
        deleteItem.onclick = function (event) {
            event.stopPropagation();
            hideContextMenu();
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('DeleteCategoryRequested', [groupCode || '']);
        };

        menu.appendChild(addItem);
        menu.appendChild(deleteItem);
        document.body.appendChild(menu);
        siTreeContextMenu = menu;

        setTimeout(function () {
            document.addEventListener('click', hideContextMenu, { once: true });
        }, 0);
    }

    data.forEach(node => body.appendChild(createNode(node, 0)));

    addBtn.onclick = function (event) {
        event.stopPropagation();

        // The toolbar action must use the exact code of the currently selected UI node.
        // Do not derive it indirectly from the row map: after re-rendering this could
        // produce a stale context and create a category in the wrong branch.
        if (!siTreeSelectedCode) {
            return;
        }

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AddCategoryRequested', [siTreeSelectedCode]);
    };

    deleteBtn.onclick = function (event) {
        event.stopPropagation();

        // Reuse the same AL event and deletion checks as the context-menu action.
        if (!siTreeSelectedCode) {
            return;
        }

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('DeleteCategoryRequested', [siTreeSelectedCode]);
    };

    expandBtn.onclick = function (event) {
        event.stopPropagation();
        treeNodes.forEach(treeNode => setExpanded(treeNode, true));
    };

    collapseBtn.onclick = function (event) {
        event.stopPropagation();
        treeNodes.forEach(treeNode => setExpanded(treeNode, false));
    };
}
