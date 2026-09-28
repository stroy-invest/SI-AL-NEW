function RenderItems(itemsJson) {
    const data = JSON.parse(itemsJson || '[]');
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
        .si-item-panel { height: 168px; border: 1px solid #edebe9; background: #fff; box-sizing: border-box; overflow: auto; }
        .si-item-grid { min-width: 850px; }
        .si-item-header, .si-item-row { display: grid; grid-template-columns: minmax(360px, 1fr) 180px 250px 220px; align-items: center; box-sizing: border-box; }
        .si-item-header { position: sticky; top: 0; z-index: 3; min-height: 34px; padding: 0 10px; border-bottom: 1px solid #d2d0ce; background: #fff; color: #605e5c; font-size: 13px; }
        .si-item-row { min-height: 32px; padding: 0 10px; border-bottom: 1px solid #edebe9; border-left: 3px solid transparent; cursor: default; user-select: none; }
        .si-item-row:hover { background: #f3f2f1; }
        .si-item-row.si-selected { background: #deecf9; border-left-color: #008575; }
        .si-item-cell { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; padding-right: 12px; }
        .si-item-link { color: #007e87; cursor: pointer; text-decoration: none; }
        .si-item-link:hover { text-decoration: underline; }
        .si-item-link:focus { outline: 1px dotted #605e5c; outline-offset: 2px; }
        .si-item-empty { min-height: 70px; display: flex; align-items: center; justify-content: center; color: #605e5c; }
    `;
    root.appendChild(style);

    const panel = document.createElement('div');
    panel.className = 'si-item-panel';
    const grid = document.createElement('div');
    grid.className = 'si-item-grid';
    const header = document.createElement('div');
    header.className = 'si-item-header';
    ['Description', 'Base Unit of Measure', 'No.', 'Item Category Code'].forEach(caption => {
        const cell = document.createElement('div');
        cell.className = 'si-item-cell';
        cell.textContent = caption;
        header.appendChild(cell);
    });
    grid.appendChild(header);

    let selectedRow = null;

    function selectRow(row, itemNo) {
        if (selectedRow) selectedRow.classList.remove('si-selected');
        row.classList.add('si-selected');
        selectedRow = row;
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ItemSelected', [itemNo || '']);
    }

    if (!data.length) {
        const empty = document.createElement('div');
        empty.className = 'si-item-empty';
        empty.textContent = '(Немає елементів, які можна відобразити в цьому поданні)';
        grid.appendChild(empty);
    } else {
        data.forEach(item => {
            const row = document.createElement('div');
            row.className = 'si-item-row';

            const descCell = document.createElement('div');
            descCell.className = 'si-item-cell';
            const link = document.createElement('span');
            link.className = 'si-item-link';
            link.textContent = item.description || item.no || '';
            link.title = 'Відкрити картку товару: ' + (item.description || item.no || '');
            link.tabIndex = 0;
            link.setAttribute('role', 'link');
            link.onclick = function (event) {
                event.stopPropagation();
                selectRow(row, item.no);
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ItemOpenRequested', [item.no || '']);
            };
            link.onkeydown = function (event) {
                if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    event.stopPropagation();
                    selectRow(row, item.no);
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ItemOpenRequested', [item.no || '']);
                }
            };
            descCell.appendChild(link);
            row.appendChild(descCell);

            [item.baseUomCode, item.no, item.categoryCode].forEach(value => {
                const cell = document.createElement('div');
                cell.className = 'si-item-cell';
                cell.textContent = value || '';
                cell.title = value || '';
                row.appendChild(cell);
            });

            row.onclick = function (event) {
                event.stopPropagation();
                selectRow(row, item.no);
            };

            grid.appendChild(row);
        });
    }

    panel.appendChild(grid);
    root.appendChild(panel);
}
