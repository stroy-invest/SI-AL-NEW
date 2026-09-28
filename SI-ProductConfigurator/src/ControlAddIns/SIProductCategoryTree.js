function RenderTree(treeJson) {
    const data = JSON.parse(treeJson);
    const root = document.getElementById('controlAddIn');

    root.innerHTML = '';

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
    panel.style.height = '290px';
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

    const title = document.createElement('span');
    title.textContent = 'Категорії товарів';

    const buttons = document.createElement('div');
    buttons.style.display = 'flex';
    buttons.style.gap = '6px';

    const expandBtn = document.createElement('button');
    expandBtn.textContent = 'Розгорнути все';

    const collapseBtn = document.createElement('button');
    collapseBtn.textContent = 'Згорнути все';

    [expandBtn, collapseBtn].forEach(btn => {
        btn.style.border = '1px solid #c8c8c8';
        btn.style.backgroundColor = '#ffffff';
        btn.style.padding = '5px 10px';
        btn.style.cursor = 'pointer';
        btn.style.fontFamily = 'Segoe UI, sans-serif';
        btn.style.fontSize = '14px';
        btn.style.borderRadius = '2px';
    });

    buttons.appendChild(expandBtn);
    buttons.appendChild(collapseBtn);

    header.appendChild(title);
    header.appendChild(buttons);

    const body = document.createElement('div');
    body.style.padding = '6px 4px 8px 4px';
    body.style.overflowY = 'auto';
    body.style.flex = '1 1 auto';

    panel.appendChild(header);
    panel.appendChild(body);
    root.appendChild(panel);

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

        const hasChildren = node.children && node.children.length > 0;

        const toggle = document.createElement('span');
        toggle.textContent = hasChildren ? '▶' : '•';
        toggle.style.display = 'inline-block';
        toggle.style.width = '16px';
        toggle.style.textAlign = 'center';
        toggle.style.flex = '0 0 16px';

        const label = document.createElement('span');
        label.textContent = node.name;
        label.style.overflow = 'hidden';
        label.style.textOverflow = 'ellipsis';

        row.appendChild(toggle);
        row.appendChild(label);

        const childrenContainer = document.createElement('div');
        childrenContainer.style.display = 'none';

        if (hasChildren) {
            node.children.forEach(child => {
                childrenContainer.appendChild(createNode(child, level + 1));
            });
        }

        treeNodes.push({
            hasChildren,
            toggle,
            childrenContainer
        });

        row.onmouseenter = function () {
            if (window.selectedTreeRow !== row) {
                row.style.backgroundColor = '#f3f2f1';
            }
        };

        row.onmouseleave = function () {
            if (window.selectedTreeRow !== row) {
                row.style.backgroundColor = '';
            }
        };

        row.onclick = function (event) {
            event.stopPropagation();

            if (window.selectedTreeRow) {
                window.selectedTreeRow.style.backgroundColor = '';
                window.selectedTreeRow.style.fontWeight = 'normal';
                window.selectedTreeRow.style.borderLeft = '';
            }

            row.style.backgroundColor = '#e5f3f8';
            row.style.fontWeight = '600';
            row.style.borderLeft = '3px solid #008575';
            window.selectedTreeRow = row;

            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeSelected', [node.code]);

            if (hasChildren) {
                const collapsed = childrenContainer.style.display === 'none';
                childrenContainer.style.display = collapsed ? 'block' : 'none';
                toggle.textContent = collapsed ? '▼' : '▶';
            }
        };

        wrapper.appendChild(row);
        wrapper.appendChild(childrenContainer);

        return wrapper;
    }

    data.forEach(node => body.appendChild(createNode(node, 0)));

    expandBtn.onclick = function (event) {
        event.stopPropagation();

        treeNodes.forEach(item => {
            if (item.hasChildren) {
                item.childrenContainer.style.display = 'block';
                item.toggle.textContent = '▼';
            }
        });
    };

    collapseBtn.onclick = function (event) {
        event.stopPropagation();

        treeNodes.forEach(item => {
            if (item.hasChildren) {
                item.childrenContainer.style.display = 'none';
                item.toggle.textContent = '▶';
            }
        });
    };
}