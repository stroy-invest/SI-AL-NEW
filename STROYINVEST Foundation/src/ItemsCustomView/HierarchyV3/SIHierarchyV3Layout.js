// Isolated layout: both legacy renderers retain their event contracts.
function siV3InitializeLayout() {
    const host = document.getElementById('controlAddIn');
    if (!host) throw new Error("SI Hierarchy V3: controlAddIn host not available");
    host.innerHTML = '';
    const css = document.createElement('style');
    css.textContent = `
        html, body { height:100%; margin:0; overflow:hidden; }
        #controlAddIn { height:100%; min-height:0; overflow:hidden; }
        .si-adaptive-shell { display:flex; flex-direction:column; height:100%; min-height:0; overflow:hidden; }
        .si-adaptive-pane { min-height:0; overflow:hidden; flex:0 0 auto; }
        .si-adaptive-divider { height:9px; flex:0 0 9px; cursor:row-resize; background:#f3f2f1;
            border-top:1px solid #c8c6c4; border-bottom:1px solid #c8c6c4; box-sizing:border-box;
            display:flex; align-items:center; justify-content:center; touch-action:none; }
        .si-adaptive-divider::after { content:''; width:42px; height:3px; border-radius:2px; background:#8a8886; }
        .si-adaptive-divider:focus { outline:2px solid #0078d4; outline-offset:-2px; }
        .si-adaptive-pane > div { height:100%; min-height:0; }
        .si-v3-workspace {height:100%;width:100%;display:flex;overflow:hidden;min-height:0;}
        .si-v3-tree {min-width:0;position:relative;height:100%;overflow:hidden;}
        .si-v3-tree .si-adaptive-shell {height:100%;}
        .si-v3-side-divider {display:none;flex:0 0 7px;cursor:col-resize;background:#f3f2f1;border-left:1px solid #ddd;border-right:1px solid #ddd;}
        .si-v3-panel {display:none;flex:1;min-width:0;box-sizing:border-box;height:100%;overflow:auto;padding:12px 14px;font:13px 'Segoe UI',sans-serif;background:#fff;}
        .si-v3-open .si-v3-side-divider,.si-v3-open .si-v3-panel {display:block;}
        .si-v3-panel h2 {font-size:16px;margin:0 0 16px;}
        .si-v3-panel h3 {font-size:14px;margin:16px 0 8px;border-bottom:1px solid #ddd;padding-bottom:6px;}
        .si-v3-param-row {display:flex;justify-content:space-between;gap:12px;padding:6px 0;border-bottom:1px solid #eee;}
        .si-v3-param-row strong {text-align:right;white-space:nowrap;}
        .si-v3-narrow.si-v3-open .si-v3-tree {display:none;}
        .si-v3-narrow.si-v3-open .si-v3-side-divider {display:none;}
        .si-v3-narrow.si-v3-open .si-v3-panel {width:100%;}
        .si-v3-narrow.si-v3-open .si-v3-panel {position:relative;padding-top:48px;}
        .si-v3-back {display:none;background:#fff;border:1px solid #aaa;padding:5px 9px;margin-bottom:10px;cursor:pointer;}
        .si-v3-narrow .si-v3-back {display:block;}

    `;
    document.head.appendChild(css);
    const workspace=document.createElement('div'); workspace.className='si-v3-workspace';
    const treeArea=document.createElement('div'); treeArea.className='si-v3-tree';
    const sideDivider=document.createElement('div'); sideDivider.className='si-v3-side-divider';
    sideDivider.setAttribute('role','separator'); sideDivider.setAttribute('aria-label','Змінити ширину панелі параметрів');
    const panel=document.createElement('aside'); panel.className='si-v3-panel';
    panel.setAttribute('aria-label','Параметри та характеристики');
    const shell = document.createElement('div'); shell.className='si-adaptive-shell';
    const top = document.createElement('div'); top.className='si-adaptive-pane';
    const divider = document.createElement('div'); divider.className='si-adaptive-divider';
    divider.tabIndex=0; divider.setAttribute('role','separator');
    divider.setAttribute('aria-label','Змінити висоту панелей');
    divider.setAttribute('aria-orientation','horizontal');
    const bottom = document.createElement('div'); bottom.className='si-adaptive-pane';
    window.siAdaptiveCategoryRoot=document.createElement('div');
    window.siAdaptiveProductRoot=document.createElement('div');
    top.appendChild(window.siAdaptiveCategoryRoot); bottom.appendChild(window.siAdaptiveProductRoot);
    shell.append(top,divider,bottom); treeArea.append(shell);
    workspace.append(treeArea,sideDivider,panel); host.appendChild(workspace);
    let panelVisible=false; let panelFraction=0.32;
    function applyPanel() {
        const narrow=workspace.clientWidth<760;
        workspace.classList.toggle('si-v3-open',panelVisible);
        workspace.classList.toggle('si-v3-narrow',narrow);
        treeArea.style.flex=panelVisible&&!narrow?'0 0 '+((1-panelFraction)*100)+'%':'1 1 auto';
        size();
    }
    window.SetParametersVisible=function(value){panelVisible=!!value;applyPanel();};
    window.RenderParameters=function(json){
        let data;
        try {data=JSON.parse(json);}catch(e){data={title:'Помилка даних',sections:[]};}
        panel.replaceChildren();
        const back=document.createElement('button');back.className='si-v3-back';back.textContent='← До дерева';back.addEventListener('click',()=>{panelVisible=false;applyPanel();});panel.append(back);const heading=document.createElement('h2');heading.textContent=data.title||'Параметри та характеристики';panel.append(heading);
        for(const section of (Array.isArray(data.sections)?data.sections:[])){
            const block=document.createElement('section');const h=document.createElement('h3');h.textContent=section.caption||'';block.append(h);
            for(const r of (Array.isArray(section.rows)?section.rows:[])){
                const line=document.createElement('div');line.className='si-v3-param-row';
                const key=document.createElement('span');key.textContent=r.caption||'';
                const val=document.createElement('strong');val.textContent=(r.displayValue||'')+(r.unit?' '+r.unit:'');
                line.append(key,val);block.append(line);
            }panel.append(block);
        }
    };
    let resizingSide=false;
    sideDivider.addEventListener('pointerdown',e=>{if(workspace.classList.contains('si-v3-narrow'))return;resizingSide=true;sideDivider.setPointerCapture(e.pointerId);e.preventDefault();});
    sideDivider.addEventListener('pointermove',e=>{if(!resizingSide)return;const r=workspace.getBoundingClientRect();panelFraction=Math.min(.55,Math.max(.25,(r.right-e.clientX)/r.width));applyPanel();});
    sideDivider.addEventListener('pointerup',()=>resizingSide=false);
    sideDivider.addEventListener('pointercancel',()=>resizingSide=false);
    if(window.ResizeObserver){
        let lastWorkspaceWidth=-1;
        new ResizeObserver(entries=>{
            const w=entries[0].contentRect.width;
            if(Math.abs(w-lastWorkspaceWidth)>0.5){lastWorkspaceWidth=w;applyPanel();}
        }).observe(workspace);
    }
    window.RenderParameters(JSON.stringify({title:'Параметри та характеристики',sections:[]}));
    let ratio=0.40;
    function size() {
        const available=Math.max(0,shell.clientHeight-divider.offsetHeight);
        const minTop=Math.min(180,available*0.5);
        const minBottom=Math.min(120,available*0.5);
        const topHeight=Math.max(minTop,Math.min(available-minBottom,available*ratio));
        top.style.height=topHeight+'px'; bottom.style.height=Math.max(0,available-topHeight)+'px';
        divider.setAttribute('aria-valuenow',String(Math.round(topHeight/Math.max(1,available)*100)));
    }
    // Drag listeners are attached to window, not to the moving divider.
    // This avoids lost pointermove/pointerup when the divider is reflowed.
    let dragging=false;
    let dragStartY=0;
    let dragStartHeight=0;
    function dragMove(e) {
        if (!dragging) return;
        if (e.buttons === 0) { endDrag(); return; }
        const available=Math.max(0,shell.clientHeight-divider.offsetHeight);
        if (available<=0) return;
        const minTop=Math.min(180,available*0.5);
        const minBottom=Math.min(120,available*0.5);
        const nextHeight=Math.max(minTop,Math.min(available-minBottom,dragStartHeight+e.clientY-dragStartY));
        ratio=nextHeight/available;
        size();
        e.preventDefault();
    }
    function endDrag() {
        if (!dragging) return;
        dragging=false;
        window.removeEventListener('pointermove',dragMove,true);
        window.removeEventListener('pointerup',endDrag,true);
        window.removeEventListener('pointercancel',endDrag,true);
        window.removeEventListener('blur',endDrag);
        document.removeEventListener('visibilitychange',onVisibilityChange);
    }
    function onVisibilityChange(){ if(document.hidden) endDrag(); }
    divider.addEventListener('pointerdown',e=>{
        if (e.button!==0 || dragging) return;
        dragging=true;
        dragStartY=e.clientY;
        dragStartHeight=top.getBoundingClientRect().height;
        window.addEventListener('pointermove',dragMove,true);
        window.addEventListener('pointerup',endDrag,true);
        window.addEventListener('pointercancel',endDrag,true);
        window.addEventListener('blur',endDrag);
        document.addEventListener('visibilitychange',onVisibilityChange);
        e.preventDefault();
    });
    divider.addEventListener('keydown',e=>{
        if(e.key==='ArrowUp'||e.key==='ArrowDown'){
            ratio+=e.key==='ArrowDown'?0.03:-0.03; size(); e.preventDefault();
        }
    });
    if(window.ResizeObserver) new ResizeObserver(size).observe(shell);
    else window.addEventListener('resize',size);
    applyPanel();
}
