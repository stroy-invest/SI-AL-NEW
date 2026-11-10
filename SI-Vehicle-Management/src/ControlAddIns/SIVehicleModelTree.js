(function () {
    'use strict';
    let nodes=[], expanded=new Set(), selected='', searchText='', mounted=false;
    const invoke=(name,args)=>Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(name,args);
    const make=(tag,cls,txt)=>{const x=document.createElement(tag);if(cls)x.className=cls;if(txt!==undefined)x.textContent=txt;return x;};
    function tokens(){return searchText.toLocaleLowerCase('uk-UA').trim().split(/\s+/).filter(Boolean);}
    function textOf(n){return ((n.label||'')+' '+(n.code||'')).toLocaleLowerCase('uk-UA');}
    function visible(n,terms,ancestors){
        const path=ancestors+' '+textOf(n);
        if(!terms.length)return true;
        if(terms.every(t=>path.includes(t)))return true;
        return (n.children||[]).some(c=>visible(c,terms,path));
    }
    function findNode(key,items=nodes){for(const n of items){if(n.key===key)return n;const child=findNode(key,n.children||[]);if(child)return child;}return null;}
    function draw(){
        const host=document.getElementById('si-vm-tree');if(!host)return;host.replaceChildren();
        const terms=tokens();
        const add=(n,depth,ancestors)=>{
            if(!visible(n,terms,ancestors))return;
            const row=make('div','vm-row'+(selected===n.key?' vm-selected':''));row.style.paddingLeft=(8+depth*22)+'px';
            const children=(n.children||[]), open=terms.length>0||expanded.has(n.key);
            const toggle=make('span','vm-toggle',children.length?(open?'▾':'▸'):'·');row.appendChild(toggle);
            toggle.addEventListener('click',e=>{e.stopPropagation();if(expanded.has(n.key))expanded.delete(n.key);else expanded.add(n.key);draw();});
            const name=make('span','vm-label'+(n.kind!=='model'?' vm-bold':''),n.label);
            row.appendChild(name);
            row.addEventListener('click',()=>{selected=n.key;if(n.kind==='model')invoke('ModelSelected',[n.brand,n.model]);else invoke('SelectionCleared',[]);draw();});
            if(n.kind==='model')name.addEventListener('click',e=>{e.stopPropagation();selected=n.key;invoke('ModelSelected',[n.brand,n.model]);invoke('ModelOpenRequested',[n.brand,n.model]);draw();});
            host.appendChild(row);
            if(open)children.forEach(c=>add(c,depth+1,ancestors+' '+textOf(n)));
        };
        nodes.forEach(n=>add(n,0,''));
    }
    function init(){if(mounted)return;const root=document.getElementById('controlAddIn');if(!root)return;mounted=true;root.innerHTML='';
        const css=make('style');css.textContent='.vm-toolbar{display:flex;flex-wrap:wrap;gap:6px;margin-bottom:10px}.vm-toolbar button{padding:5px 9px;background:transparent;color:inherit;border:1px solid #aab4bb;border-radius:3px;cursor:pointer}.vm-toolbar button:disabled{opacity:.45;cursor:default}.vm-search{display:flex;gap:7px;margin-bottom:10px}.vm-search input{flex:1;min-width:0;padding:7px;border:1px solid #aaa;background:transparent;color:inherit}.vm-row{display:flex;align-items:center;gap:7px;min-height:30px;border-bottom:1px solid #e3e3e3;cursor:pointer}.vm-row:hover{background:#e5f1f4;color:#111}.vm-selected{background:#cce9ef;color:#111}.vm-toggle{width:17px;flex-shrink:0}.vm-label{flex:0 0 auto;max-width:calc(100% - 28px);overflow-wrap:anywhere}.vm-label:hover{text-decoration:underline}.vm-bold{font-weight:700}';root.appendChild(css);
        const toolbar=make('div','vm-toolbar');const buttons=[['Додати',()=>act('AddRequested')],['Видалити',()=>act('DeleteRequested')],['Розгорнути все',()=>{walk(nodes,n=>expanded.add(n.key));draw();}],['Згорнути все',()=>{expanded.clear();draw();}]];
        buttons.forEach(([label,fn])=>{const b=make('button','',label);b.type='button';b.addEventListener('click',fn);toolbar.appendChild(b);});root.appendChild(toolbar);
        const search=make('div','vm-search'),input=make('input');input.placeholder='Пошук типу, бренду або моделі';input.addEventListener('input',()=>{searchText=input.value;draw();});search.appendChild(input);
        const clear=make('button','','Очистити');clear.type='button';clear.addEventListener('click',()=>{input.value='';searchText='';draw();input.focus();});search.appendChild(clear);root.appendChild(search);
        root.appendChild(make('div',''));root.lastChild.id='si-vm-tree';draw();
    }
    function walk(items,fn){items.forEach(n=>{fn(n);walk(n.children||[],fn);});}
    function act(event){const n=findNode(selected);if(!n)return;invoke(event,[n.kind,n.type||'',n.brand||'',n.model||'']);}
    window.siVehicleTreeRender=function(json){try{nodes=JSON.parse(json||'[]');}catch(e){nodes=[];}init();if(!expanded.size)walk(nodes,n=>{if(n.kind!=='model')expanded.add(n.key);});draw();};
})();