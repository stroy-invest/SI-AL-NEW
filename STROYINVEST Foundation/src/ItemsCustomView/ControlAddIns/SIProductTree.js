let siProductNodeMap = {};
let siProductSelectedRow = null;
let siProductSelectedNode = null;

function productNodeKey(nodeType, itemNo, variantCode) {
    return (nodeType || '') + '|' + (itemNo || '') + '|' + (variantCode || '');
}

function setProductNodeExpanded(node, expanded) {
    if (!node || !node.hasChildren) return;
    node.childrenContainer.style.display = expanded ? 'block' : 'none';
    node.toggle.textContent = expanded ? '▼' : '▶';
}

function selectProductRow(row, nodeType, itemNo, variantCode, notifyAl) {
    if (siProductSelectedRow) siProductSelectedRow.classList.remove('si-product-selected');
    row.classList.add('si-product-selected');
    siProductSelectedRow = row;
    siProductSelectedNode = {
        nodeType: nodeType || '',
        itemNo: itemNo || '',
        variantCode: variantCode || ''
    };

    if (notifyAl) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
            'ProductSelected',
            [nodeType || '', itemNo || '', variantCode || '']
        );
    }
}

function SelectProduct(nodeType, itemNo, variantCode) {
    const key = productNodeKey(nodeType, itemNo, variantCode);
    const entry = siProductNodeMap[key];
    if (!entry) return;

    if (entry.parentItemKey) {
        const parent = siProductNodeMap[entry.parentItemKey];
        if (parent) setProductNodeExpanded(parent, true);
    }

    selectProductRow(entry.row, nodeType, itemNo, variantCode, false);
    entry.row.scrollIntoView({ block: 'nearest' });
}

