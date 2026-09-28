let siProductConfigTreeBranches = [];

function ExpandAll() {
    siProductConfigTreeBranches.forEach(branch => {
        branch.kids.style.display = 'block';
        branch.toggle.textContent = '▼';
    });
}

function CollapseAll() {
    siProductConfigTreeBranches.forEach(branch => {
        branch.kids.style.display = 'none';
        branch.toggle.textContent = '▶';
    });
}

function sortConfigurationTreeAlphabetically(nodes) {
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
            sortConfigurationTreeAlphabetically(node.children);
        }
    });

    return nodes;
}

function RenderTree(treeJson) {
    const data = sortConfigurationTreeAlphabetically(JSON.parse(treeJson || '[]'));
    const root = document.getElementById('controlAddIn');
    root.innerHTML = '';
    root.style.fontFamily = 'Segoe UI, sans-serif';
    root.style.fontSize = '14px';
    root.style.height = '100%';
    root.style.boxSizing = 'border-box';

    const panel = document.createElement('div');
    panel.style.height = '100%';
    panel.style.display = 'flex';
    panel.style.flexDirection = 'column';
    panel.style.borderTop = '1px solid #d2d2d2';

    const header = document.createElement('div');
    header.style.display = 'grid';
    header.style.gridTemplateColumns = 'minmax(390px, 2.4fr) minmax(165px, .95fr) minmax(180px, 1fr) minmax(120px, .75fr) minmax(170px, 1fr) minmax(145px, .9fr) minmax(170px, 1fr)';
    header.style.fontWeight = '600';
    header.style.padding = '8px 8px';
    header.style.borderBottom = '1px solid #d2d2d2';
    header.style.background = '#fafafa';
    ['Назва конфігурації','Статус','Статус готовності проєкції','Затвердив','Дата й час затвердження','Дата створення','Дата останньої модифікації'].forEach(t => {
        const c=document.createElement('div'); c.textContent=t; c.style.paddingRight='10px'; header.appendChild(c);
    });

    const body = document.createElement('div');
    body.style.flex = '1 1 auto'; body.style.overflow = 'auto';
    panel.appendChild(header); panel.appendChild(body); root.appendChild(panel);

    let selectedRow = null;
    const branchNodes = [];
    siProductConfigTreeBranches = branchNodes;
    let contextMenu = null;

    function closeContextMenu() {
        if (contextMenu && contextMenu.parentNode) contextMenu.parentNode.removeChild(contextMenu);
        contextMenu = null;
    }

    // Dismiss the context menu without requiring a command selection.
    // `blur` is essential in BC because a click elsewhere on the page moves
    // focus outside the Control Add-In iframe/document.
    document.addEventListener('pointerdown', function (event) {
        if (contextMenu && !contextMenu.contains(event.target))
            closeContextMenu();
    });
    window.addEventListener('blur', closeContextMenu);
    window.addEventListener('keydown', function (event) {
        if (event.key === 'Escape')
            closeContextMenu();
    });

    function addContextCommand(menu, caption, enabled, handler) {
        const item = document.createElement('div');
        item.textContent = caption;
        item.style.padding = '7px 24px 7px 12px';
        item.style.whiteSpace = 'nowrap';
        item.style.userSelect = 'none';
        item.style.color = enabled ? '#323130' : '#a19f9d';
        item.style.cursor = enabled ? 'pointer' : 'default';
        if (enabled) {
            item.onmouseenter = () => item.style.background = '#f3f2f1';
            item.onmouseleave = () => item.style.background = '';
            item.onclick = (e) => {
                e.stopPropagation();
                closeContextMenu();
                handler();
            };
        }
        menu.appendChild(item);
    }

    function showContextMenu(e, node, row) {
        e.preventDefault();
        e.stopPropagation();
        closeContextMenu();

        if (!node.configNo) return;

        if (selectedRow) {
            selectedRow.style.background = '';
            selectedRow.style.borderLeft = '';
        }
        selectedRow = row;
        row.style.background = '#e5f3f8';
        row.style.borderLeft = '3px solid #008575';
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeSelected', [node.type, node.configNo]);

        const menu = document.createElement('div');
        contextMenu = menu;
        menu.style.position = 'fixed';
        menu.style.left = e.clientX + 'px';
        menu.style.top = e.clientY + 'px';
        menu.style.zIndex = '2147483647';
        menu.style.minWidth = '170px';
        menu.style.background = '#ffffff';
        menu.style.border = '1px solid #c8c6c4';
        menu.style.boxShadow = '0 4px 12px rgba(0,0,0,.18)';
        menu.style.padding = '4px 0';
        menu.style.fontFamily = 'Segoe UI, sans-serif';
        menu.style.fontSize = '14px';

        addContextCommand(menu, 'Переглянути', true, () =>
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeCommand', ['view', node.configNo])
        );
        addContextCommand(menu, 'Видалити', node.canDeleteProjection === true, () =>
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeCommand', ['delete', node.configNo])
        );

        document.body.appendChild(menu);

        const rect = menu.getBoundingClientRect();
        if (rect.right > window.innerWidth)
            menu.style.left = Math.max(0, window.innerWidth - rect.width - 4) + 'px';
        if (rect.bottom > window.innerHeight)
            menu.style.top = Math.max(0, window.innerHeight - rect.height - 4) + 'px';
    }


    function cell(text) {
        const c=document.createElement('div'); c.textContent=text || ''; c.style.paddingRight='10px'; c.style.overflow='hidden'; c.style.textOverflow='ellipsis'; c.style.whiteSpace='nowrap'; return c;
    }

    function makeNode(node, level) {
        const wrap=document.createElement('div');
        const row=document.createElement('div');
        row.style.display='grid';
        row.style.gridTemplateColumns='minmax(390px, 2.4fr) minmax(165px, .95fr) minmax(180px, 1fr) minmax(120px, .75fr) minmax(170px, 1fr) minmax(145px, .9fr) minmax(170px, 1fr)';
        row.style.minHeight='32px'; row.style.alignItems='center'; row.style.borderBottom='1px solid #edebe9'; row.style.cursor='pointer'; row.style.padding='0 8px';

        const name=document.createElement('div'); name.style.display='flex'; name.style.alignItems='center'; name.style.minWidth='0'; name.style.paddingLeft=(level*28)+'px';
        const hasChildren=node.children && node.children.length>0;
        const toggle=document.createElement('span'); toggle.style.width='20px'; toggle.style.flex='0 0 20px'; toggle.style.textAlign='center'; toggle.textContent=hasChildren?'▼':(node.type==='family'?'•':''); name.appendChild(toggle);
        const icon=document.createElement('span'); icon.style.width='22px'; icon.style.flex='0 0 22px'; icon.style.textAlign='center'; icon.style.marginRight='5px';
        icon.textContent=node.type==='family'?'▾':(node.type==='item'?'▣':'◆');
        icon.title=node.type==='family'?'Сімейство':(node.type==='item'?'Конфігурація товару':'Конфігурація варіанта'); name.appendChild(icon);
        const label=document.createElement('span'); label.textContent=node.name || ''; label.style.overflow='hidden'; label.style.textOverflow='ellipsis'; label.style.whiteSpace='nowrap';
        if(node.type==='family') label.style.fontWeight='700'; else if(node.type==='item') label.style.fontWeight='600';

        // Configuration nodes behave like links, consistent with ItemCustomView:
        // clicking the name opens the configuration card, while clicking elsewhere
        // on the row only selects the node.
        if(node.configNo) {
            label.style.color='#007e87';
            label.style.cursor='pointer';
            label.style.textDecoration='none';
            label.title='Відкрити картку конфігурації: ' + (node.name || node.configNo || '');
            label.tabIndex=0;
            label.setAttribute('role','link');

            const openConfigurationCard=(e)=>{
                e.stopPropagation();
                if(selectedRow){selectedRow.style.background='';selectedRow.style.borderLeft='';}
                selectedRow=row;
                row.style.background='#e5f3f8';
                row.style.borderLeft='3px solid #008575';
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeSelected',[node.type,node.configNo]);
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeOpen',[node.configNo]);
            };

            label.onclick=openConfigurationCard;
            label.onmouseenter=()=>{label.style.textDecoration='underline';};
            label.onmouseleave=()=>{label.style.textDecoration='none';};
            label.onfocus=()=>{label.style.outline='1px dotted #605e5c';label.style.outlineOffset='2px';};
            label.onblur=()=>{label.style.outline='';label.style.outlineOffset='';};
            label.onkeydown=(e)=>{
                if(e.key==='Enter' || e.key===' ') {
                    e.preventDefault();
                    openConfigurationCard(e);
                }
            };
        }

        name.appendChild(label); row.appendChild(name);
        row.appendChild(cell(node.status)); row.appendChild(cell(node.readinessStatus)); row.appendChild(cell(node.approvedBy)); row.appendChild(cell(node.approvedAt)); row.appendChild(cell(node.createdAt)); row.appendChild(cell(node.modifiedAt));

        const kids=document.createElement('div'); kids.style.display='block';
        if(hasChildren) node.children.forEach(ch => kids.appendChild(makeNode(ch, level+1)));
        if(hasChildren) branchNodes.push({toggle:toggle,kids:kids});

        row.onmouseenter=()=>{ if(selectedRow!==row) row.style.background='#f3f2f1'; };
        row.onmouseleave=()=>{ if(selectedRow!==row) row.style.background=''; };
        row.onclick=(e)=>{
            e.stopPropagation();
            if(selectedRow){selectedRow.style.background='';selectedRow.style.borderLeft='';}
            selectedRow=row; row.style.background='#e5f3f8'; row.style.borderLeft='3px solid #008575';
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeSelected',[node.type,node.configNo || '']);
            if(hasChildren && (e.target===toggle || node.type==='family')) { const open=kids.style.display==='none'; kids.style.display=open?'block':'none'; toggle.textContent=open?'▼':'▶'; }
        };
        row.ondblclick=(e)=>{e.stopPropagation(); if(node.configNo) Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeOpen',[node.configNo]);};
        row.oncontextmenu=(e)=>showContextMenu(e,node,row);
        toggle.onclick=(e)=>{e.stopPropagation(); if(!hasChildren)return; const open=kids.style.display==='none'; kids.style.display=open?'block':'none'; toggle.textContent=open?'▼':'▶';};

        wrap.appendChild(row); wrap.appendChild(kids); return wrap;
    }
    data.forEach(n=>body.appendChild(makeNode(n,0)));
}
