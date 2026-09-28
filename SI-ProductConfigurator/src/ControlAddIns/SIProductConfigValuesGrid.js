(function () {
    'use strict';
    var host, rows = [], showNewRow = false;

    function ensureHost() {
        if (host) return host;
        host = document.getElementById('controlAddIn') || document.body;
        host.style.fontFamily = 'Segoe UI, Arial, sans-serif';
        host.style.fontSize = '13px';
        host.style.boxSizing = 'border-box';
        host.style.height = '100%';
        host.style.overflow = 'hidden';
        return host;
    }
    function invoke(name, args) { Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(name, args || []); }
    function el(tag, cls, text) {
        var n = document.createElement(tag);
        if (cls) n.className = cls;
        if (text !== undefined && text !== null) n.textContent = text;
        return n;
    }
    function button(text, title, handler, compact) {
        var b = el('button', compact ? 'si-btn si-btn-compact' : 'si-btn', text);
        b.type = 'button'; b.title = title || text;
        b.addEventListener('click', function (e) { e.preventDefault(); e.stopPropagation(); handler(); });
        return b;
    }
    function inputFor(row) {
        var input, fieldName = '', value = '', type = row.valueType || '';
        if (type === 'Reference') {
            var rwrap = el('div', 'si-lookup-wrap');
            rwrap.appendChild(el('div', 'si-readonly si-controlled', row.displayValue || ''));
            rwrap.appendChild(button('⋯', 'Вибрати значення', function () {
                invoke('ReferenceValueLookupRequested', [row.parameterCode]);
            }, true));
            return rwrap;
        }
        if (type === 'Controlled Value') {
            var wrap = el('div', 'si-lookup-wrap');
            wrap.appendChild(el('div', 'si-readonly si-controlled', row.displayValue || row.parameterValueCode || ''));
            wrap.appendChild(button('⋯', 'Вибрати допустиме значення', function () {
                invoke('ControlledValueLookupRequested', [row.parameterCode]);
            }, true));
            return wrap;
        }
        if (type === 'Decimal') { fieldName = 'Decimal Value'; value = row.decimalValue || ''; input = el('input','si-input'); input.inputMode='decimal'; }
        else if (type === 'Integer') { fieldName = 'Integer Value'; value = row.integerValue || ''; input = el('input','si-input'); input.inputMode='numeric'; }
        else if (type === 'Text') { fieldName = 'Text Value'; value = row.textValue || ''; input = el('input','si-input'); }
        else if (type === 'Boolean') {
            fieldName = 'Boolean Value'; input = el('input','si-checkbox'); input.type='checkbox'; input.checked=!!row.booleanValue;
            input.addEventListener('change', function () { invoke('ValueChanged',[row.parameterCode,fieldName,input.checked ? 'true':'false']); });
            return input;
        }
        else if (type === 'Date') { fieldName = 'Date Value'; value = row.dateValue || ''; input = el('input','si-input'); input.type='date'; }
        else return el('div','si-readonly','');
        input.value = value;
        input.addEventListener('change', function () { invoke('ValueChanged',[row.parameterCode,fieldName,input.value]); });
        return input;
    }
    function render() {
        var root = ensureHost(); root.innerHTML = '';
        var style=document.createElement('style');
        style.textContent=''
          +'.si-wrap{height:100%;display:flex;flex-direction:column;border:1px solid #d6dce2;background:#fff;box-sizing:border-box}'
          +'.si-toolbar{height:34px;display:flex;align-items:center;padding:4px 7px;border-bottom:1px solid #d6dce2;box-sizing:border-box;background:#fafbfc}'
          +'.si-btn{border:0;background:transparent;color:#2b579a;cursor:pointer;padding:4px 7px;font:inherit}.si-btn:hover{background:#eef3f8}'
          +'.si-btn-compact{font-size:18px;line-height:18px;padding:0 6px;color:#333}.si-grid-wrap{flex:1;overflow:auto}'
          +'.si-grid{width:100%;border-collapse:collapse;table-layout:fixed}.si-grid th{font-weight:400;color:#3d4a57;text-align:left;background:#f7f8fa;border-bottom:1px solid #d6dce2;padding:5px 7px;white-space:nowrap}'
          +'.si-grid td{border-bottom:1px solid #e5e8eb;padding:3px 7px;height:31px;box-sizing:border-box;vertical-align:middle}.si-grid tr:last-child td{border-bottom:0}'
          +'.si-param{display:flex;align-items:center;gap:6px}.si-code{flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}'
          +'.si-input{width:100%;height:25px;border:1px solid #b8c2cc;padding:2px 5px;box-sizing:border-box;font:inherit}.si-checkbox{width:16px;height:16px}'
          +'.si-readonly{min-height:24px;display:flex;align-items:center;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.si-lookup-wrap{display:flex;align-items:center;gap:2px}.si-controlled{flex:1;border-bottom:1px dotted #777}.si-empty{color:#6b737b;font-style:italic}'
          +'.si-col-param{width:27%}.si-col-type{width:14%}.si-col-value{width:25%}.si-col-display{width:28%}.si-col-del{width:6%}';
        root.appendChild(style);
        var wrap=el('div','si-wrap'), toolbar=el('div','si-toolbar');
        toolbar.appendChild(button('＋ Новий рядок','Додати параметр',function(){invoke('AddRowRequested',[]);},false)); wrap.appendChild(toolbar);
        var gridWrap=el('div','si-grid-wrap'), table=el('table','si-grid'), thead=el('thead'), hr=el('tr');
        [['Код параметра','si-col-param'],['Тип','si-col-type'],['Значення','si-col-value'],['Відображуване значення','si-col-display'],['','si-col-del']].forEach(function(h){hr.appendChild(el('th',h[1],h[0]));});
        thead.appendChild(hr); table.appendChild(thead); var tbody=el('tbody');
        rows.forEach(function(row){
            var tr=el('tr'), ptd=el('td'), pwrap=el('div','si-param'); pwrap.appendChild(el('div','si-code',row.parameterCode||'')); ptd.appendChild(pwrap); tr.appendChild(ptd);
            tr.appendChild(el('td','',row.valueTypeCaption||row.valueType||'')); var vtd=el('td'); vtd.appendChild(inputFor(row)); tr.appendChild(vtd); tr.appendChild(el('td','',row.displayValue||''));
            var dtd=el('td'); dtd.appendChild(button('×','Видалити рядок',function(){invoke('DeleteRowRequested',[row.parameterCode]);},true)); tr.appendChild(dtd); tbody.appendChild(tr);
        });
        if(showNewRow){
            var nr=el('tr'),np=el('td'),nw=el('div','si-param'); nw.appendChild(el('div','si-code si-empty','Виберіть параметр')); nw.appendChild(button('⋯','Вибрати параметр',function(){invoke('ParameterLookupRequested',[]);},true)); np.appendChild(nw); nr.appendChild(np);
            nr.appendChild(el('td','',''));nr.appendChild(el('td','',''));nr.appendChild(el('td','',''));nr.appendChild(el('td','',''));tbody.appendChild(nr);
        }
        if(!rows.length&&!showNewRow){var er=el('tr'),e=el('td','si-empty','Немає параметрів. Натисніть «Новий рядок», щоб додати параметр.');e.colSpan=5;er.appendChild(e);tbody.appendChild(er);}
        table.appendChild(tbody); gridWrap.appendChild(table); wrap.appendChild(gridWrap); root.appendChild(wrap);
    }
    window.RenderRows=function(rowsJson){var p={};try{p=JSON.parse(rowsJson||'{}');}catch(e){p={};}rows=Array.isArray(p.rows)?p.rows:[];showNewRow=!!p.showNewRow;render();};
    render();
})();
