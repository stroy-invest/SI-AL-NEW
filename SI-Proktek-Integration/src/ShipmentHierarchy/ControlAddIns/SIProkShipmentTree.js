(function () {
  'use strict';
  var host, expanded = Object.create(null), lastData = {groups: []}, defaultExpanded = true;
  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = String(text);
    return node;
  }
  function cell(text, cls) { return el('div', 'sh-cell ' + (cls || ''), text === null || text === undefined ? '' : text); }
  function num(v) { return Number(v || 0).toLocaleString('uk-UA', {maximumFractionDigits: 3}); }
  function notify(type, id) {
    if (window.Microsoft && Microsoft.Dynamics && Microsoft.Dynamics.NAV)
      Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('RowOpened', [type, id]);
  }
  function render() {
    if (!host) return;
    host.replaceChildren();
    var style = el('style');
    style.textContent = '.sh-wrap{font-family:Segoe UI,Arial,sans-serif;font-size:13px;color:#252423;overflow:auto;height:100%;background:#fff}.sh-grid{display:grid;grid-template-columns:minmax(125px,1.15fr) minmax(150px,1.25fr) 100px 110px 100px 100px 115px 125px 150px;min-width:1000px;align-items:center}.sh-cell{padding:9px 8px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;border-bottom:1px solid #edebe9}.sh-head{position:sticky;top:0;background:#f3f2f1;font-weight:600;z-index:2}.sh-parent{background:#f8f8f8;font-weight:600;cursor:pointer}.sh-parent:hover,.sh-child:hover{background:#edf4fb}.sh-child{cursor:default}.sh-child .sh-cell:first-child{padding-left:32px}.sh-toggle{margin-right:7px;display:inline-block;width:12px}.sh-muted{color:#666}.sh-empty{padding:22px;color:#666}.sh-help{padding:7px 10px;color:#666;border-bottom:1px solid #ddd;display:flex;align-items:center;gap:8px;flex-wrap:wrap}.sh-help-text{margin-right:auto}.sh-btn{font:inherit;padding:5px 10px;border:1px solid #8a8886;border-radius:3px;background:#fff;color:#252423;cursor:pointer}.sh-btn:hover{background:#edebe9}.sh-btn:focus-visible{outline:2px solid #0078d4;outline-offset:2px}';
    host.appendChild(style);
    var wrap = el('div','sh-wrap');
    var toolbar = el('div','sh-help');
    toolbar.appendChild(el('span','sh-help-text','Натисніть на заявку, щоб розгорнути/згорнути партії. Подвійний клік відкриває картку.'));
    function addExpandButton(label, expand) {
      var btn = el('button','sh-btn',label);
      btn.type = 'button';
      btn.addEventListener('click',function(){
        defaultExpanded = expand;
        expanded = Object.create(null);
        render();
      });
      toolbar.appendChild(btn);
    }
    addExpandButton('Розгорнути все',true);
    addExpandButton('Згорнути все',false);
    wrap.appendChild(toolbar);
    var head = el('div','sh-grid sh-head');
    ['Заявка / відвантаження','Бетон','Замовлено, м³','Відвантажено, м³','Залишок, м³','Статус','Міксер','Водій','Дата/час'].forEach(function(t){head.appendChild(cell(t));});
    wrap.appendChild(head);
    if (!lastData.groups || !lastData.groups.length) wrap.appendChild(el('div','sh-empty','За заданими фільтрами відвантажень не знайдено.'));
    (lastData.groups || []).forEach(function(g){
      var key = String(g.groupKey), isOpen = Object.prototype.hasOwnProperty.call(expanded,key) ? expanded[key] : defaultExpanded;
      var parent = el('div','sh-grid sh-parent');
      var first = cell(''); first.appendChild(el('span','sh-toggle',isOpen ? '▾' : '▸')); first.appendChild(document.createTextNode(g.request || 'Без заявки'));
      parent.appendChild(first);
      [g.product,num(g.ordered),num(g.shipped),num(g.remaining),g.status,'','',''].forEach(function(v){parent.appendChild(cell(v));});
      parent.addEventListener('click',function(){expanded[key] = !isOpen;render();});
      parent.addEventListener('dblclick',function(e){e.stopPropagation();if(g.hasRequest)notify('request',g.requestEntryNo);});
      wrap.appendChild(parent);
      if (isOpen) (g.children || []).forEach(function(s){
        var child = el('div','sh-grid sh-child');
        ['Партія №'+s.batchNo,'','',num(s.quantity),'',s.status,s.mixer,s.driver,s.dateTime].forEach(function(v){child.appendChild(cell(v));});
        child.addEventListener('dblclick',function(){notify('shipment',s.entryNo);});
        wrap.appendChild(child);
      });
    });
    host.appendChild(wrap);
  }
  window.SIProkShipmentTree = {
    init: function(){host=document.getElementById('controlAddIn') || document.body; render();},
    render: function(json){try {lastData=JSON.parse(json);render();}catch(e){if(host)host.textContent='Помилка відображення дерева: '+e.message;}}
  };
  window.RenderTree = function(json){window.SIProkShipmentTree.render(json);};
}());
