function ClearTree() {
    const root = document.getElementById('controlAddIn');

    if (root) {
        root.innerHTML = '';
    }

    window.selectedClassificationTreeRow = null;
}

function RenderTree(treeJson) {
    const data = JSON.parse(treeJson || '[]');
    const root = document.getElementById('controlAddIn');

    ClearTree();

    root.style.fontFamily = 'Segoe UI, sans-serif';
    root.style.fontSize = '14px';
    root.style.textAlign = 'left';
    root.style.height = '100%';
    root.style.boxSizing = 'border-box';

    const panel = document.createElement('div');
    panel.style.border = '1px solid #d2d2d2';
    panel.style.borderRadius = '2px';
    panel.style.backgroundColor = '#ffffff';
    panel.style.boxSizing = 'border-box';
    panel.style.height = '100%';
    panel.style.minHeight = '400px';
    panel.style.display = 'flex';
    panel.style.flexDirection = 'column';

    const header = document.createElement('div');
    header.style.fontWeight = '600';
    header.style.fontSize = '15px';
    header.style.padding = '8px 10px';
    header.style.borderBottom = '1px solid #e1e1e1';
    header.style.backgroundColor = '#fafafa';
    header.style.display = 'flex';
    header.style.justifyContent = 'space-between';
    header.style.alignItems = 'center';
    header.style.gap = '8px';

    const title = document.createElement('span');
    title.textContent = 'Дерево класифікації';

    const buttons = document.createElement('div');
    buttons.style.display = 'flex';
    buttons.style.gap = '6px';

    const expandBtn = document.createElement('button');
    expandBtn.textContent = 'Розгорнути все';

    const collapseBtn = document.createElement('button');
    collapseBtn.textContent = 'Згорнути все';

    [expandBtn, collapseBtn].forEach(button => {
        button.type = 'button';
        button.style.border = '1px solid #c8c8c8';
        button.style.backgroundColor = '#ffffff';
        button.style.padding = '5px 10px';
        button.style.cursor = 'pointer';
        button.style.fontFamily = 'Segoe UI, sans-serif';
        button.style.fontSize = '14px';
        button.style.borderRadius = '2px';
    });

    buttons.appendChild(expandBtn);
    buttons.appendChild(collapseBtn);

    header.appendChild(title);
    header.appendChild(buttons);

    const body = document.createElement('div');
    body.style.padding = '6px 4px 8px 4px';
    body.style.overflow = 'auto';
    body.style.flex = '1 1 auto';

    panel.appendChild(header);
    panel.appendChild(body);
    root.appendChild(panel);

    if (!Array.isArray(data) || data.length === 0) {
        const emptyText = document.createElement('div');
        emptyText.textContent = 'Для вибраної системи класифікації вузлів не знайдено.';
        emptyText.style.padding = '12px';
        emptyText.style.color = '#605e5c';
        body.appendChild(emptyText);
        return;
    }

    const treeNodes = [];

    function createNode(node, level) {
        const wrapper = document.createElement('div');

        const row = document.createElement('div');
        row.style.cursor = 'pointer';
        row.style.padding = '4px 8px';
        row.style.paddingLeft = (8 + level * 16) + 'px';
        row.style.userSelect = 'none';
        row.style.whiteSpace = 'nowrap';
        row.style.display = 'flex';
        row.style.alignItems = 'center';
        row.style.gap = '4px';
        row.style.minHeight = '24px';
        row.style.borderRadius = '2px';

        const hasChildren =
            Array.isArray(node.children) &&
            node.children.length > 0;

        const toggle = document.createElement('span');
        toggle.textContent = hasChildren ? '▶' : '•';
        toggle.style.display = 'inline-block';
        toggle.style.width = '16px';
        toggle.style.textAlign = 'center';
        toggle.style.flex = '0 0 16px';

        const label = document.createElement('span');
        label.textContent = node.name;
        label.title = node.name;
        label.style.overflow = 'hidden';
        label.style.textOverflow = 'ellipsis';

        row.appendChild(toggle);
        row.appendChild(label);

        const childrenContainer = document.createElement('div');
        childrenContainer.style.display = 'none';

        if (hasChildren) {
            node.children.forEach(child => {
                childrenContainer.appendChild(
                    createNode(child, level + 1)
                );
            });
        }

        treeNodes.push({
            hasChildren,
            toggle,
            childrenContainer
        });

        row.addEventListener('mouseenter', function () {
            if (window.selectedClassificationTreeRow !== row) {
                row.style.backgroundColor = '#f3f2f1';
            }
        });

        row.addEventListener('mouseleave', function () {
            if (window.selectedClassificationTreeRow !== row) {
                row.style.backgroundColor = '';
            }
        });

        row.addEventListener('click', function (event) {
            event.stopPropagation();

            if (window.selectedClassificationTreeRow) {
                window.selectedClassificationTreeRow.style.backgroundColor = '';
                window.selectedClassificationTreeRow.style.fontWeight = 'normal';
                window.selectedClassificationTreeRow.style.borderLeft = '';
            }

            row.style.backgroundColor = '#e5f3f8';
            row.style.fontWeight = '600';
            row.style.borderLeft = '3px solid #008575';
            window.selectedClassificationTreeRow = row;

            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                'NodeSelected',
                [node.systemCode, node.code]
            );

            if (hasChildren) {
                const isCollapsed =
                    childrenContainer.style.display === 'none';

                childrenContainer.style.display =
                    isCollapsed ? 'block' : 'none';

                toggle.textContent =
                    isCollapsed ? '▼' : '▶';
            }
        });

        wrapper.appendChild(row);
        wrapper.appendChild(childrenContainer);

        return wrapper;
    }

    data.forEach(node => {
        body.appendChild(createNode(node, 0));
    });

    expandBtn.addEventListener('click', function (event) {
        event.stopPropagation();

        treeNodes.forEach(item => {
            if (item.hasChildren) {
                item.childrenContainer.style.display = 'block';
                item.toggle.textContent = '▼';
            }
        });
    });

    collapseBtn.addEventListener('click', function (event) {
        event.stopPropagation();

        treeNodes.forEach(item => {
            if (item.hasChildren) {
                item.childrenContainer.style.display = 'none';
                item.toggle.textContent = '▶';
            }
        });
    });
}
