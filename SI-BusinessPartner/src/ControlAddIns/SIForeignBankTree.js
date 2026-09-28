let siForeignBankData = [];
let siForeignBankSelectedRow = null;
let siForeignBankNodeMap = {};
let siForeignBankExpandedCountries = new Set();
let siForeignBankExpandedBeforeSearch = null;
let siForeignBankSearchText = '';
let siForeignBankInitialized = false;

function normalizeSearchValue(value) {
    return (value || '').toString().toLocaleLowerCase();
}

function countryKey(countryCode, countryName) {
    return (countryCode || '') + '|' + (countryName || '');
}

function InitializeForeignBankTree() {
    if (siForeignBankInitialized)
        return;

    const root = document.getElementById('controlAddIn');
    if (!root)
        return;

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
        .si-bank-panel {
            height: 100%;
            min-height: 345px;
            border: 1px solid #edebe9;
            background: #fff;
            box-sizing: border-box;
            display: flex;
            flex-direction: column;
        }
        .si-bank-toolbar {
            flex: 0 0 auto;
            display: flex;
            gap: 8px;
            align-items: center;
            padding: 8px 10px;
            border-bottom: 1px solid #d2d0ce;
            background: #faf9f8;
        }
        .si-bank-search {
            flex: 1 1 auto;
            min-width: 180px;
            height: 32px;
            padding: 4px 9px;
            border: 1px solid #8a8886;
            border-radius: 2px;
            box-sizing: border-box;
            font-family: inherit;
            font-size: 14px;
        }
        .si-bank-search:focus {
            outline: 2px solid #0078d4;
            outline-offset: -1px;
        }
        .si-bank-button {
            flex: 0 0 auto;
            min-height: 32px;
            padding: 4px 12px;
            border: 1px solid #8a8886;
            border-radius: 2px;
            background: #fff;
            color: #323130;
            font-family: inherit;
            font-size: 13px;
            cursor: pointer;
        }
        .si-bank-button:hover { background: #f3f2f1; }
        .si-bank-button:disabled {
            color: #a19f9d;
            cursor: default;
            background: #f3f2f1;
        }
        .si-bank-tree-host {
            position: relative;
            flex: 1 1 auto;
            min-height: 0;
            overflow: auto;
        }
        .si-bank-grid { min-width: 820px; }
        .si-bank-header,
        .si-bank-row {
            display: grid;
            grid-template-columns: 150px minmax(360px, 1fr) 190px 80px;
            align-items: center;
            box-sizing: border-box;
        }
        .si-bank-header {
            position: sticky;
            top: 0;
            z-index: 4;
            min-height: 34px;
            padding: 0 10px;
            border-bottom: 1px solid #d2d0ce;
            background: #fff;
            color: #605e5c;
            font-size: 13px;
            font-weight: 600;
        }
        .si-bank-country-row {
            min-height: 34px;
            display: flex;
            align-items: center;
            padding: 0 10px;
            border-bottom: 1px solid #d2d0ce;
            background: #f3f2f1;
            cursor: pointer;
            user-select: none;
        }
        .si-bank-country-row:hover { background: #edebe9; }
        .si-bank-country-cell {
            display: flex;
            align-items: center;
            min-width: 0;
            font-weight: 600;
        }
        .si-bank-toggle {
            flex: 0 0 22px;
            width: 22px;
            margin-right: 4px;
            text-align: center;
            font-size: 15px;
        }
        .si-bank-country-label {
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .si-bank-row {
            min-height: 31px;
            padding: 0 10px 0 36px;
            border-bottom: 1px solid #edebe9;
            border-left: 3px solid transparent;
            cursor: default;
            user-select: none;
            background: #fff;
        }
        .si-bank-row:hover { background: #f3f2f1; }
        .si-bank-row.si-bank-selected {
            background: #deecf9;
            border-left-color: #008575;
        }
        .si-bank-row:focus {
            outline: 1px dotted #605e5c;
            outline-offset: -2px;
        }
        .si-bank-row.si-bank-inactive {
            color: #8a8886;
            opacity: 0.65;
        }
        .si-bank-cell {
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            padding-right: 12px;
        }
        .si-bank-swift {
            font-family: Consolas, 'Courier New', monospace;
            font-weight: 600;
        }
        .si-bank-active { text-align: center; }
        .si-bank-empty,
        .si-bank-loading {
            min-height: 120px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #605e5c;
        }
        .si-bank-loading {
            position: absolute;
            inset: 0;
            z-index: 10;
            min-height: 100%;
            background: rgba(255,255,255,0.88);
            font-weight: 600;
        }
    `;
    root.appendChild(style);

    const panel = document.createElement('div');
    panel.className = 'si-bank-panel';

    const toolbar = document.createElement('div');
    toolbar.className = 'si-bank-toolbar';

    const search = document.createElement('input');
    search.id = 'si-bank-search';
    search.className = 'si-bank-search';
    search.type = 'search';
    search.placeholder = 'Пошук за SWIFT або назвою банку...';
    search.setAttribute('aria-label', 'Пошук за SWIFT або назвою банку');
    search.oninput = function() {
        const newValue = search.value || '';
        const wasSearching = normalizeSearchValue(siForeignBankSearchText).trim() !== '';
        const isSearching = normalizeSearchValue(newValue).trim() !== '';

        if (!wasSearching && isSearching)
            siForeignBankExpandedBeforeSearch = new Set(siForeignBankExpandedCountries);

        siForeignBankSearchText = newValue;

        if (wasSearching && !isSearching && siForeignBankExpandedBeforeSearch) {
            siForeignBankExpandedCountries = new Set(siForeignBankExpandedBeforeSearch);
            siForeignBankExpandedBeforeSearch = null;
        }

        renderTree();
    };
    toolbar.appendChild(search);

    const expandButton = document.createElement('button');
    expandButton.id = 'si-bank-expand-all';
    expandButton.className = 'si-bank-button';
    expandButton.type = 'button';
    expandButton.textContent = 'Розгорнути все';
    expandButton.onclick = function() { ExpandAll(); };
    toolbar.appendChild(expandButton);

    const collapseButton = document.createElement('button');
    collapseButton.id = 'si-bank-collapse-all';
    collapseButton.className = 'si-bank-button';
    collapseButton.type = 'button';
    collapseButton.textContent = 'Згорнути все';
    collapseButton.onclick = function() { CollapseAll(); };
    toolbar.appendChild(collapseButton);

    panel.appendChild(toolbar);

    const treeHost = document.createElement('div');
    treeHost.id = 'si-bank-tree-host';
    treeHost.className = 'si-bank-tree-host';
    panel.appendChild(treeHost);

    root.appendChild(panel);
    siForeignBankInitialized = true;

    SetLoading(true);
}

function SetLoading(isLoading) {
    InitializeForeignBankTree();

    const treeHost = document.getElementById('si-bank-tree-host');
    if (!treeHost)
        return;

    let loading = document.getElementById('si-bank-loading');

    if (isLoading) {
        if (!loading) {
            loading = document.createElement('div');
            loading.id = 'si-bank-loading';
            loading.className = 'si-bank-loading';
            loading.textContent = 'Завантаження банків...';
            treeHost.appendChild(loading);
        }
    } else if (loading) {
        loading.remove();
    }

    const search = document.getElementById('si-bank-search');
    const expandButton = document.getElementById('si-bank-expand-all');
    const collapseButton = document.getElementById('si-bank-collapse-all');

    if (search) search.disabled = !!isLoading;
    if (expandButton) expandButton.disabled = !!isLoading;
    if (collapseButton) collapseButton.disabled = !!isLoading;
}

function setCountryExpanded(entry, expanded) {
    if (!entry) return;

    entry.children.style.display = expanded ? 'block' : 'none';
    entry.toggle.textContent = expanded ? '▼' : '▶';

    if (expanded)
        siForeignBankExpandedCountries.add(entry.key);
    else
        siForeignBankExpandedCountries.delete(entry.key);
}

function selectBankRow(row, bankId, notifyAl) {
    if (siForeignBankSelectedRow)
        siForeignBankSelectedRow.classList.remove('si-bank-selected');

    row.classList.add('si-bank-selected');
    siForeignBankSelectedRow = row;

    if (notifyAl) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
            'BankSelected',
            [bankId || '']
        );
    }
}

function SelectBank(bankId) {
    const entry = siForeignBankNodeMap[bankId || ''];
    if (!entry) return;

    if (entry.countryEntry)
        setCountryExpanded(entry.countryEntry, true);

    selectBankRow(entry.row, bankId, false);
    entry.row.scrollIntoView({ block: 'nearest' });
}

function ExpandAll() {
    Object.values(siForeignBankNodeMap)
        .filter(x => x && x.nodeType === 'Country')
        .forEach(x => setCountryExpanded(x, true));
}

function CollapseAll() {
    Object.values(siForeignBankNodeMap)
        .filter(x => x && x.nodeType === 'Country')
        .forEach(x => setCountryExpanded(x, false));
}

function groupBanks(data) {
    const groups = new Map();

    (data || []).forEach(bank => {
        const code = bank.countryCode || '';
        const name = bank.countryName || code || '(Без країни)';
        const key = countryKey(code, name);

        if (!groups.has(key)) {
            groups.set(key, {
                key: key,
                countryCode: code,
                countryName: name,
                banks: []
            });
        }

        groups.get(key).banks.push(bank);
    });

    const result = Array.from(groups.values());

    result.sort((a, b) =>
        (a.countryName || '').localeCompare(
            b.countryName || '',
            undefined,
            { sensitivity: 'base' }
        )
    );

    result.forEach(group => {
        group.banks.sort((a, b) =>
            (a.name || '').localeCompare(
                b.name || '',
                undefined,
                { sensitivity: 'base' }
            ) ||
            (a.swift || '').localeCompare(
                b.swift || '',
                undefined,
                { sensitivity: 'base' }
            )
        );
    });

    return result;
}

function getFilteredGroups() {
    const groups = groupBanks(siForeignBankData);
    const search = normalizeSearchValue(siForeignBankSearchText).trim();

    if (!search)
        return groups;

    return groups
        .map(group => ({
            key: group.key,
            countryCode: group.countryCode,
            countryName: group.countryName,
            banks: group.banks.filter(bank =>
                normalizeSearchValue(bank.swift).includes(search) ||
                normalizeSearchValue(bank.name).includes(search)
            )
        }))
        .filter(group => group.banks.length > 0);
}

function createCell(text, className, title) {
    const cell = document.createElement('div');
    cell.className = 'si-bank-cell' + (className ? ' ' + className : '');
    cell.textContent = text || '';
    cell.title = title || text || '';
    return cell;
}

function renderTree() {
    InitializeForeignBankTree();

    const treeHost = document.getElementById('si-bank-tree-host');
    if (!treeHost) return;

    siForeignBankNodeMap = {};
    siForeignBankSelectedRow = null;
    treeHost.innerHTML = '';

    const groups = getFilteredGroups();
    const fragment = document.createDocumentFragment();

    const grid = document.createElement('div');
    grid.className = 'si-bank-grid';

    const header = document.createElement('div');
    header.className = 'si-bank-header';
    ['SWIFT', 'Name', 'City', 'Active'].forEach(caption => {
        const cell = document.createElement('div');
        cell.className = 'si-bank-cell';
        cell.textContent = caption;
        header.appendChild(cell);
    });
    grid.appendChild(header);

    if (!groups.length) {
        const empty = document.createElement('div');
        empty.className = 'si-bank-empty';
        empty.textContent = siForeignBankSearchText
            ? '(Нічого не знайдено)'
            : '(Довідник іноземних банків порожній)';
        grid.appendChild(empty);
        fragment.appendChild(grid);
        treeHost.appendChild(fragment);
        return;
    }

    const searchActive = normalizeSearchValue(siForeignBankSearchText).trim() !== '';

    groups.forEach(group => {
        const countryRow = document.createElement('div');
        countryRow.className = 'si-bank-country-row';

        const countryCell = document.createElement('div');
        countryCell.className = 'si-bank-country-cell';

        const toggle = document.createElement('span');
        toggle.className = 'si-bank-toggle';

        const countryLabel = document.createElement('span');
        countryLabel.className = 'si-bank-country-label';
        countryLabel.textContent =
            (group.countryName || group.countryCode || '(Без країни)') +
            ' (' + group.banks.length + ')';
        countryLabel.title = group.countryCode
            ? (group.countryName + ' [' + group.countryCode + ']')
            : group.countryName;

        countryCell.appendChild(toggle);
        countryCell.appendChild(countryLabel);
        countryRow.appendChild(countryCell);

        const children = document.createElement('div');
        children.className = 'si-bank-country-children';

        const countryEntry = {
            key: group.key,
            nodeType: 'Country',
            row: countryRow,
            toggle: toggle,
            children: children
        };

        siForeignBankNodeMap['COUNTRY|' + group.key] = countryEntry;

        const shouldExpand = searchActive || siForeignBankExpandedCountries.has(group.key);
        toggle.textContent = shouldExpand ? '▼' : '▶';
        children.style.display = shouldExpand ? 'block' : 'none';

        if (shouldExpand)
            siForeignBankExpandedCountries.add(group.key);

        countryRow.onclick = function(event) {
            event.stopPropagation();
            setCountryExpanded(
                countryEntry,
                countryEntry.children.style.display === 'none'
            );
        };

        grid.appendChild(countryRow);

        group.banks.forEach(bank => {
            const bankRow = document.createElement('div');
            bankRow.className = 'si-bank-row';
            if (!bank.isActive)
                bankRow.classList.add('si-bank-inactive');

            bankRow.appendChild(createCell(bank.swift || '', 'si-bank-swift'));
            bankRow.appendChild(createCell(bank.name || '', 'si-bank-name'));
            bankRow.appendChild(createCell(bank.city || '', 'si-bank-city'));
            bankRow.appendChild(createCell(
                bank.isActive ? '✓' : '—',
                'si-bank-active',
                bank.isActive ? 'Active' : 'Inactive'
            ));

            const bankEntry = {
                nodeType: 'Bank',
                row: bankRow,
                bankId: bank.id || '',
                countryEntry: countryEntry
            };
            siForeignBankNodeMap[bank.id || ''] = bankEntry;

            bankRow.onclick = function(event) {
                event.stopPropagation();
                selectBankRow(bankRow, bank.id || '', true);
            };

            bankRow.ondblclick = function(event) {
                event.preventDefault();
                event.stopPropagation();
                selectBankRow(bankRow, bank.id || '', true);
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                    'BankOpenRequested',
                    [bank.id || '']
                );
            };

            bankRow.tabIndex = 0;
            bankRow.onkeydown = function(event) {
                if (event.key === 'Enter') {
                    event.preventDefault();
                    selectBankRow(bankRow, bank.id || '', true);
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                        'BankOpenRequested',
                        [bank.id || '']
                    );
                }
            };

            children.appendChild(bankRow);
        });

        grid.appendChild(children);
    });

    fragment.appendChild(grid);
    treeHost.appendChild(fragment);
}

function RenderBanks(bankJson) {
    InitializeForeignBankTree();

    try {
        siForeignBankData = JSON.parse(bankJson || '[]');
    } catch (error) {
        siForeignBankData = [];
        const treeHost = document.getElementById('si-bank-tree-host');
        if (treeHost) {
            treeHost.innerHTML = '';
            const errorBox = document.createElement('div');
            errorBox.className = 'si-bank-empty';
            errorBox.textContent = 'Не вдалося прочитати дані довідника банків.';
            treeHost.appendChild(errorBox);
        }
        SetLoading(false);
        return;
    }

    siForeignBankSelectedRow = null;
    siForeignBankNodeMap = {};

    renderTree();
    SetLoading(false);
}
