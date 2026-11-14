// Isolated layout: both legacy renderers retain their event contracts.
function siAdaptiveInitializeLayout() {
    const host = document.getElementById('controlAddIn');
    if (!host) throw new Error('SI Adaptive Hierarchy: controlAddIn host not found');
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
        .si-adaptive-divider.si-adaptive-dragging { background:#deecf9; }
        .si-adaptive-divider:focus { outline:2px solid #0078d4; outline-offset:-2px; }
        .si-adaptive-pane > div { height:100%; min-height:0; }
    `;
    document.head.appendChild(css);
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
    shell.append(top,divider,bottom); host.appendChild(shell);
    let ratio=0.70;
    function size() {
        const available=Math.max(0,shell.clientHeight-divider.offsetHeight);
        const minTop=Math.min(180,available*0.5);
        const minBottom=Math.min(120,available*0.5);
        const topHeight=Math.max(minTop,Math.min(available-minBottom,available*ratio));
        top.style.height=topHeight+'px'; bottom.style.height=Math.max(0,available-topHeight)+'px';
        divider.setAttribute('aria-valuenow',String(Math.round(topHeight/Math.max(1,available)*100)));
    }
    // Track the drag on window: the separator itself moves while dragging.
    // Use client coordinates from the actual pointer event, and always release
    // on pointerup/cancel/blur so mouse movement cannot continue resizing.
    let activePointerId = null;
    function setRatioFromPointer(e) {
        const r = shell.getBoundingClientRect();
        const available = Math.max(1, shell.clientHeight - divider.offsetHeight);
        const minTop = Math.min(180, available * 0.5);
        const minBottom = Math.min(120, available * 0.5);
        const desired = e.clientY - r.top - divider.offsetHeight / 2;
        ratio = Math.max(minTop, Math.min(available - minBottom, desired)) / available;
        size();
    }
    function stopDrag() {
        if (activePointerId === null) return;
        activePointerId = null;
        window.removeEventListener('pointermove', onDragMove, true);
        window.removeEventListener('pointerup', onDragEnd, true);
        window.removeEventListener('pointercancel', onDragEnd, true);
        window.removeEventListener('blur', stopDrag);
        divider.classList.remove('si-adaptive-dragging');
    }
    function onDragMove(e) {
        if (e.pointerId !== activePointerId) return;
        if (e.pointerType === 'mouse' && (e.buttons & 1) === 0) {
            stopDrag();
            return;
        }
        setRatioFromPointer(e);
        e.preventDefault();
    }
    function onDragEnd(e) {
        if (e.pointerId === activePointerId) stopDrag();
    }
    divider.addEventListener('pointerdown', e => {
        if (activePointerId !== null || (e.pointerType === 'mouse' && e.button !== 0)) return;
        activePointerId = e.pointerId;
        divider.classList.add('si-adaptive-dragging');
        window.addEventListener('pointermove', onDragMove, true);
        window.addEventListener('pointerup', onDragEnd, true);
        window.addEventListener('pointercancel', onDragEnd, true);
        window.addEventListener('blur', stopDrag);
        setRatioFromPointer(e);
        e.preventDefault();
    });
    divider.addEventListener('keydown',e=>{
        if(e.key==='ArrowUp'||e.key==='ArrowDown'){
            ratio+=e.key==='ArrowDown'?0.03:-0.03; size(); e.preventDefault();
        }
    });
    if(window.ResizeObserver) new ResizeObserver(size).observe(shell);
    else window.addEventListener('resize',size);
    size();
}
