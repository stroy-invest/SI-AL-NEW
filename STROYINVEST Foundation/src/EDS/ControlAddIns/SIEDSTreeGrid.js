let siEdsSelectedRow = null;

function Render(treeJson) {
    const model = JSON.parse(treeJson || '{}');
    const root = document.getElementById('controlAddIn');
    root.innerHTML = '';
    root.style.height = '100%';
    root.style.boxSizing = 'border-box';
    root.style.fontFamily = '"Segoe UI", sans-serif';
    root.style.fontSize = '13px';
    root.style.background = '#fff';
    root.style.color = '#323130';

    const columns = model.columns || [];
    const nodes = model.nodes || [];
    const template = columns.map(c => c.width || 'minmax(120px,1fr)').join(' ');

    const style = document.createElement('style');
    style.textContent = `
      .si-eds-panel{height:100%;min-height:350px;border:1px solid #edebe9;overflow:auto;box-sizing:border-box;background:#fff}
      .si-eds-grid{min-width:${Math.max(900, columns.length * 120)}px}
      .si-eds-header,.si-eds-row{display:grid;grid-template-columns:${template};align-items:center;box-sizing:border-box}
      .si-eds-header{position:sticky;top:0;z-index:5;min-height:36px;background:#fff;border-bottom:1px solid #c8c6c4;color:#605e5c;font-weight:600}
      .si-eds-cell{padding:6px 8px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;border-right:1px solid #f3f2f1}
      .si-eds-row{min-height:32px;border-bottom:1px solid #edebe9;border-left:3px solid transparent;cursor:default;user-select:none}
      .si-eds-row:hover{background:#f3f2f1}.si-eds-row.si-eds-selected{background:#deecf9;border-left-color:#008575}
      .si-eds-treecell{display:flex;align-items:center;min-width:0}.si-eds-toggle{flex:0 0 20px;width:20px;text-align:center;cursor:pointer}
      .si-eds-indent{display:inline-block;flex:0 0 auto}.si-eds-node-label{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
      .si-eds-parent .si-eds-node-label{font-weight:600}.si-eds-parent{background:#faf9f8}
      .si-eds-empty{padding:24px;color:#605e5c;text-align:center}
      .si-eds-yes{font-weight:600;color:#107c10}
    `;
    root.appendChild(style);

    const panel = document.createElement('div'); panel.className = 'si-eds-panel';
    const grid = document.createElement('div'); grid.className = 'si-eds-grid';
    const header = document.createElement('div'); header.className = 'si-eds-header';
    columns.forEach(c => { const x=document.createElement('div'); x.className='si-eds-cell'; x.textContent=c.caption||''; x.title=c.caption||''; header.appendChild(x); });
    grid.appendChild(header);

    function select(row,node,notify){
      if(siEdsSelectedRow) siEdsSelectedRow.classList.remove('si-eds-selected');
      row.classList.add('si-eds-selected'); siEdsSelectedRow=row;
      if(notify) Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeSelected',[node.nodeType||'',node.key1||'',node.key2||'',node.key3||'',node.key4||'']);
    }

    function addNode(node, level, host){
      const row=document.createElement('div'); row.className='si-eds-row'+((node.children||[]).length?' si-eds-parent':'');
      const cells=node.cells||{};
      columns.forEach((c,idx)=>{
        const cell=document.createElement('div'); cell.className='si-eds-cell'+(idx===0?' si-eds-treecell':'');
        let value=cells[c.key];
        if(idx===0){
          const indent=document.createElement('span'); indent.className='si-eds-indent'; indent.style.width=(level*24)+'px'; cell.appendChild(indent);
          const toggle=document.createElement('span'); toggle.className='si-eds-toggle'; toggle.textContent=(node.children||[]).length?'▼':''; cell.appendChild(toggle);
          const label=document.createElement('span'); label.className='si-eds-node-label'; label.textContent=(value===undefined||value===null)?'':String(value); label.title=label.textContent; cell.appendChild(label);
          if((node.children||[]).length){
            toggle.onclick=e=>{e.stopPropagation(); const hidden=children.style.display==='none'; children.style.display=hidden?'block':'none'; toggle.textContent=hidden?'▼':'▶';};
          }
        } else {
          if(value===true){cell.textContent='✓';cell.classList.add('si-eds-yes');}
          else if(value===false) cell.textContent='';
          else cell.textContent=(value===undefined||value===null)?'':String(value);
          cell.title=cell.textContent;
        }
        row.appendChild(cell);
      });
      row.onclick=()=>select(row,node,true);
      row.ondblclick=()=>{select(row,node,true);Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeOpenRequested',[node.nodeType||'',node.key1||'',node.key2||'',node.key3||'',node.key4||'']);};
      host.appendChild(row);
      const children=document.createElement('div'); children.style.display='block'; host.appendChild(children);
      (node.children||[]).forEach(ch=>addNode(ch,level+1,children));
    }

    if(!nodes.length){const e=document.createElement('div');e.className='si-eds-empty';e.textContent='(Немає даних)';grid.appendChild(e);} else nodes.forEach(n=>addNode(n,0,grid));
    panel.appendChild(grid); root.appendChild(panel);
}