function RenderProducts(productTreeJson) {
    const data = JSON.parse(productTreeJson || '[]');
    const root = document.getElementById('controlAddIn');

    siProductNodeMap = {};
    siProductSelectedRow = null;
    siProductSelectedNode = null;

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
        .si-product-panel {
            min-height: 235px;
            height: 100%;
            border: 1px solid #edebe9;
            background: #fff;
            box-sizing: border-box;
            overflow: auto;
        }
        .si-product-grid { min-width: 620px; }
        .si-product-header,
        .si-product-row {
            display: grid;
            grid-template-columns: minmax(420px, 1fr) 140px;
            align-items: center;
            box-sizing: border-box;
        }
        .si-product-header {
            position: sticky;
            top: 0;
            z-index: 3;
            min-height: 34px;
            padding: 0 10px;
            border-bottom: 1px solid #d2d0ce;
            background: #fff;
            color: #605e5c;
            font-size: 13px;
        }
        .si-product-row {
            min-height: 31px;
            padding: 0 10px;
            border-bottom: 1px solid #edebe9;
            border-left: 3px solid transparent;
            cursor: default;
            user-select: none;
        }
        .si-product-row:hover { background: #f3f2f1; }
        .si-product-row.si-product-selected {
            background: #deecf9;
            border-left-color: #008575;
        }
        .si-product-cell {
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            padding-right: 12px;
        }
        .si-product-name-cell {
            display: flex;
            align-items: center;
            min-width: 0;
        }
        .si-product-toggle {
            flex: 0 0 20px;
            width: 20px;
            margin-right: 4px;
            text-align: center;
            cursor: pointer;
            font-size: 15px;
        }
        .si-product-toggle-spacer {
            flex: 0 0 20px;
            width: 20px;
            margin-right: 4px;
        }
        .si-product-indent {
            flex: 0 0 48px;
            width: 48px;
        }
        .si-product-type-icon {
            flex: 0 0 20px;
            width: 20px;
            margin-right: 7px;
            text-align: center;
            color: #605e5c;
            font-size: 13px;
            line-height: 1;
        }
        .si-product-item-row .si-product-link {
            font-weight: 600;
        }
        .si-product-variant-row .si-product-link {
            font-weight: 400;
        }
        .si-product-link {
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            color: #007e87;
            cursor: pointer;
            text-decoration: none;
        }
        .si-product-link:hover { text-decoration: underline; }
        .si-product-link:focus {
            outline: 1px dotted #605e5c;
            outline-offset: 2px;
        }
        .si-product-variant-row { background: #fff; }
        .si-product-children { display: block; }
        .si-product-empty {
            min-height: 90px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #605e5c;
        }
    `;
    root.appendChild(style);

    const panel = document.createElement('div');
    panel.className = 'si-product-panel';
    const grid = document.createElement('div');
    grid.className = 'si-product-grid';

    const header = document.createElement('div');
    header.className = 'si-product-header';
    ['Назва', 'Од. виміру'].forEach(caption => {
        const cell = document.createElement('div');
        cell.className = 'si-product-cell';
        cell.textContent = caption;
        header.appendChild(cell);
    });
    grid.appendChild(header);

    if (!data.length) {
        const empty = document.createElement('div');
        empty.className = 'si-product-empty';
        empty.textContent = '(Немає товарів у вибраній категорії)';
        grid.appendChild(empty);
    } else {
        data.forEach(item => {
            const itemRow = document.createElement('div');
            itemRow.className = 'si-product-row si-product-item-row';

            const itemNameCell = document.createElement('div');
            itemNameCell.className = 'si-product-cell si-product-name-cell';

            const toggle = document.createElement('span');
            toggle.className = 'si-product-toggle';
            toggle.textContent = (item.children && item.children.length) ? '▼' : '';
            itemNameCell.appendChild(toggle);

            const itemIcon = document.createElement('span');
            itemIcon.className = 'si-product-type-icon';
            itemIcon.textContent = '▣';
            itemIcon.title = 'Товар';
            itemNameCell.appendChild(itemIcon);

            const itemLink = document.createElement('span');
            itemLink.className = 'si-product-link';
            itemLink.textContent = item.name || item.itemNo || '';
            itemLink.title = 'Відкрити картку товару: ' + (item.name || item.itemNo || '');
            itemLink.tabIndex = 0;
            itemLink.setAttribute('role', 'link');
            itemNameCell.appendChild(itemLink);
            itemRow.appendChild(itemNameCell);

            const uomCell = document.createElement('div');
            uomCell.className = 'si-product-cell';
            uomCell.textContent = item.baseUomCode || '';
            uomCell.title = item.baseUomCode || '';
            itemRow.appendChild(uomCell);

            const itemKey = productNodeKey('Item', item.itemNo, '');
            const childrenContainer = document.createElement('div');
            childrenContainer.className = 'si-product-children';
            const itemEntry = {
                row: itemRow,
                nodeType: 'Item',
                itemNo: item.itemNo || '',
                variantCode: '',
                toggle: toggle,
                childrenContainer: childrenContainer,
                hasChildren: !!(item.children && item.children.length)
            };
            siProductNodeMap[itemKey] = itemEntry;

            toggle.onclick = function(event) {
                event.stopPropagation();
                if (!itemEntry.hasChildren) return;
                setProductNodeExpanded(
                    itemEntry,
                    itemEntry.childrenContainer.style.display === 'none'
                );
            };

            itemLink.onclick = function(event) {
                event.stopPropagation();
                selectProductRow(itemRow, 'Item', item.itemNo, '', true);
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                    'ProductOpenRequested',
                    ['Item', item.itemNo || '', '']
                );
            };
            itemLink.onkeydown = function(event) {
                if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    event.stopPropagation();
                    selectProductRow(itemRow, 'Item', item.itemNo, '', true);
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                        'ProductOpenRequested',
                        ['Item', item.itemNo || '', '']
                    );
                }
            };
            itemRow.onclick = function(event) {
                event.stopPropagation();
                selectProductRow(itemRow, 'Item', item.itemNo, '', true);
            };

            grid.appendChild(itemRow);

            (item.children || []).forEach(variant => {
                const variantRow = document.createElement('div');
                variantRow.className = 'si-product-row si-product-variant-row';

                const variantNameCell = document.createElement('div');
                variantNameCell.className = 'si-product-cell si-product-name-cell';
                const indent = document.createElement('span');
                indent.className = 'si-product-indent';
                variantNameCell.appendChild(indent);

                const variantIcon = document.createElement('span');
                variantIcon.className = 'si-product-type-icon';
                variantIcon.textContent = '◆';
                variantIcon.title = 'Варіант';
                variantNameCell.appendChild(variantIcon);

                const variantLink = document.createElement('span');
                variantLink.className = 'si-product-link';
                variantLink.textContent = variant.name || variant.variantCode || '';
                variantLink.title = 'Відкрити варіант: ' + (variant.name || variant.variantCode || '');
                variantLink.tabIndex = 0;
                variantLink.setAttribute('role', 'link');
                variantNameCell.appendChild(variantLink);
                variantRow.appendChild(variantNameCell);

                const blankUomCell = document.createElement('div');
                blankUomCell.className = 'si-product-cell';
                blankUomCell.textContent = '';
                variantRow.appendChild(blankUomCell);

                const variantKey = productNodeKey('Variant', item.itemNo, variant.variantCode);
                siProductNodeMap[variantKey] = {
                    row: variantRow,
                    nodeType: 'Variant',
                    itemNo: item.itemNo || '',
                    variantCode: variant.variantCode || '',
                    parentItemKey: itemKey
                };

                variantLink.onclick = function(event) {
                    event.stopPropagation();
                    selectProductRow(variantRow, 'Variant', item.itemNo, variant.variantCode, true);
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                        'ProductOpenRequested',
                        ['Variant', item.itemNo || '', variant.variantCode || '']
                    );
                };
                variantLink.onkeydown = function(event) {
                    if (event.key === 'Enter' || event.key === ' ') {
                        event.preventDefault();
                        event.stopPropagation();
                        selectProductRow(variantRow, 'Variant', item.itemNo, variant.variantCode, true);
                        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                            'ProductOpenRequested',
                            ['Variant', item.itemNo || '', variant.variantCode || '']
                        );
                    }
                };
                variantRow.onclick = function(event) {
                    event.stopPropagation();
                    selectProductRow(variantRow, 'Variant', item.itemNo, variant.variantCode, true);
                };

                childrenContainer.appendChild(variantRow);
            });

            grid.appendChild(childrenContainer);
        });
    }

    panel.appendChild(grid);
    root.appendChild(panel);
}
