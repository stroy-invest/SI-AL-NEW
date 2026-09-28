function RenderVariants(variantsJson) {
    const data = JSON.parse(variantsJson || '[]');
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
        .si-var-panel { height: 128px; border: 1px solid #edebe9; background: #fff; box-sizing: border-box; overflow: auto; }
        .si-var-grid { min-width: 700px; }
        .si-var-header, .si-var-row { display: grid; grid-template-columns: 220px minmax(420px, 1fr); align-items: center; box-sizing: border-box; }
        .si-var-header { position: sticky; top: 0; z-index: 3; min-height: 34px; padding: 0 10px; border-bottom: 1px solid #d2d0ce; background: #fff; color: #605e5c; font-size: 13px; }
        .si-var-row { min-height: 32px; padding: 0 10px; border-bottom: 1px solid #edebe9; border-left: 3px solid transparent; cursor: default; user-select: none; }
        .si-var-row:hover { background: #f3f2f1; }
        .si-var-row.si-selected { background: #deecf9; border-left-color: #008575; }
        .si-var-cell { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; padding-right: 12px; }
        .si-var-link { color: #007e87; cursor: pointer; text-decoration: none; }
        .si-var-link:hover { text-decoration: underline; }
        .si-var-link:focus { outline: 1px dotted #605e5c; outline-offset: 2px; }
        .si-var-empty { min-height: 62px; display: flex; align-items: center; justify-content: center; color: #605e5c; }
    `;
    root.appendChild(style);

    const panel = document.createElement('div');
    panel.className = 'si-var-panel';
    const grid = document.createElement('div');
    grid.className = 'si-var-grid';
    const header = document.createElement('div');
    header.className = 'si-var-header';
    ['Code', 'Description'].forEach(caption => {
        const cell = document.createElement('div');
        cell.className = 'si-var-cell';
        cell.textContent = caption;
        header.appendChild(cell);
    });
    grid.appendChild(header);

    let selectedRow = null;

    function selectRow(row, itemNo, variantCode) {
        if (selectedRow) selectedRow.classList.remove('si-selected');
        row.classList.add('si-selected');
        selectedRow = row;
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('VariantSelected', [itemNo || '', variantCode || '']);
    }

    if (!data.length) {
        const empty = document.createElement('div');
        empty.className = 'si-var-empty';
        empty.textContent = '(Немає елементів, які можна відобразити в цьому поданні)';
        grid.appendChild(empty);
    } else {
        data.forEach(variant => {
            const row = document.createElement('div');
            row.className = 'si-var-row';

            const codeCell = document.createElement('div');
            codeCell.className = 'si-var-cell';
            codeCell.textContent = variant.code || '';
            codeCell.title = variant.code || '';
            row.appendChild(codeCell);

            const descCell = document.createElement('div');
            descCell.className = 'si-var-cell';
            const link = document.createElement('span');
            link.className = 'si-var-link';
            link.textContent = variant.description || variant.code || '';
            link.title = 'Відкрити варіант: ' + (variant.description || variant.code || '');
            link.tabIndex = 0;
            link.setAttribute('role', 'link');
            link.onclick = function (event) {
                event.stopPropagation();
                selectRow(row, variant.itemNo, variant.code);
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('VariantOpenRequested', [variant.itemNo || '', variant.code || '']);
            };
            link.onkeydown = function (event) {
                if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    event.stopPropagation();
                    selectRow(row, variant.itemNo, variant.code);
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('VariantOpenRequested', [variant.itemNo || '', variant.code || '']);
                }
            };
            descCell.appendChild(link);
            row.appendChild(descCell);

            row.onclick = function (event) {
                event.stopPropagation();
                selectRow(row, variant.itemNo, variant.code);
            };

            grid.appendChild(row);
        });
    }

    panel.appendChild(grid);
    root.appendChild(panel);
}
