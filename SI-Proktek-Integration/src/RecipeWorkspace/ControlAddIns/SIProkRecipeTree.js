(function () {
    let model = [];
    let expanded = new Set();
    let selectedKey = '';

    function esc(v) {
        return String(v == null ? '' : v).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
    }
    function key(n) { return n.type + ':' + n.id; }
    function root() { return document.getElementById('controlAddIn'); }

    function render() {
        const r = root();
        r.innerHTML = '';
        r.style.fontFamily = 'Segoe UI, sans-serif';
        r.style.fontSize = '14px';
        r.style.color = '#323130';
        r.style.background = '#fff';
        r.style.height = '100%';
        r.style.overflow = 'auto';
        const style = document.createElement('style');
        style.textContent = `
          .rw-row{display:flex;align-items:center;min-height:34px;border-bottom:1px solid #edebe9;cursor:pointer;padding:0 8px;box-sizing:border-box}
          .rw-row:hover{background:#f3f2f1}.rw-sel{background:#deecf9!important}.rw-toggle{width:24px;text-align:center;user-select:none}
          .rw-name{width:58%;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.rw-name a{color:#005a9e;text-decoration:none}
          .rw-code{flex:1;min-width:300px;color:#605e5c;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.rw-status{width:120px}.rw-type{width:140px;color:#605e5c}.rw-child{padding-left:34px}
          .rw-head{display:flex;font-weight:600;border-bottom:1px solid #c8c6c4;padding:8px}.rw-head .rw-toggle{visibility:hidden}
        `;
        r.appendChild(style);
        const h=document.createElement('div'); h.className='rw-head';
        h.innerHTML='<span class="rw-toggle"></span><span class="rw-name">Рецептура / продукт</span><span class="rw-code">Код</span><span class="rw-status">Статус</span><span class="rw-type">Тип</span>';
        r.appendChild(h);
        model.forEach(n => addNode(r,n,false));
    }

    function addNode(r,n,isChild){
        const k=key(n), has=n.children && n.children.length>0;
        const row=document.createElement('div'); row.className='rw-row'+(isChild?' rw-child':'')+(selectedKey===k?' rw-sel':'');
        const toggle=document.createElement('span'); toggle.className='rw-toggle'; toggle.textContent=has?(expanded.has(k)?'▾':'▸'):'';
        toggle.onclick=e=>{e.stopPropagation(); if(!has)return; expanded.has(k)?expanded.delete(k):expanded.add(k); render();};
        const name=document.createElement('span'); name.className='rw-name';
        const a=document.createElement('a'); a.href='#'; a.textContent=n.name||n.id; a.onclick=e=>{e.preventDefault();e.stopPropagation();Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeOpened',[n.type,String(n.id)]);}; name.appendChild(a);
        const code=document.createElement('span'); code.className='rw-code'; code.innerHTML=esc(n.code||'');
        const status=document.createElement('span'); status.className='rw-status'; status.innerHTML=esc(n.status||'');
        const type=document.createElement('span'); type.className='rw-type'; type.innerHTML=esc(n.typeCaption||'');
        row.append(toggle,name,code,status,type);
        row.onclick=()=>{selectedKey=k; Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('NodeSelected',[n.type,String(n.id)]); render();};
        r.appendChild(row);
        if(has && expanded.has(k)) n.children.forEach(c=>addNode(r,c,true));
    }

    window.RenderTree=function(json){ try{model=JSON.parse(json||'[]');}catch(e){model=[];} render(); };
    window.ExpandAll=function(){ model.forEach(n=>{if(n.children&&n.children.length)expanded.add(key(n));}); render(); };
    window.CollapseAll=function(){ expanded.clear(); render(); };
})();
