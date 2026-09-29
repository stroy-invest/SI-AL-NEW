(function () {
    function esc(v) { return String(v || ''); }

    window.RenderTree = function (treeJson) {
        var root = document.getElementById('controlAddIn');
        if (!root) return;
        root.innerHTML = '';
        var data = [];
        try { data = JSON.parse(treeJson || '[]'); } catch (e) { data = []; }

        var style = document.createElement('style');
        style.textContent = `
          *{box-sizing:border-box} body{margin:0;font-family:"Segoe UI",sans-serif;font-size:14px;color:#323130}
          .bar{display:flex;justify-content:space-between;align-items:center;padding:8px 10px;border-bottom:1px solid #edebe9}
          .title{font-weight:600}.buttons{display:flex;gap:8px}.btn{border:1px solid #8a8886;background:white;padding:5px 12px;cursor:pointer}
          .tree{padding:6px 8px;overflow:auto;height:430px}.node{min-height:30px}.row{display:flex;align-items:center;min-height:30px;border-bottom:1px solid #f3f2f1}
          .toggle{width:24px;text-align:center;cursor:pointer;user-select:none}.toggle.empty{cursor:default}.check{margin:0 10px 0 2px}.name{flex:1}.uom{width:120px;color:#605e5c}.children{display:none}.node.open>.children{display:block}
        `;
        root.appendChild(style);

        var bar=document.createElement('div'); bar.className='bar';
        var title=document.createElement('div'); title.className='title'; title.textContent='Категорії товарів'; bar.appendChild(title);
        var buttons=document.createElement('div'); buttons.className='buttons';
        var expand=document.createElement('button'); expand.className='btn'; expand.textContent='Розгорнути все';
        var collapse=document.createElement('button'); collapse.className='btn'; collapse.textContent='Згорнути все';
        buttons.appendChild(expand); buttons.appendChild(collapse); bar.appendChild(buttons); root.appendChild(bar);
        var tree=document.createElement('div'); tree.className='tree'; root.appendChild(tree);

        function makeNode(n, level) {
            var wrap=document.createElement('div'); wrap.className='node';
            var row=document.createElement('div'); row.className='row'; row.style.paddingLeft=(level*22)+'px';
            var children=Array.isArray(n.children)?n.children:[];
            var tog=document.createElement('span'); tog.className='toggle'+(children.length?'':' empty'); tog.textContent=children.length?'▸':''; row.appendChild(tog);
            var cb=document.createElement('input'); cb.type='checkbox'; cb.className='check'; cb.checked=!!n.selected;
            cb.addEventListener('change',function(){ Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('CategoryToggled',[esc(n.code),cb.checked]); }); row.appendChild(cb);
            var name=document.createElement('span'); name.className='name'; name.textContent=n.name||n.code||''; row.appendChild(name);
            var uom=document.createElement('span'); uom.className='uom'; uom.textContent=n.baseUomCode||''; row.appendChild(uom);
            wrap.appendChild(row);
            var childBox=document.createElement('div'); childBox.className='children'; children.forEach(function(c){childBox.appendChild(makeNode(c,level+1));}); wrap.appendChild(childBox);
            if(children.length) tog.addEventListener('click',function(){wrap.classList.toggle('open');tog.textContent=wrap.classList.contains('open')?'▾':'▸';});
            return wrap;
        }
        data.forEach(function(n){tree.appendChild(makeNode(n,0));});
        expand.onclick=function(){root.querySelectorAll('.node').forEach(function(n){if(n.querySelector(':scope > .children > .node')) n.classList.add('open');});root.querySelectorAll('.toggle:not(.empty)').forEach(function(t){t.textContent='▾';});};
        collapse.onclick=function(){root.querySelectorAll('.node').forEach(function(n){n.classList.remove('open');});root.querySelectorAll('.toggle:not(.empty)').forEach(function(t){t.textContent='▸';});};
    };
})();
