window.SIProkFactWorkspace = (() => {
    let root, main, panel;
    function el(tag, text, cls) {
        const node = document.createElement(tag);
        if (text !== undefined) node.textContent = text;
        if (cls) node.className = cls;
        return node;
    }
    function rows(target, values, batch) {
        const list = el('dl', undefined, batch ? 'batch' : 'order');
        values.forEach((r, i) => {
            const item = el('div', undefined, batch && i === 4 ? 'output' : 'pair');
            item.append(el('dt', r.caption), el('dd', r.value));
            list.append(item);
        });
        target.append(list);
    }
    function init() {
        root = document.getElementById('controlAddIn');
        root.replaceChildren();
        const css = el('style');
        css.textContent = `
            html,body {margin:0;font:13px 'Segoe UI',sans-serif;color:#242424;}
            * {box-sizing:border-box;} [hidden]{display:none!important;}
            .workspace {display:flex;align-items:flex-start;gap:16px;}
            .section-divider {border:0;border-top:1px solid #aaa;margin:18px 0 16px;}
            main {flex:1;min-width:0;} aside {flex:0 0 34%;min-width:0;border-left:1px solid #ccc;padding-left:14px;}
            h2 {font-size:14px;margin:0 0 8px;padding-bottom:6px;border-bottom:1px solid #aaa;}
            dl {margin:0 0 14px;} .batch {display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px 16px;}
            dt {color:#555;} dd {margin:3px 0 0;font-weight:600;overflow-wrap:anywhere;}
            .output {grid-column:1/-1;} .output dd {font-size:24px;}
            .order .pair {padding:4px 0;border-bottom:1px solid #eee;}
            .order .pair dd {margin:2px 0 0;}
            .grid {overflow-x:auto;} table {border-collapse:collapse;width:100%;font:inherit;}
            th,td {padding:5px 8px;border-bottom:1px solid #ddd;text-align:right;white-space:nowrap;}
            th {background:#f3f2f1;font-weight:600;} th:first-child,td:first-child {text-align:left;white-space:normal;}
            @media(max-width:700px){.workspace{flex-direction:column;} main,aside{width:100%;} aside{border-left:0;padding-left:0;}}
        `;
        document.head.append(css);
        const workspace = el('div', undefined, 'workspace');
        main = el('main'); panel = el('aside'); panel.id = 'order-panel';
        workspace.append(main,panel); root.append(workspace, el('hr', undefined, 'section-divider'));
    }
    function render(payload) {
        const data = JSON.parse(payload);
        main.replaceChildren(el('h2','Інформація про партію'));
        rows(main,data.batch,true);
        main.append(el('hr', undefined, 'section-divider'), el('h2','План/факт витрат матеріалів'));
        const grid = el('div',undefined,'grid'), table = el('table'), head = el('thead'), hr = el('tr');
        ['Матеріал','Од. виміру','План, кг','Факт, кг','Відхилення, кг'].forEach(v=>hr.append(el('th',v)));
        head.append(hr); table.append(head);
        const body = el('tbody');
        data.materials.forEach(m=>{const tr=el('tr'); [m.name,m.unit,m.plan,m.actual,m.variance].forEach(v=>tr.append(el('td',v)));body.append(tr);});
        table.append(body); grid.append(table); main.append(grid);
        if (!data.materials.length) main.append(el('p','Немає матеріалів для цього факту.'));
        panel.replaceChildren(el('h2','Загальна інформація про замовлення'));
        rows(panel,data.order,false);
    }
    return {init,render};
})();
function RenderFact(PayloadJson) { window.SIProkFactWorkspace.render(PayloadJson); }
